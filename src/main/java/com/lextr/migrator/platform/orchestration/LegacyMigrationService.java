package com.lextr.migrator.platform.orchestration;

import com.lextr.migrator.integrations.flyway.FlywayFactory;
import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.flywaydb.core.api.FlywayException;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class LegacyMigrationService {

    private final InventoryService inventoryService;
    private final FlywayFactory flywayFactory;

    public LegacyMigrationService(InventoryService inventoryService, FlywayFactory flywayFactory) {
        this.inventoryService = inventoryService;
        this.flywayFactory = flywayFactory;
    }

    public String migrate(boolean cleanDb, boolean force) {
        try {
            for (MigrationTarget target : inventoryService.listTargets().stream().filter(MigrationTarget::legacyCompatible).toList()) {
                var flyway = flywayFactory.create(target);
                if (cleanDb) {
                    if (flyway.isCleanDisabled()) {
                        return "Database cleaning is disabled.";
                    }
                    flyway.clean();
                }
                if (force) {
                    flyway.repair();
                }
                flyway.migrate();
            }
            return "Database cleaned and migration executed successfully.";
        } catch (FlywayException exception) {
            return "Error during migration: " + exception.getMessage();
        }
    }

    public String clean() {
        try {
            for (MigrationTarget target : inventoryService.listTargets().stream().filter(MigrationTarget::legacyCompatible).toList()) {
                var flyway = flywayFactory.create(target);
                if (flyway.isCleanDisabled()) {
                    return "Database cleaning is disabled.";
                }
                flyway.clean();
            }
            return "Database cleaned successfully.";
        } catch (FlywayException exception) {
            return "Error during cleaning: " + exception.getMessage();
        }
    }

    public List<String> info() {
        return inventoryService.listTargets().stream()
                .filter(MigrationTarget::legacyCompatible)
                .flatMap(target -> Arrays.stream(flywayFactory.create(target).infoAll())
                        .map(migration -> String.format("Service: %s, Version: %s, Description: %s, State: %s",
                                target.service(), migration.getVersion(), migration.getDescription(), migration.getState())))
                .toList();
    }
}
