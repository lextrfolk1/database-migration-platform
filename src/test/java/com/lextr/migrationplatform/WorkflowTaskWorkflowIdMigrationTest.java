package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class WorkflowTaskWorkflowIdMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V4__add_workflow_id_to_tasks.sql";

    @Test
    void addsNullableWorkflowIdColumnToWorkflowTaskWithoutDroppingTheTable() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("ALTER TABLE wkfl.workflow_task"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS workflow_id bigint"));
        assertFalse(migrationSql.contains("NOT NULL"));
        assertFalse(migrationSql.contains("DROP TABLE"));
        assertFalse(migrationSql.contains("workflow_detail"));
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
