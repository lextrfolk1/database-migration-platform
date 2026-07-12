package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class MetadataChangeHistoryEntityRefIndexMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V3__semantic_layer_extensions.sql";

    @Test
    void definesMetadataChangeHistoryLookupIndexForEntityRefReads() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_mch_entity_ref_lookup"));
        assertTrue(migrationSql.contains("ON meta.metadata_change_history ("));
        assertTrue(migrationSql.contains("entity_type_cd"));
        assertTrue(migrationSql.contains("entity_ref"));
        assertTrue(migrationSql.contains("changed_ts DESC"));
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
