package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class DataConnectionClientIdMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V11__add_missing_client_id_to_data_connection.sql";

    @Test
    void addsClientIdColumnToDataConnection() throws IOException {
        String migrationSql = loadMigrationSql(MIGRATION_PATH);

        assertTrue(migrationSql.contains("ALTER TABLE meta.data_connection"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS client_id varchar(40) NOT NULL DEFAULT 'GLOBAL'"));
        assertTrue(migrationSql.contains("UPDATE meta.data_connection SET client_id = 'GLOBAL'"));
    }

    private static String loadMigrationSql(String path) throws IOException {
        try (InputStream inputStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(path)) {
            if (inputStream == null) {
                fail("Migration file not found on classpath: " + path);
            }
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}
