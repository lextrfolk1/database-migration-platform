package com.lextr.migrationplatform.orchestration;

import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.dto.MigrationHistoryResponse;
import com.lextr.migrationplatform.factory.DatabaseAdapterFactory;
import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ServiceMigrationDefinition;
import com.lextr.migrationplatform.model.TargetDatabase;
import com.lextr.migrationplatform.service.MigrationExecutionService;
import com.lextr.migrationplatform.service.MigrationHistoryService;
import com.lextr.migrationplatform.service.MigrationInventoryService;
import com.lextr.migrationplatform.service.MigrationPlanService;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class MigrationPlatformOrchestrator {

    private final MigrationInventoryService inventoryService;
    private final MigrationPlanService planService;
    private final MigrationExecutionService executionService;
    private final MigrationHistoryService historyService;
    private final DatabaseAdapterFactory databaseAdapterFactory;

    public MigrationPlatformOrchestrator(MigrationInventoryService inventoryService,
                                         MigrationPlanService planService,
                                         MigrationExecutionService executionService,
                                         MigrationHistoryService historyService,
                                         DatabaseAdapterFactory databaseAdapterFactory) {
        this.inventoryService = inventoryService;
        this.planService = planService;
        this.executionService = executionService;
        this.historyService = historyService;
        this.databaseAdapterFactory = databaseAdapterFactory;
    }

    public List<MigrationTarget> inventory() {
        return inventoryService.resolvedTargets();
    }

    public List<TargetDatabase> targets() {
        return inventoryService.targetDatabases();
    }

    public TargetDatabase target(String targetName) {
        return inventoryService.getRequiredTargetDatabase(targetName);
    }

    public List<String> services() {
        return inventoryService.listServices();
    }

    public ServiceMigrationDefinition service(String serviceName) {
        return inventoryService.getRequiredServiceDefinition(serviceName);
    }

    public List<String> serviceTargets(String serviceName) {
        return inventoryService.listTargetNamesForService(serviceName);
    }

    public MigrationPlan plan(MigrationRequest request) {
        return planService.createPlan(resolveTargets(request), request.allowRisky());
    }

    public MigrationPlan validate(MigrationRequest request) {
        List<MigrationTarget> targets = resolveTargets(request);
        for (MigrationTarget target : targets) {
            databaseAdapterFactory.getRequired(target.databaseType()).validateConnection(target);
        }
        return planService.createPlan(targets, request.allowRisky());
    }

    public ExecutionResponse run(MigrationRequest request) {
        return executionService.execute(request, resolveTargets(request));
    }

    public ExecutionResponse repair(MigrationRequest request) {
        return executionService.repair(request, resolveTargets(request));
    }

    public List<MigrationHistoryResponse> history() {
        return historyService.history();
    }

    public MigrationHistoryResponse status(String executionId) {
        return historyService.status(executionId);
    }

    private List<MigrationTarget> resolveTargets(MigrationRequest request) {
        return inventoryService.resolveRequest(request);
    }
}
