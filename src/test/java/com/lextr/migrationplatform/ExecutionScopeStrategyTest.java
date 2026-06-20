package com.lextr.migrationplatform;

import com.lextr.migrationplatform.model.ExecutionScope;
import com.lextr.migrationplatform.model.MigrationRequest;
import com.lextr.migrationplatform.model.MigrationTarget;
import com.lextr.migrationplatform.model.RunMode;
import com.lextr.migrationplatform.strategy.AllDatabasesExecutionStrategy;
import com.lextr.migrationplatform.strategy.AllServicesExecutionStrategy;
import com.lextr.migrationplatform.strategy.SingleServiceExecutionStrategy;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ExecutionScopeStrategyTest {

    @Test
    void selectsSingleServiceTarget() {
        SingleServiceExecutionStrategy strategy = new SingleServiceExecutionStrategy();
        var targets = strategy.selectTargets(request(ExecutionScope.SERVICE, false), List.of(
                target("dev", "generic-service", "postgres-main-dev", "postgres"),
                target("dev", "workflow-service", "postgres-main-dev", "postgres")
        ));

        assertEquals(1, targets.size());
        assertEquals("generic-service", targets.get(0).service());
    }

    @Test
    void selectsAllServicesForOneDatabaseInOrder() {
        AllServicesExecutionStrategy strategy = new AllServicesExecutionStrategy();
        var targets = strategy.selectTargets(request(ExecutionScope.ALL_SERVICES, false), List.of(
                target("dev", "workflow-service", "postgres-main-dev", "postgres"),
                target("dev", "generic-service", "postgres-main-dev", "postgres"),
                target("dev", "generic-service", "clickhouse-analytics-dev", "clickhouse")
        ));

        assertEquals(List.of("generic-service", "workflow-service"), targets.stream().map(MigrationTarget::service).toList());
    }

    @Test
    void selectsAllServicesForAllDatabasesInOrder() {
        AllDatabasesExecutionStrategy strategy = new AllDatabasesExecutionStrategy();
        var targets = strategy.selectTargets(request(ExecutionScope.ALL_SERVICES, true), List.of(
                target("dev", "workflow-service", "clickhouse-analytics-dev", "clickhouse"),
                target("dev", "generic-service", "postgres-main-dev", "postgres"),
                target("dev", "generic-service", "clickhouse-analytics-dev", "clickhouse")
        ));

        assertEquals(List.of("clickhouse-analytics-dev", "postgres-main-dev", "clickhouse-analytics-dev"),
                targets.stream().map(MigrationTarget::targetName).toList());
    }

    private MigrationRequest request(ExecutionScope scope, boolean allTargets) {
        return new MigrationRequest(scope, "generic-service", "postgres-main-dev", "postgres", "dev", allTargets,
                RunMode.DELTA, false, false, false, "dba");
    }

    private MigrationTarget target(String environment, String service, String targetName, String databaseType) {
        return new MigrationTarget(environment, service, targetName, databaseType, "jdbc:test", "user", "pw", "driver",
                List.of("classpath:test"), List.of(), true, "0", false, "flyway_history_" + service, Map.of());
    }
}
