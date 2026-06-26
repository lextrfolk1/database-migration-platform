package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ObservabilityPolicyPresetLookupMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V7__observability_policy_preset_lookup_index.sql";

    @Test
    void definesPolicyPresetLookupIndexForObservabilityThresholdResolution() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_pp_scope_code_effective"));
        assertTrue(migrationSql.contains("ON governance.policy_preset (policy_scope_cd, policy_cd, effective_from_dt DESC, effective_to_dt)"));
        assertFalse(migrationSql.contains("DROP TABLE IF EXISTS governance.policy_preset;"));
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
