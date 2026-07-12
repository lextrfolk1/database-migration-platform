package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class SemanticLayerClassificationMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V3__semantic_layer_extensions.sql";

    @Test
    void definesGovernedClassificationReferenceAndAdditiveObjectAttributeAlterations() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS meta.data_classification_ref"));
        assertTrue(migrationSql.contains("ALTER TABLE meta.object_catalog"));
        assertTrue(migrationSql.contains("fk_oc_data_class_ref"));
        assertTrue(migrationSql.contains("REFERENCES meta.data_classification_ref (data_classification_cd)"));

        assertTrue(migrationSql.contains("ALTER TABLE meta.attribute_catalog"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS data_classification_cd varchar(30)"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS mnpi_flg boolean NOT NULL DEFAULT false"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS csi_flg boolean NOT NULL DEFAULT false"));
        assertTrue(migrationSql.contains("ADD COLUMN IF NOT EXISTS ai_exposure_cd varchar(20) NOT NULL DEFAULT 'RESTRICTED'"));
        assertTrue(migrationSql.contains("fk_ac_data_class_ref"));
        assertTrue(migrationSql.contains("ck_ac_ai_exposure"));
        assertFalse(migrationSql.contains("DROP TABLE IF EXISTS meta.object_catalog;"));
        assertFalse(migrationSql.contains("DROP TABLE IF EXISTS meta.attribute_catalog;"));
    }

    @Test
    void definesTenantScopedAttributeAccessGrantAndClassificationSeedRows() throws IOException {
        String migrationSql = loadMigrationSql();

        assertTrue(migrationSql.contains("CREATE TABLE IF NOT EXISTS meta.attribute_access_grant"));
        assertTrue(migrationSql.contains("client_id            varchar(40)  NOT NULL"));
        assertTrue(migrationSql.contains("REFERENCES meta.attribute_catalog (schema_cd, object_cd, attribute_cd)"));
        assertTrue(migrationSql.contains("CREATE INDEX IF NOT EXISTS ix_aag_client ON meta.attribute_access_grant (client_id)"));
        assertTrue(migrationSql.contains("('PUBLIC', 'Public'"));
        assertTrue(migrationSql.contains("('INTERNAL', 'Internal'"));
        assertTrue(migrationSql.contains("('CONFIDENTIAL', 'Confidential'"));
        assertTrue(migrationSql.contains("('RESTRICTED', 'Restricted'"));
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
