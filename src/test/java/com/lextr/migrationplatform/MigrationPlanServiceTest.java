package com.lextr.migrationplatform;

import com.lextr.migrationplatform.adapter.FlywayAdapter;
import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.factory.FlywayAdapterFactory;
import com.lextr.migrationplatform.model.IssueSeverity;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ValidationIssue;
import com.lextr.migrationplatform.service.MigrationValidationService;
import com.lextr.migrationplatform.service.impl.MigrationPlanServiceImpl;
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

class MigrationPlanServiceTest {

    @Test
    void classifiesAppliedPendingAndRepeatableMigrations() {
        FlywayAdapterFactory factory = mock(FlywayAdapterFactory.class);
        FlywayAdapter adapter = mock(FlywayAdapter.class);
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
        when(factory.getRequired("postgres")).thenReturn(adapter);
        when(adapter.create(target)).thenReturn(operations);
        when(operations.infoAll()).thenReturn(new MigrationInfo[]{applied, pending, repeatable});
        when(validationService.validateTarget(target, false)).thenReturn(List.of(
                new ValidationIssue(IssueSeverity.WARNING, "POSTGRES_LOCKING_RISK", "review index")
        ));

        MigrationPlanServiceImpl service = new MigrationPlanServiceImpl(factory, validationService);
        var plan = service.createPlan(List.of(target), false);

        assertEquals(2, plan.targets().get(0).alreadyApplied().size());
        assertEquals(1, plan.targets().get(0).pendingVersionedMigrations().size());
        assertEquals(1, plan.targets().get(0).repeatableMigrationsToRerun().size());
        assertEquals(1, plan.targets().get(0).riskWarnings().size());
    }

    private MigrationTarget target() {
        return new MigrationTarget("dev", "generic-service", "postgres-main-dev", "postgres", "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, "0", false, "flyway_history_generic_service", Map.of());
    }
}
