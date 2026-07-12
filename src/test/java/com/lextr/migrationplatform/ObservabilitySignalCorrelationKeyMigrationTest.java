package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ObservabilitySignalCorrelationKeyMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V3__semantic_layer_extensions.sql";

    @Test
    void definesCorrelationKeyIndexForObservabilitySignalLookups() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_client_corr_key"));
        assertTrue(migrationSql.contains("ON meta.observability_signal (client_id, correlation_key_txt)"));
        assertFalse(migrationSql.contains("DROP TABLE IF EXISTS meta.observability_signal;"));
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
