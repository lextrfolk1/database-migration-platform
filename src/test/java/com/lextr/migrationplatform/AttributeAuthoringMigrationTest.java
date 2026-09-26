package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class AttributeAuthoringMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V9__attribute_catalog_extended_authoring.sql";

    @Test
    void verifiesAttributeCatalogExtendedAuthoringMigration() throws IOException {
        String sql = loadMigrationSql(MIGRATION_PATH);

        // Multi-tenancy & Governance
        assertTrue(sql.contains("ALTER TABLE meta.attribute_catalog"));
        assertTrue(sql.contains("client_id"));
        assertTrue(sql.contains("semantic_role_cd"));
        assertTrue(sql.contains("semantic_enabled_flg"));
        assertTrue(sql.contains("ai_exposed_flg"));
        assertTrue(sql.contains("element_class_cd"));
        assertTrue(sql.contains("element_class_source_cd"));
        assertTrue(sql.contains("domain_mode_cd"));
        assertTrue(sql.contains("domain_values_jsonb"));
        assertTrue(sql.contains("domain_ref_table_nm"));
        assertTrue(sql.contains("domain_ref_code_col"));
        assertTrue(sql.contains("domain_ref_desc_col"));
        assertTrue(sql.contains("insert_mode_cd"));
        assertTrue(sql.contains("update_mode_cd"));
        assertTrue(sql.contains("delete_mode_cd"));
        assertTrue(sql.contains("immutable_flg"));
        assertTrue(sql.contains("null_on_insert_flg"));
        assertTrue(sql.contains("attr_source_system_cd"));
        assertTrue(sql.contains("effective_start_dt"));
        assertTrue(sql.contains("effective_end_dt"));

        // Constraints
        assertTrue(sql.contains("ck_ac_element_class"));
        assertTrue(sql.contains("ck_ac_domain_mode"));

        // Indexes
        assertTrue(sql.contains("ix_ac_client"));
        assertTrue(sql.contains("ix_ac_element_class"));
        assertTrue(sql.contains("ix_ac_domain_mode"));
        assertTrue(sql.contains("ix_ac_semantic_role"));
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
