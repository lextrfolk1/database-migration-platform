package com.lextr.migrationplatform;

import com.lextr.migrationplatform.adapter.ClickHouseDatabaseAdapter;
import com.lextr.migrationplatform.adapter.PostgresDatabaseAdapter;
import com.lextr.migrationplatform.model.MigrationTarget;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DatabaseAdapterTest {

    @Test
    void buildsPostgresFlywayConfig() {
        PostgresDatabaseAdapter adapter = new PostgresDatabaseAdapter();
        var config = adapter.getFlywayTargetConfiguration(target("postgres", "org.postgresql.Driver"));
        assertEquals("org.postgresql.Driver", config.driverClassName());
        assertTrue(adapter.supportsTransactions());
        assertTrue(adapter.supportsClean());
    }

    @Test
    void buildsClickHouseFlywayConfig() {
        ClickHouseDatabaseAdapter adapter = new ClickHouseDatabaseAdapter();
        var config = adapter.getFlywayTargetConfiguration(target("clickhouse", "com.clickhouse.jdbc.ClickHouseDriver"));
        assertEquals("com.clickhouse.jdbc.ClickHouseDriver", config.driverClassName());
        assertFalse(adapter.supportsTransactions());
        assertFalse(adapter.supportsClean());
    }

    private MigrationTarget target(String databaseType, String driver) {
        return new MigrationTarget("dev", "svc", "target-a", databaseType, "jdbc:test", "user", "pw", driver,
                List.of("classpath:test"), List.of("public"), true, "0", false, "flyway_history_svc", Map.of());
    }
}
