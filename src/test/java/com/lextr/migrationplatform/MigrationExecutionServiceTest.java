package com.lextr.migrationplatform;

import com.lextr.migrationplatform.adapter.DatabaseAdapter;
import com.lextr.migrationplatform.adapter.FlywayAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.factory.DatabaseAdapterFactory;
import com.lextr.migrationplatform.factory.FlywayAdapterFactory;
import com.lextr.migrationplatform.factory.MigrationModeStrategyFactory;
import com.lextr.migrationplatform.mapper.ExecutionResponseMapper;
import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationPlan;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.RunMode;
import com.lextr.migrationplatform.model.TargetMigrationPlan;
import com.lextr.migrationplatform.service.AuditService;
import com.lextr.migrationplatform.service.MigrationPlanService;
import com.lextr.migrationplatform.service.MigrationValidationService;
import com.lextr.migrationplatform.service.impl.MigrationExecutionServiceImpl;
import com.lextr.migrationplatform.strategy.DeltaMigrationStrategy;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MigrationExecutionServiceTest {

    @Test
    void stopsOnFirstFailureByDefault() {
        DatabaseAdapterFactory databaseFactory = mock(DatabaseAdapterFactory.class);
        FlywayAdapterFactory flywayFactory = mock(FlywayAdapterFactory.class);
        MigrationValidationService validationService = mock(MigrationValidationService.class);
        MigrationPlanService planService = mock(MigrationPlanService.class);
        AuditService auditService = mock(AuditService.class);
        DatabaseAdapter databaseAdapter = mock(DatabaseAdapter.class);
        FlywayAdapter flywayAdapter = mock(FlywayAdapter.class);
        FlywayOperations flyway1 = mock(FlywayOperations.class);
        FlywayOperations flyway2 = mock(FlywayOperations.class);

        MigrationTarget first = target("generic-service");
        MigrationTarget second = target("workflow-service");
        when(validationService.validateTarget(first, false)).thenReturn(List.of());
        when(validationService.validateTarget(second, false)).thenReturn(List.of());
        when(databaseFactory.getRequired("postgres")).thenReturn(databaseAdapter);
        when(flywayFactory.getRequired("postgres")).thenReturn(flywayAdapter);
        when(flywayAdapter.create(first)).thenReturn(flyway1);
        when(flywayAdapter.create(second)).thenReturn(flyway2);
        when(planService.createPlan(List.of(first), false)).thenReturn(plan(first, "V001 :: init [PENDING]"));
        when(planService.createPlan(List.of(second), false)).thenReturn(plan(second, "V002 :: init [PENDING]"));
        doThrow(new IllegalStateException("boom")).when(flyway1).migrate();

        MigrationExecutionServiceImpl service = new MigrationExecutionServiceImpl(
                databaseFactory,
                flywayFactory,
                new MigrationModeStrategyFactory(List.of(new DeltaMigrationStrategy())),
                validationService,
                planService,
                auditService,
                new ExecutionResponseMapper()
        );

        ExecutionResponse response = service.execute(request(false), List.of(first, second));

        assertEquals("FAILED", response.status());
        assertEquals("SKIPPED", response.results().get(1).status());
        verify(flyway2, never()).migrate();
    }

    @Test
    void continuesOnErrorWhenRequested() {
        DatabaseAdapterFactory databaseFactory = mock(DatabaseAdapterFactory.class);
        FlywayAdapterFactory flywayFactory = mock(FlywayAdapterFactory.class);
        MigrationValidationService validationService = mock(MigrationValidationService.class);
        MigrationPlanService planService = mock(MigrationPlanService.class);
        AuditService auditService = mock(AuditService.class);
        DatabaseAdapter databaseAdapter = mock(DatabaseAdapter.class);
        FlywayAdapter flywayAdapter = mock(FlywayAdapter.class);
        FlywayOperations flyway1 = mock(FlywayOperations.class);
        FlywayOperations flyway2 = mock(FlywayOperations.class);

        MigrationTarget first = target("generic-service");
        MigrationTarget second = target("workflow-service");
        when(validationService.validateTarget(first, false)).thenReturn(List.of());
        when(validationService.validateTarget(second, false)).thenReturn(List.of());
        when(databaseFactory.getRequired("postgres")).thenReturn(databaseAdapter);
        when(flywayFactory.getRequired("postgres")).thenReturn(flywayAdapter);
        when(flywayAdapter.create(first)).thenReturn(flyway1);
        when(flywayAdapter.create(second)).thenReturn(flyway2);
        when(planService.createPlan(List.of(first), false)).thenReturn(plan(first, "V001 :: init [PENDING]"));
        when(planService.createPlan(List.of(second), false)).thenReturn(plan(second, "V002 :: init [PENDING]"));
        doThrow(new IllegalStateException("boom")).when(flyway1).migrate();

        MigrationExecutionServiceImpl service = new MigrationExecutionServiceImpl(
                databaseFactory,
                flywayFactory,
                new MigrationModeStrategyFactory(List.of(new DeltaMigrationStrategy())),
                validationService,
                planService,
                auditService,
                new ExecutionResponseMapper()
        );

        ExecutionResponse response = service.execute(request(true), List.of(first, second));

        assertEquals("FAILED", response.status());
        assertEquals("SUCCESS", response.results().get(1).status());
        verify(flyway2).migrate();
    }

    private MigrationRequest request(boolean continueOnError) {
        return new MigrationRequest(ExecutionScope.ALL_SERVICES, null, "postgres-main-dev", "postgres", "dev",
                false, RunMode.DELTA, continueOnError, false, false, "dba");
    }

    private MigrationPlan plan(MigrationTarget target, String pending) {
        return new MigrationPlan(List.of(new TargetMigrationPlan(
                target.service(), target.targetName(), target.databaseType(), target.environment(), target.locations(),
                target.historyTable(), List.of(), List.of(pending), List.of(), List.of(), List.of(), List.of(), 1
        )));
    }

    private MigrationTarget target(String service) {
        return new MigrationTarget("dev", service, "postgres-main-dev", "postgres", "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, "0", false, "flyway_history_" + service, Map.of());
    }
}
