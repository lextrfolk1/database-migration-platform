package com.lextr.migrator;

import com.lextr.migrator.platform.inventory.InventoryService;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import com.lextr.migrator.platform.orchestration.ExecutionScope;
import com.lextr.migrator.platform.orchestration.MigrationRequest;
import com.lextr.migrator.platform.orchestration.RunMode;
import com.lextr.migrator.platform.orchestration.TargetSelectionService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class TargetSelectionServiceTest {

    @Test
    void resolvesSingleServiceTarget() {
        InventoryService inventory = mock(InventoryService.class);
        MigrationTarget target = target("dev", "customer-service", "postgres");
        when(inventory.getRequiredTarget("dev", "customer-service", "postgres")).thenReturn(target);

        TargetSelectionService service = new TargetSelectionService(inventory);
        var resolved = service.resolve(new MigrationRequest(
                ExecutionScope.SERVICE, "customer-service", "postgres", "dev",
                false, RunMode.DELTA, false, false, false, "dba"
        ));

        assertEquals(List.of(target), resolved);
    }

    @Test
    void resolvesAllServicesAcrossAllDatabasesInDeterministicOrder() {
        InventoryService inventory = mock(InventoryService.class);
        when(inventory.listTargets()).thenReturn(List.of(
                target("dev", "workflow-service", "clickhouse"),
                target("dev", "customer-service", "postgres"),
                target("dev", "customer-service", "clickhouse"),
                target("qa", "customer-service", "postgres")
        ));

        TargetSelectionService service = new TargetSelectionService(inventory);
        var resolved = service.resolve(new MigrationRequest(
                ExecutionScope.ALL_SERVICES, null, null, "dev",
                true, RunMode.DELTA, false, false, false, "dba"
        ));

        assertEquals(List.of("customer-service", "customer-service", "workflow-service"),
                resolved.stream().map(MigrationTarget::service).toList());
        assertEquals(List.of("clickhouse", "postgres", "clickhouse"),
                resolved.stream().map(MigrationTarget::database).toList());
    }

    private MigrationTarget target(String environment, String service, String database) {
        return new MigrationTarget(environment, service, database, "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, false, null, Map.of(), false);
    }
}
