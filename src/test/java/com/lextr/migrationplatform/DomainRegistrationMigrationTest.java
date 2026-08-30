package com.lextr.migrationplatform;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class DomainRegistrationMigrationTest {

    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V6__domain_registration_and_governed_ai_resolve.sql";

    @Test
    void verifiesCombinedDomainRegistrationMigration() throws IOException {
        String sql = loadMigrationSql(MIGRATION_PATH);
        // Domain catalog & domain value
        assertTrue(sql.contains("CREATE TABLE IF NOT EXISTS meta.domain_catalog"));
        assertTrue(sql.contains("CREATE TABLE IF NOT EXISTS meta.domain_value"));
        assertTrue(sql.contains("domain_source_cd"));
        assertTrue(sql.contains("INLINE"));
        assertTrue(sql.contains("ENUMERATED"));
        assertTrue(sql.contains("REFERENCE_TABLE"));
        assertTrue(sql.contains("version_nbr"));
        assertTrue(sql.contains("value_count_nbr"));
        assertTrue(sql.contains("ai_exposure_cd"));

        // Attribute catalog domain columns
        assertTrue(sql.contains("ALTER TABLE meta.attribute_catalog"));
        assertTrue(sql.contains("ADD COLUMN IF NOT EXISTS domain_cd varchar(60)"));
        assertTrue(sql.contains("ADD COLUMN IF NOT EXISTS domain_source_cd varchar(30)"));

        // Domain value synonym
        assertTrue(sql.contains("CREATE TABLE IF NOT EXISTS meta.domain_value_synonym"));
        assertTrue(sql.contains("synonym_txt"));

        // Domain value source map
        assertTrue(sql.contains("CREATE TABLE IF NOT EXISTS meta.domain_value_source_map"));
        assertTrue(sql.contains("source_system_cd"));

        // Domain value text
        assertTrue(sql.contains("CREATE TABLE IF NOT EXISTS meta.domain_value_text"));
        assertTrue(sql.contains("locale_cd"));

        // Policy presets
        assertTrue(sql.contains("DOMAIN_INLINE_MAX_CARDINALITY"));
        assertTrue(sql.contains("DOMAIN_MAX_ENUMERATE_CARDINALITY"));
        assertTrue(sql.contains("DOMAIN_RESOLVE_TTL_SECONDS"));
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
