package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class AttributePromotionTaskLinkMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V12__link_attribute_promotion_task.sql";

    @Test
    void verifiesAttributePromotionTaskLinkMigration() throws IOException {
        String migrationSql = loadMigrationSql(MIGRATION_PATH);

        assertTrue(migrationSql.contains("ALTER TABLE meta.attribute_catalog"));
        assertTrue(migrationSql.contains("promotion_workflow_task_id bigint"));
        assertTrue(migrationSql.contains("REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_ac_promotion_workflow"));
        assertTrue(migrationSql.contains("ON meta.attribute_catalog (promotion_workflow_task_id)"));
        assertTrue(migrationSql.contains("ATTRIBUTE_PROMOTION"));
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
