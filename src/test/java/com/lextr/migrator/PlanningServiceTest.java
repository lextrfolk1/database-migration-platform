package com.lextr.migrator;

import com.lextr.migrator.integrations.flyway.FlywayFactory;
import com.lextr.migrator.integrations.flyway.FlywayOperations;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.planning.PlanningService;
import com.lextr.migrator.platform.validation.IssueSeverity;
import com.lextr.migrator.platform.validation.MigrationValidationService;
import com.lextr.migrator.platform.validation.ValidationIssue;
import org.flywaydb.core.api.MigrationInfo;
import org.flywaydb.core.api.MigrationState;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class PlanningServiceTest {

    @Test
    void classifiesAppliedPendingAndRepeatableMigrations() {
        FlywayFactory flywayFactory = mock(FlywayFactory.class);
        FlywayOperations operations = mock(FlywayOperations.class);
        MigrationValidationService validationService = mock(MigrationValidationService.class);

        MigrationInfo applied = mock(MigrationInfo.class);
        when(applied.getVersion()).thenReturn(MigrationVersion.fromVersion("1"));
        when(applied.getDescription()).thenReturn("init");
        when(applied.getState()).thenReturn(MigrationState.SUCCESS);
        when(applied.getInstalledOn()).thenReturn(Timestamp.from(Instant.now()));

        MigrationInfo pending = mock(MigrationInfo.class);
        when(pending.getVersion()).thenReturn(MigrationVersion.fromVersion("2"));
        when(pending.getDescription()).thenReturn("add_index");
        when(pending.getState()).thenReturn(MigrationState.PENDING);
        when(pending.getInstalledOn()).thenReturn(null);

        MigrationInfo repeatable = mock(MigrationInfo.class);
        when(repeatable.getVersion()).thenReturn(null);
        when(repeatable.getDescription()).thenReturn("refresh_view");
        when(repeatable.getState()).thenReturn(MigrationState.OUTDATED);
        when(repeatable.getInstalledOn()).thenReturn(Timestamp.from(Instant.now()));

        MigrationTarget target = target();
        when(flywayFactory.create(target)).thenReturn(operations);
        when(operations.infoAll()).thenReturn(new MigrationInfo[]{applied, pending, repeatable});
        when(validationService.validateTarget(target, false)).thenReturn(List.of(
                new ValidationIssue(IssueSeverity.WARNING, "POSTGRES_LOCKING_RISK", "review index")
        ));

        PlanningService service = new PlanningService(flywayFactory, validationService);
        var plan = service.createPlan(List.of(target), false);

        assertEquals(1, plan.targets().size());
        assertEquals(2, plan.targets().get(0).alreadyApplied().size());
        assertEquals(1, plan.targets().get(0).pendingVersionedMigrations().size());
        assertEquals(1, plan.targets().get(0).repeatableMigrationsToRerun().size());
        assertEquals(1, plan.targets().get(0).riskWarnings().size());
    }

    private MigrationTarget target() {
        return new MigrationTarget("dev", "customer-service", "postgres", "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, false, null, Map.of(), false);
    }
}
