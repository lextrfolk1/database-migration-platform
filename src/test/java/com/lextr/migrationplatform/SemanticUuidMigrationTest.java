package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class SemanticUuidMigrationTest {

    private static final String V12_PATH = "migrations/semantic-service/postgres/V12__backfill_object_entity_ref.sql";
    private static final String V13_PATH = "migrations/semantic-service/postgres/V13__consumption_outbound_object_id_to_bigint.sql";
    private static final String V14_PATH = "migrations/semantic-service/postgres/V14__add_uat_to_consumption_sdlc_status.sql";

    @Test
    void verifiesV12BackfillsObjectEntityRef() throws IOException {
        String sql = loadMigrationSql(V12_PATH);

        assertTrue(sql.contains("UPDATE wkfl.workflow_task"));
        assertTrue(sql.contains("UPDATE meta.metadata_change_history"));
        assertTrue(sql.contains("SET entity_ref = oc.id::text"));
    }

    @Test
    void verifiesV13ConvertsConsumptionOutboundObjectIdToBigint() throws IOException {
        String sql = loadMigrationSql(V13_PATH);

        assertTrue(sql.contains("ALTER TABLE meta.consumption_outbound ADD COLUMN IF NOT EXISTS object_id_new bigint"));
        assertTrue(sql.contains("UPDATE meta.consumption_outbound co"));
        assertTrue(sql.contains("SET object_id_new = oc.id"));
        assertTrue(sql.contains("ALTER TABLE meta.consumption_outbound RENAME COLUMN object_id_new TO object_id"));
        assertTrue(sql.contains("CREATE INDEX IF NOT EXISTS ix_co_lookup ON meta.consumption_outbound (client_id, object_id, outbound_cd)"));
    }

    @Test
    void verifiesV14AddsUatToConsumptionSdlcStatus() throws IOException {
        String sql = loadMigrationSql(V14_PATH);

        assertTrue(sql.contains("DROP CONSTRAINT IF EXISTS ck_co_sdlc"));
        assertTrue(sql.contains("CHECK (sdlc_status_cd IN ('DEV', 'QA', 'UAT', 'PROD'))"));
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
