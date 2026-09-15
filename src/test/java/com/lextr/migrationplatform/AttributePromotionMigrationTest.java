package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class AttributePromotionMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V7__attribute_promotion_provenance.sql";

    @Test
    void verifiesAttributePromotionMigration() throws IOException {
        String sql = loadMigrationSql(MIGRATION_PATH);

        // Attribute catalog provenance columns
        assertTrue(sql.contains("ALTER TABLE meta.attribute_catalog"));
        assertTrue(sql.contains("source_expression_txt"));
        assertTrue(sql.contains("derivation_formula_txt"));
        assertTrue(sql.contains("derivation_type_cd"));
        assertTrue(sql.contains("provenance_type_cd"));
        assertTrue(sql.contains("promoted_from_ref"));
        assertTrue(sql.contains("promoted_ts"));
        assertTrue(sql.contains("promoted_by"));

        // Derivation & provenance constraints
        assertTrue(sql.contains("ck_ac_derivation_type"));
        assertTrue(sql.contains("DIRECT"));
        assertTrue(sql.contains("DERIVED"));
        assertTrue(sql.contains("CALCULATED"));
        assertTrue(sql.contains("AGGREGATED"));

        assertTrue(sql.contains("ck_ac_provenance_type"));
        assertTrue(sql.contains("SYSTEM"));
        assertTrue(sql.contains("USER_PROMOTED"));
        assertTrue(sql.contains("AI_INFERRED"));

        // Indices
        assertTrue(sql.contains("ix_ac_provenance_type"));
        assertTrue(sql.contains("ix_ac_promoted_from_ref"));

        // Policy presets
        assertTrue(sql.contains("ATTRIBUTE_PROMOTION_REQUIRES_APPROVAL"));
        assertTrue(sql.contains("ATTRIBUTE_PROMOTION_AUTO_GOVERN"));
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
