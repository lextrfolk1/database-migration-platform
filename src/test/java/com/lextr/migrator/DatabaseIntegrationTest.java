package com.lextr.migrator;

import com.lextr.migrator.integrations.databases.clickhouse.ClickHouseDatabaseIntegration;
import com.lextr.migrator.integrations.databases.postgres.PostgresDatabaseIntegration;
import com.lextr.migrator.platform.inventory.MigrationTarget;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DatabaseIntegrationTest {

    @Test
    void buildsPostgresFlywayConfig() {
        PostgresDatabaseIntegration integration = new PostgresDatabaseIntegration();
        var config = integration.getFlywayConfig(target("postgres", "org.postgresql.Driver"));
        assertEquals("org.postgresql.Driver", config.driverClassName());
        assertTrue(integration.supportsTransactions());
        assertTrue(integration.supportsClean());
    }

    @Test
    void buildsClickHouseFlywayConfig() {
        ClickHouseDatabaseIntegration integration = new ClickHouseDatabaseIntegration();
        var config = integration.getFlywayConfig(target("clickhouse", "com.clickhouse.jdbc.ClickHouseDriver"));
        assertEquals("com.clickhouse.jdbc.ClickHouseDriver", config.driverClassName());
        assertFalse(integration.supportsTransactions());
        assertFalse(integration.supportsClean());
    }

    private MigrationTarget target(String database, String driver) {
        return new MigrationTarget("dev", "svc", database, "jdbc:test", "user", "pw", driver,
                List.of("classpath:test"), List.of("public"), true, false, "flyway_history", Map.of(), false);
    }
}
