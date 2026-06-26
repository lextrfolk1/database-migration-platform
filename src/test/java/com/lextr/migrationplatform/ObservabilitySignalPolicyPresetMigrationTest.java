package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ObservabilitySignalPolicyPresetMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V5__observability_signal_policies.sql";

    @Test
    void seedsObservabilityPolicyThresholdsForWorkflowRoutingAndDqReruns() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("INSERT INTO governance.policy_preset"));
        assertTrue(migrationSql.contains("('GOV-OS-001', 'Observability workflow route severity floor', 'OBSERVABILITY_SIGNAL', 'WARN', 'STRING', true, true)"));
        assertTrue(migrationSql.contains("('GOV-OS-002', 'Observability DQ rerun severity floor', 'OBSERVABILITY_SIGNAL', 'HIGH', 'STRING', true, true)"));
        assertTrue(migrationSql.contains("ON CONFLICT (policy_cd) DO NOTHING"));
    }

    private static String loadMigrationSql() throws IOException {
        try (InputStream inputStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(MIGRATION_PATH)) {
            if (inputStream == null) {
                fail("Migration file not found on classpath: " + MIGRATION_PATH);
            }
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}
