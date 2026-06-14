package com.lextr.migrator.platform.orchestration;

import com.lextr.migrator.integrations.databases.base.DatabaseIntegration;
import com.lextr.migrator.integrations.databases.base.DatabaseIntegrationRegistry;
import com.lextr.migrator.integrations.flyway.FlywayFactory;
import com.lextr.migrator.integrations.flyway.FlywayOperations;
import com.lextr.migrator.platform.audit.AuditRecord;
import com.lextr.migrator.platform.audit.AuditRepository;
import com.lextr.migrator.platform.config.PlatformProperties;
import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.planning.MigrationPlan;
import com.lextr.migrator.platform.planning.PlanningService;
import com.lextr.migrator.platform.validation.MigrationValidationService;
import com.lextr.migrator.platform.validation.ValidationIssue;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class MigrationOrchestrator {

    private final TargetSelectionService targetSelectionService;
    private final PlanningService planningService;
    private final FlywayFactory flywayFactory;
    private final DatabaseIntegrationRegistry integrationRegistry;
    private final MigrationValidationService validationService;
    private final AuditRepository auditRepository;
    private final InventoryService inventoryService;
    private final PlatformProperties properties;

    public MigrationOrchestrator(TargetSelectionService targetSelectionService, PlanningService planningService,
                                 FlywayFactory flywayFactory, DatabaseIntegrationRegistry integrationRegistry,
                                 MigrationValidationService validationService, AuditRepository auditRepository,
                                 InventoryService inventoryService, PlatformProperties properties) {
        this.targetSelectionService = targetSelectionService;
        this.planningService = planningService;
        this.flywayFactory = flywayFactory;
        this.integrationRegistry = integrationRegistry;
        this.validationService = validationService;
        this.auditRepository = auditRepository;
        this.inventoryService = inventoryService;
        this.properties = properties;
    }

    public List<MigrationTarget> inventory() {
        return inventoryService.listTargets();
    }

    public MigrationPlan plan(MigrationRequest request) {
        return planningService.createPlan(targetSelectionService.resolve(request), request.allowRisky());
    }

    public MigrationPlan validate(MigrationRequest request) {
        List<MigrationTarget> targets = targetSelectionService.resolve(request);
        for (MigrationTarget target : targets) {
            integrationRegistry.getRequired(target.database()).validateConnection(target);
        }
        return planningService.createPlan(targets, request.allowRisky());
    }

    public ExecutionResponse run(MigrationRequest request) {
        List<MigrationTarget> targets = targetSelectionService.resolve(request);
        String executionId = UUID.randomUUID().toString();
        Instant startedAt = Instant.now();
        List<ExecutionTargetResult> results = new ArrayList<>();
        String overallStatus = "SUCCESS";
        String failedMigration = null;
        String errorMessage = null;
        List<String> executedMigrationsForAudit = new ArrayList<>();

        for (int index = 0; index < targets.size(); index++) {
            MigrationTarget target = targets.get(index);
            List<ValidationIssue> issues = validationService.validateTarget(target, request.allowRisky());
            if (validationService.hasErrors(issues)) {
                overallStatus = "FAILED";
                String targetMessage = "Validation failed for " + target.service() + "/" + target.database();
                results.add(new ExecutionTargetResult(target.service(), target.database(), target.environment(),
                        "FAILED", List.of(), null, targetMessage, issues));
                errorMessage = targetMessage;
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
                continue;
            }

            DatabaseIntegration integration = integrationRegistry.getRequired(target.database());
            integration.validateConnection(target);
            FlywayOperations flyway = flywayFactory.create(target);
            MigrationPlan targetPlan = planningService.createPlan(List.of(target), request.allowRisky());
            List<String> willExecute = targetPlan.targets().get(0).pendingVersionedMigrations();
            List<String> repeatables = targetPlan.targets().get(0).repeatableMigrationsToRerun();
            List<String> expectedMigrations = new ArrayList<>(willExecute);
            expectedMigrations.addAll(repeatables);

            try {
                if (request.mode() == RunMode.REBUILD) {
                    validateRebuildAllowed(request, target, integration);
                    flyway.clean();
                }
                flyway.migrate();
                executedMigrationsForAudit.addAll(expectedMigrations);
                results.add(new ExecutionTargetResult(target.service(), target.database(), target.environment(),
                        "SUCCESS", expectedMigrations, null, null, issues));
            } catch (Exception exception) {
                overallStatus = "FAILED";
                failedMigration = expectedMigrations.isEmpty() ? null : expectedMigrations.get(0);
                errorMessage = exception.getMessage();
                results.add(new ExecutionTargetResult(target.service(), target.database(), target.environment(),
                        "FAILED", expectedMigrations, failedMigration, exception.getMessage(), issues));
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
            }
        }

        Instant completedAt = Instant.now();
        auditRepository.save(new AuditRecord(
                executionId,
                request.scope().name(),
                request.service(),
                request.allDatabases() ? "all" : request.database(),
                request.environment(),
                request.mode().name(),
                request.requestedBy() == null || request.requestedBy().isBlank() ? properties.getDefaultRequestedBy() : request.requestedBy(),
                startedAt,
                completedAt,
                overallStatus,
                executedMigrationsForAudit,
                failedMigration,
                errorMessage,
                Duration.between(startedAt, completedAt).toMillis(),
                request.allowRisky()
        ));
        return new ExecutionResponse(executionId, request.scope().name(), overallStatus, results);
    }

    public ExecutionResponse repair(MigrationRequest request) {
        List<MigrationTarget> targets = targetSelectionService.resolve(request);
        String executionId = UUID.randomUUID().toString();
        Instant startedAt = Instant.now();
        List<ExecutionTargetResult> results = new ArrayList<>();
        String overallStatus = "SUCCESS";
        String errorMessage = null;

        for (int index = 0; index < targets.size(); index++) {
            MigrationTarget target = targets.get(index);
            try {
                integrationRegistry.getRequired(target.database()).validateConnection(target);
                flywayFactory.create(target).repair();
                results.add(new ExecutionTargetResult(target.service(), target.database(), target.environment(),
                        "SUCCESS", List.of(), null, null, List.of()));
            } catch (Exception exception) {
                overallStatus = "FAILED";
                errorMessage = exception.getMessage();
                results.add(new ExecutionTargetResult(target.service(), target.database(), target.environment(),
                        "FAILED", List.of(), null, exception.getMessage(), List.of()));
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
            }
        }

        Instant completedAt = Instant.now();
        auditRepository.save(new AuditRecord(
                executionId,
                request.scope().name(),
                request.service(),
                request.allDatabases() ? "all" : request.database(),
                request.environment(),
                "REPAIR",
                request.requestedBy() == null || request.requestedBy().isBlank() ? properties.getDefaultRequestedBy() : request.requestedBy(),
                startedAt,
                completedAt,
                overallStatus,
                List.of(),
                null,
                errorMessage,
                Duration.between(startedAt, completedAt).toMillis(),
                request.allowRisky()
        ));
        return new ExecutionResponse(executionId, request.scope().name(), overallStatus, results);
    }

    public List<AuditRecord> history() {
        return auditRepository.findAll();
    }

    public AuditRecord status(String executionId) {
        return auditRepository.findByExecutionId(executionId)
                .orElseThrow(() -> new IllegalArgumentException("Unknown execution id: " + executionId));
    }

    private void validateRebuildAllowed(MigrationRequest request, MigrationTarget target, DatabaseIntegration integration) {
        String environmentName = target.environment().toLowerCase(Locale.ROOT);
        if (!request.confirm()) {
            throw new IllegalStateException("Rebuild requires explicit confirmation");
        }
        if (!integration.supportsClean()) {
            throw new IllegalStateException("Rebuild is not supported for database " + target.database());
        }
        if (target.cleanDisabled()) {
            throw new IllegalStateException("Flyway clean is disabled for " + target.service() + "/" + target.database());
        }
        if ((environmentName.equals("prod") || environmentName.equals("production")) && !properties.isAllowProductionRebuild()) {
            throw new IllegalStateException("Production rebuild is blocked by configuration");
        }
    }

    private void addSkippedResults(List<MigrationTarget> targets, List<ExecutionTargetResult> results, int startIndex) {
        for (int index = startIndex; index < targets.size(); index++) {
            MigrationTarget skipped = targets.get(index);
            results.add(new ExecutionTargetResult(skipped.service(), skipped.database(), skipped.environment(),
                    "SKIPPED", List.of(), null, "Skipped after earlier failure", List.of()));
        }
    }
}
