package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class LogicalPhysicalResolutionLookupMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V3__semantic_layer_extensions.sql";

    @Test
    void definesLookupIndexesForLogicalPhysicalResolutionReads() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_alno_lookup"));
        assertTrue(migrationSql.contains("ON meta.attribute_logical_name_override ("));
        assertTrue(migrationSql.contains("override_status_cd"));
        assertTrue(migrationSql.contains("approved_ts DESC"));
        assertTrue(migrationSql.contains("requested_ts DESC"));
        assertTrue(migrationSql.contains("id DESC"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_cog_outbound_lookup"));
        assertTrue(migrationSql.contains("ON meta.consumption_outbound_grain ("));
        assertTrue(migrationSql.contains("client_id"));
        assertTrue(migrationSql.contains("outbound_id"));
        assertTrue(migrationSql.contains("grain_level_nbr"));
        assertTrue(migrationSql.contains("logical_attribute_cd"));
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
