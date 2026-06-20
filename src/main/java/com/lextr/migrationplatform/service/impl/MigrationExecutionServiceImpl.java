package com.lextr.migrationplatform.service.impl;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.dto.ExecutionTargetResponse;
import com.lextr.migrationplatform.entity.MigrationAuditEntity;
import com.lextr.migrationplatform.factory.DatabaseAdapterFactory;
import com.lextr.migrationplatform.factory.FlywayAdapterFactory;
import com.lextr.migrationplatform.factory.MigrationModeStrategyFactory;
import com.lextr.migrationplatform.mapper.ExecutionResponseMapper;
import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.service.AuditService;
import com.lextr.migrationplatform.service.MigrationExecutionService;
import com.lextr.migrationplatform.service.MigrationPlanService;
import com.lextr.migrationplatform.service.MigrationValidationService;
import com.lextr.migrationplatform.strategy.MigrationModeStrategy;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class MigrationExecutionServiceImpl implements MigrationExecutionService {

    private final DatabaseAdapterFactory databaseAdapterFactory;
    private final FlywayAdapterFactory flywayAdapterFactory;
    private final MigrationModeStrategyFactory modeStrategyFactory;
    private final MigrationValidationService validationService;
    private final MigrationPlanService migrationPlanService;
    private final AuditService auditService;
    private final ExecutionResponseMapper executionResponseMapper;

    public MigrationExecutionServiceImpl(DatabaseAdapterFactory databaseAdapterFactory,
                                         FlywayAdapterFactory flywayAdapterFactory,
                                         MigrationModeStrategyFactory modeStrategyFactory,
                                         MigrationValidationService validationService,
                                         MigrationPlanService migrationPlanService,
                                         AuditService auditService,
                                         ExecutionResponseMapper executionResponseMapper) {
        this.databaseAdapterFactory = databaseAdapterFactory;
        this.flywayAdapterFactory = flywayAdapterFactory;
        this.modeStrategyFactory = modeStrategyFactory;
        this.validationService = validationService;
        this.migrationPlanService = migrationPlanService;
        this.auditService = auditService;
        this.executionResponseMapper = executionResponseMapper;
    }

    @Override
    public ExecutionResponse execute(MigrationRequest request, List<MigrationTarget> targets) {
        String executionId = UUID.randomUUID().toString();
        Instant startedAt = Instant.now();
        List<ExecutionTargetResponse> results = new ArrayList<>();
        String overallStatus = "SUCCESS";
        String failedMigration = null;
        String errorMessage = null;
        List<String> executedMigrationsForAudit = new ArrayList<>();

        for (int index = 0; index < targets.size(); index++) {
            MigrationTarget target = targets.get(index);
            List<ValidationIssue> issues = validationService.validateTarget(target, request.allowRisky());
            if (validationService.hasErrors(issues)) {
                overallStatus = "FAILED";
                String targetMessage = "Validation failed for " + target.service() + "/" + target.targetName();
                results.add(new ExecutionTargetResponse(target.service(), target.targetName(), target.databaseType(), target.environment(),
                        target.historyTable(),
                        "FAILED", List.of(), null, targetMessage, issues));
                errorMessage = targetMessage;
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
                continue;
            }

            DatabaseAdapter databaseAdapter = databaseAdapterFactory.getRequired(target.databaseType());
            databaseAdapter.validateConnection(target);
            FlywayOperations flywayOperations = flywayAdapterFactory.getRequired(target.databaseType()).create(target);
            MigrationModeStrategy modeStrategy = modeStrategyFactory.getRequired(request);
            MigrationPlan targetPlan = migrationPlanService.createPlan(List.of(target), request.allowRisky());
            List<String> expectedMigrations = new ArrayList<>(targetPlan.targets().get(0).pendingVersionedMigrations());
            expectedMigrations.addAll(targetPlan.targets().get(0).repeatableMigrationsToRerun());

            try {
                modeStrategy.beforeMigrate(request, target, databaseAdapter, flywayOperations);
                flywayOperations.migrate();
                executedMigrationsForAudit.addAll(expectedMigrations);
                results.add(new ExecutionTargetResponse(target.service(), target.targetName(), target.databaseType(), target.environment(),
                        target.historyTable(),
                        "SUCCESS", expectedMigrations, null, null, issues));
            } catch (Exception exception) {
                overallStatus = "FAILED";
                failedMigration = expectedMigrations.isEmpty() ? null : expectedMigrations.get(0);
                errorMessage = exception.getMessage();
                results.add(new ExecutionTargetResponse(target.service(), target.targetName(), target.databaseType(), target.environment(),
                        target.historyTable(),
                        "FAILED", expectedMigrations, failedMigration, exception.getMessage(), issues));
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
            }
        }

        persistAudit(executionId, request, startedAt, overallStatus, executedMigrationsForAudit, failedMigration, errorMessage);
        return executionResponseMapper.toResponse(executionId, request.scope().name(), overallStatus, results);
    }

    @Override
    public ExecutionResponse repair(MigrationRequest request, List<MigrationTarget> targets) {
        String executionId = UUID.randomUUID().toString();
        Instant startedAt = Instant.now();
        List<ExecutionTargetResponse> results = new ArrayList<>();
        String overallStatus = "SUCCESS";
        String errorMessage = null;

        for (int index = 0; index < targets.size(); index++) {
            MigrationTarget target = targets.get(index);
            try {
                databaseAdapterFactory.getRequired(target.databaseType()).validateConnection(target);
                flywayAdapterFactory.getRequired(target.databaseType()).create(target).repair();
                results.add(new ExecutionTargetResponse(target.service(), target.targetName(), target.databaseType(), target.environment(),
                        target.historyTable(),
                        "SUCCESS", List.of(), null, null, List.of()));
            } catch (Exception exception) {
                overallStatus = "FAILED";
                errorMessage = exception.getMessage();
                results.add(new ExecutionTargetResponse(target.service(), target.targetName(), target.databaseType(), target.environment(),
                        target.historyTable(),
                        "FAILED", List.of(), null, exception.getMessage(), List.of()));
                if (!request.continueOnError()) {
                    addSkippedResults(targets, results, index + 1);
                    break;
                }
            }
        }

        persistAudit(executionId, request, startedAt, overallStatus, List.of(), null, errorMessage);
        return executionResponseMapper.toResponse(executionId, request.scope().name(), overallStatus, results);
    }

    private void persistAudit(String executionId, MigrationRequest request, Instant startedAt, String overallStatus,
                              List<String> executedMigrationsForAudit, String failedMigration, String errorMessage) {
        Instant completedAt = Instant.now();
        auditService.save(new MigrationAuditEntity(
                executionId,
                request.scope().name(),
                request.service(),
                request.allTargets() ? "all" : request.target(),
                request.databaseType(),
                request.environment(),
                request.mode().name(),
                request.requestedBy(),
                startedAt,
                completedAt,
                overallStatus,
                executedMigrationsForAudit,
                failedMigration,
                errorMessage,
                Duration.between(startedAt, completedAt).toMillis(),
                request.allowRisky()
        ));
    }

    private void addSkippedResults(List<MigrationTarget> targets, List<ExecutionTargetResponse> results, int startIndex) {
        for (int index = startIndex; index < targets.size(); index++) {
            MigrationTarget skipped = targets.get(index);
            results.add(new ExecutionTargetResponse(skipped.service(), skipped.targetName(), skipped.databaseType(), skipped.environment(),
                    skipped.historyTable(),
                    "SKIPPED", List.of(), null, "Skipped after earlier failure", List.of()));
        }
    }
}
