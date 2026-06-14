package com.lextr.migrator;

import com.lextr.migrator.integrations.databases.base.DatabaseIntegration;
import com.lextr.migrator.integrations.databases.base.DatabaseIntegrationRegistry;
import com.lextr.migrator.integrations.flyway.FlywayFactory;
import com.lextr.migrator.integrations.flyway.FlywayOperations;
import com.lextr.migrator.platform.audit.AuditRepository;
import com.lextr.migrator.platform.config.PlatformProperties;
import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.orchestration.ExecutionScope;
import com.lextr.migrator.platform.orchestration.MigrationOrchestrator;
import com.lextr.migrator.platform.orchestration.MigrationRequest;
import com.lextr.migrator.platform.orchestration.RunMode;
import com.lextr.migrator.platform.orchestration.TargetSelectionService;
import com.lextr.migrator.platform.planning.MigrationPlan;
import com.lextr.migrator.platform.planning.PlanningService;
import com.lextr.migrator.platform.planning.TargetMigrationPlan;
import com.lextr.migrator.platform.validation.MigrationValidationService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MigrationOrchestratorTest {

    @Test
    void executesSingleServiceRun() {
        var fixture = fixture();
        MigrationTarget target = target("customer-service", "postgres");
        when(fixture.selection.resolve(request(ExecutionScope.SERVICE, false))).thenReturn(List.of(target));
        when(fixture.validation.validateTarget(target, false)).thenReturn(List.of());
        when(fixture.integrationRegistry.getRequired("postgres")).thenReturn(fixture.integration);
        when(fixture.factory.create(target)).thenReturn(fixture.flyway1);
        when(fixture.planning.createPlan(List.of(target), false)).thenReturn(plan(target, "V001 :: init [PENDING]"));

        var response = fixture.orchestrator.run(request(ExecutionScope.SERVICE, false));

        assertEquals("SUCCESS", response.status());
        assertEquals("SUCCESS", response.results().get(0).status());
        verify(fixture.flyway1).migrate();
    }

    @Test
    void stopsOnFirstFailureByDefault() {
        var fixture = fixture();
        MigrationTarget first = target("customer-service", "postgres");
        MigrationTarget second = target("workflow-service", "postgres");
        when(fixture.selection.resolve(request(ExecutionScope.ALL_SERVICES, false))).thenReturn(List.of(first, second));
        when(fixture.validation.validateTarget(first, false)).thenReturn(List.of());
        when(fixture.validation.validateTarget(second, false)).thenReturn(List.of());
        when(fixture.integrationRegistry.getRequired("postgres")).thenReturn(fixture.integration);
        when(fixture.factory.create(first)).thenReturn(fixture.flyway1);
        when(fixture.planning.createPlan(List.of(first), false)).thenReturn(plan(first, "V001 :: init [PENDING]"));
        doThrow(new IllegalStateException("boom")).when(fixture.flyway1).migrate();

        var response = fixture.orchestrator.run(request(ExecutionScope.ALL_SERVICES, false));

        assertEquals("FAILED", response.status());
        assertEquals("FAILED", response.results().get(0).status());
        assertEquals("SKIPPED", response.results().get(1).status());
        verify(fixture.factory, never()).create(second);
    }

    @Test
    void continuesOnErrorWhenRequested() {
        var fixture = fixture();
        MigrationTarget first = target("customer-service", "postgres");
        MigrationTarget second = target("workflow-service", "postgres");
        when(fixture.selection.resolve(request(ExecutionScope.ALL_SERVICES, true))).thenReturn(List.of(first, second));
        when(fixture.validation.validateTarget(first, false)).thenReturn(List.of());
        when(fixture.validation.validateTarget(second, false)).thenReturn(List.of());
        when(fixture.integrationRegistry.getRequired("postgres")).thenReturn(fixture.integration);
        when(fixture.factory.create(first)).thenReturn(fixture.flyway1);
        when(fixture.factory.create(second)).thenReturn(fixture.flyway2);
        when(fixture.planning.createPlan(List.of(first), false)).thenReturn(plan(first, "V001 :: init [PENDING]"));
        when(fixture.planning.createPlan(List.of(second), false)).thenReturn(plan(second, "V002 :: init [PENDING]"));
        doThrow(new IllegalStateException("boom")).when(fixture.flyway1).migrate();

        var response = fixture.orchestrator.run(request(ExecutionScope.ALL_SERVICES, true));

        assertEquals("FAILED", response.status());
        assertEquals("FAILED", response.results().get(0).status());
        assertEquals("SUCCESS", response.results().get(1).status());
        verify(fixture.flyway2).migrate();
    }

    private Fixture fixture() {
        Fixture fixture = new Fixture();
        fixture.selection = mock(TargetSelectionService.class);
        fixture.planning = mock(PlanningService.class);
        fixture.factory = mock(FlywayFactory.class);
        fixture.integrationRegistry = mock(DatabaseIntegrationRegistry.class);
        fixture.validation = mock(MigrationValidationService.class);
        fixture.audit = mock(AuditRepository.class);
        fixture.inventory = mock(InventoryService.class);
        fixture.integration = mock(DatabaseIntegration.class);
        fixture.flyway1 = mock(FlywayOperations.class);
        fixture.flyway2 = mock(FlywayOperations.class);
        PlatformProperties properties = new PlatformProperties();
        fixture.orchestrator = new MigrationOrchestrator(
                fixture.selection, fixture.planning, fixture.factory, fixture.integrationRegistry,
                fixture.validation, fixture.audit, fixture.inventory, properties
        );
        return fixture;
    }

    private MigrationRequest request(ExecutionScope scope, boolean continueOnError) {
        return new MigrationRequest(scope, "customer-service", "postgres", "dev", false,
                RunMode.DELTA, continueOnError, false, false, "dba");
    }

    private MigrationPlan plan(MigrationTarget target, String pending) {
        return new MigrationPlan(List.of(new TargetMigrationPlan(
                target.service(), target.database(), target.environment(), target.locations(),
                List.of(), List.of(pending), List.of(), List.of(), List.of(), List.of(), 1
        )));
    }

    private MigrationTarget target(String service, String database) {
        return new MigrationTarget("dev", service, database, "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, false, null, Map.of(), false);
    }

    private static class Fixture {
        private TargetSelectionService selection;
        private PlanningService planning;
        private FlywayFactory factory;
        private DatabaseIntegrationRegistry integrationRegistry;
        private MigrationValidationService validation;
        private AuditRepository audit;
        private InventoryService inventory;
        private DatabaseIntegration integration;
        private FlywayOperations flyway1;
        private FlywayOperations flyway2;
        private MigrationOrchestrator orchestrator;
    }
}
