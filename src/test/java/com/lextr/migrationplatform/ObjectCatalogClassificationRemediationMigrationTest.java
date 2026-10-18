package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ObjectCatalogClassificationRemediationMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V10__remediate_object_catalog_classification.sql";

    @Test
    void updatesRestrictedClassificationInObjectCatalogToInternal() throws IOException {
        String migrationSql = loadMigrationSql(MIGRATION_PATH);

        assertTrue(migrationSql.contains("UPDATE meta.object_catalog"));
        assertTrue(migrationSql.contains("SET data_classification_cd = 'INTERNAL'"));
        assertTrue(migrationSql.contains("WHERE data_classification_cd = 'RESTRICTED'"));
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
