package com.lextr.migrationplatform;

import com.lextr.migrationplatform.dao.ServiceInventoryDao;
import com.lextr.migrationplatform.factory.ExecutionScopeStrategyFactory;
import com.lextr.migrationplatform.model.InventorySnapshot;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.ServiceMigrationDefinition;
import com.lextr.migrationplatform.model.ServiceTargetMapping;
import com.lextr.migrationplatform.model.TargetDatabase;
import com.lextr.migrationplatform.service.impl.MigrationInventoryServiceImpl;
import com.lextr.migrationplatform.util.FlywayHistoryTableResolver;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MigrationInventoryServiceTest {

    @Test
    void serviceMappingCanOverrideTargetBaselineOnMigrate() {
        TargetDatabase target = new TargetDatabase("postgres-main-dev", "postgres", "dev", "jdbc:test", "user", () -> "pw",
                "driver", List.of("meta"), true, "0", false, "flyway_history", Map.of());
        ServiceInventoryDao dao = mock(ServiceInventoryDao.class);
        when(dao.loadInventory()).thenReturn(new InventorySnapshot("dev", Map.of("postgres-main-dev", target), Map.of(
                "database-scripts", new ServiceMigrationDefinition("database-scripts", List.of(
                        new ServiceTargetMapping("postgres-main-dev", List.of("classpath:a"), List.of(), null, Map.of(), false))),
                "semantic-service", new ServiceMigrationDefinition("semantic-service", List.of(
                        new ServiceTargetMapping("postgres-main-dev", List.of("classpath:b"), List.of(), null, Map.of(), null)))
        )));
        MigrationInventoryServiceImpl service = new MigrationInventoryServiceImpl(dao, new FlywayHistoryTableResolver(),
                new ExecutionScopeStrategyFactory(List.of()));

        Map<String, Boolean> baselineByService = service.resolvedTargets().stream()
                .collect(java.util.stream.Collectors.toMap(MigrationTarget::service, MigrationTarget::baselineOnMigrate));

        assertFalse(baselineByService.get("database-scripts"));
        assertTrue(baselineByService.get("semantic-service"));
    }
}
