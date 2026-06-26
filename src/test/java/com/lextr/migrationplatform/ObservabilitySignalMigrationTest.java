package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ObservabilitySignalMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V4__observability_signal.sql";

    @Test
    void definesTenantScopedObservabilitySignalTableWithWorkflowCorrelation() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS meta.observability_signal"));
        assertTrue(migrationSql.contains("client_id               varchar(40)  NOT NULL"));
        assertTrue(migrationSql.contains("signal_type_cd          varchar(40)  NOT NULL"));
        assertTrue(migrationSql.contains("severity_cd             varchar(20)  NOT NULL DEFAULT 'INFO'"));
        assertTrue(migrationSql.contains("signal_status_cd        varchar(20)  NOT NULL DEFAULT 'OPEN'"));
        assertTrue(migrationSql.contains("source_system_cd        varchar(60)  NOT NULL"));
        assertTrue(migrationSql.contains("detected_ts             timestamptz  NOT NULL"));
        assertTrue(migrationSql.contains("source_entity_ref_txt   varchar(120)"));
        assertTrue(migrationSql.contains("workflow_task_id        bigint"));
        assertTrue(migrationSql.contains("CONSTRAINT ck_os_type CHECK (signal_type_cd IN"));
        assertTrue(migrationSql.contains("('FRESHNESS','VOLUME','SCHEMA_DRIFT','NULL_RATE_SPIKE','DISTRIBUTION_SHIFT')"));
        assertTrue(migrationSql.contains("CONSTRAINT ck_os_severity CHECK (severity_cd IN ('HIGH','WARN','INFO'))"));
        assertTrue(migrationSql.contains("CONSTRAINT ck_os_status CHECK (signal_status_cd IN ('OPEN','TRIAGE','ACK','RESOLVED'))"));
        assertTrue(migrationSql.contains("REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_client ON meta.observability_signal (client_id)"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_status ON meta.observability_signal"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_type ON meta.observability_signal"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_detected ON meta.observability_signal (detected_ts DESC)"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_os_workflow_task ON meta.observability_signal (workflow_task_id)"));
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
