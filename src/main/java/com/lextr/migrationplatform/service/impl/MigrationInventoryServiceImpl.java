package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.dao.ServiceInventoryDao;
import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.exception.UnsupportedDatabaseException;
import com.lextr.migrationplatform.factory.ExecutionScopeStrategyFactory;
import com.lextr.migrationplatform.model.InventorySnapshot;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ServiceMigrationDefinition;
import com.lextr.migrationplatform.model.ServiceTargetMapping;
import com.lextr.migrationplatform.model.TargetDatabase;
import com.lextr.migrationplatform.service.MigrationInventoryService;
import com.lextr.migrationplatform.util.FlywayHistoryTableResolver;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MigrationInventoryServiceImpl implements MigrationInventoryService {

    private final ServiceInventoryDao serviceInventoryDao;
    private final FlywayHistoryTableResolver historyTableResolver;
    private final ExecutionScopeStrategyFactory executionScopeStrategyFactory;

    public MigrationInventoryServiceImpl(ServiceInventoryDao serviceInventoryDao,
                                         FlywayHistoryTableResolver historyTableResolver,
                                         ExecutionScopeStrategyFactory executionScopeStrategyFactory) {
        this.serviceInventoryDao = serviceInventoryDao;
        this.historyTableResolver = historyTableResolver;
        this.executionScopeStrategyFactory = executionScopeStrategyFactory;
    }

    @Override
    public InventorySnapshot inventorySnapshot() {
        return serviceInventoryDao.loadInventory();
    }

    @Override
    public List<MigrationTarget> resolvedTargets() {
        InventorySnapshot snapshot = inventorySnapshot();
        List<MigrationTarget> resolvedTargets = new ArrayList<>();
        snapshot.services().forEach((serviceName, definition) -> {
            for (ServiceTargetMapping mapping : definition.targetMappings()) {
                TargetDatabase targetDatabase = snapshot.targets().get(mapping.targetName());
                if (targetDatabase == null) {
                    throw new UnsupportedDatabaseException("Service " + serviceName + " references unknown target " + mapping.targetName());
                }
                resolvedTargets.add(resolve(serviceName, targetDatabase, mapping));
            }
        });
        return resolvedTargets.stream()
                .sorted(Comparator.comparing(MigrationTarget::environment)
                        .thenComparing(MigrationTarget::service)
                        .thenComparing(MigrationTarget::targetName))
                .toList();
    }

    @Override
    public List<TargetDatabase> targetDatabases() {
        return inventorySnapshot().targets().values().stream()
                .sorted(Comparator.comparing(TargetDatabase::environment).thenComparing(TargetDatabase::name))
                .toList();
    }

    @Override
    public TargetDatabase getRequiredTargetDatabase(String targetName) {
        TargetDatabase targetDatabase = inventorySnapshot().targets().get(targetName);
        if (targetDatabase == null) {
            throw new ServiceNotFoundException("Unknown target database: " + targetName);
        }
        return targetDatabase;
    }

    @Override
    public List<String> listServices() {
        return inventorySnapshot().services().keySet().stream().sorted().toList();
    }

    @Override
    public ServiceMigrationDefinition getRequiredServiceDefinition(String serviceName) {
        ServiceMigrationDefinition definition = inventorySnapshot().services().get(serviceName);
        if (definition == null) {
            throw new ServiceNotFoundException("Unknown service: " + serviceName);
        }
        return definition;
    }

    @Override
    public List<String> listTargetNamesForService(String serviceName) {
        return getRequiredServiceDefinition(serviceName).targetMappings().stream()
                .map(ServiceTargetMapping::targetName)
                .distinct()
                .sorted()
                .toList();
    }

    @Override
    public List<MigrationTarget> resolveRequest(MigrationRequest request) {
        return executionScopeStrategyFactory.getRequired(request).selectTargets(request, resolvedTargets());
    }

    private MigrationTarget resolve(String serviceName, TargetDatabase targetDatabase, ServiceTargetMapping mapping) {
        Map<String, String> mergedPlaceholders = new LinkedHashMap<>(targetDatabase.placeholders());
        mergedPlaceholders.putAll(mapping.placeholders());
        List<String> schemas = !mapping.schemas().isEmpty() ? mapping.schemas() : targetDatabase.defaultSchemas();
        return new MigrationTarget(
                targetDatabase.environment(),
                serviceName,
                targetDatabase.name(),
                targetDatabase.databaseType(),
                targetDatabase.url(),
                targetDatabase.username(),
                targetDatabase.passwordSupplier(),
                targetDatabase.driverClassName(),
                mapping.locations(),
                schemas,
                targetDatabase.baselineOnMigrate(),
                targetDatabase.baselineVersion(),
                targetDatabase.cleanDisabled(),
                historyTableResolver.resolve(serviceName, targetDatabase, mapping),
                mergedPlaceholders
        );
    }
}
