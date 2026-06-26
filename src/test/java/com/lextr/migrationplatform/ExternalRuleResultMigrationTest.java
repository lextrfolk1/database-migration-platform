package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class ExternalRuleResultMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V10__external_rule_result.sql";

    @Test
    void definesAdditiveExternalRuleResultTableAndLookupIndexes() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS meta.external_rule_result"));
        assertTrue(migrationSql.contains("id                  bigserial    PRIMARY KEY"));
        assertTrue(migrationSql.contains("client_id           varchar(40)  NOT NULL"));
        assertTrue(migrationSql.contains("outbound_id         bigint       NOT NULL"));
        assertTrue(migrationSql.contains("REFERENCES meta.consumption_outbound (id)"));
        assertTrue(migrationSql.contains("rule_ref_cd         varchar(120) NOT NULL"));
        assertTrue(migrationSql.contains("output_kind_cd      varchar(40)  NOT NULL"));
        assertTrue(migrationSql.contains("output_payload_jsonb jsonb"));
        assertTrue(migrationSql.contains("observed_ts         timestamptz   NOT NULL"));
        assertTrue(migrationSql.contains("created_ts          timestamptz   NOT NULL DEFAULT now()"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_err_client"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_err_outbound"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_err_rule_ref"));
        assertFalse(migrationSql.contains("DROP TABLE IF EXISTS meta.external_rule_result"));
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
