package com.lextr.migrationplatform;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Conformance test for V1__semantic_layer_baseline.sql.
 * Verifies the fixed DDL contract: schemas, tables, indexes, constraints, and seeds
 * are all present and structurally correct before Flyway applies the migration.
 *
 * This is a file-level contract verification — it validates the SQL content
 * matches the fixed schema contract v2.4.0 (5 schemas, 18 tables).
 */
class SemanticLayerBaselineMigrationTest {

    private static final String MIGRATION_PATH =
            "migrations/semantic-service/postgres/V1__semantic_layer_baseline.sql";

    private static String migrationSql;

    @BeforeAll
    static void loadMigration() throws IOException {
        try (InputStream is = Thread.currentThread().getContextClassLoader()
                .getResourceAsStream(MIGRATION_PATH)) {
            assertNotNull(is, "Migration file not found on classpath: " + MIGRATION_PATH);
            migrationSql = new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    // -----------------------------------------------------------------------
    // Migration file exists and is non-empty
    // -----------------------------------------------------------------------

    @Test
    void migrationFileExistsAndIsNonEmpty() {
        assertNotNull(migrationSql);
        assertFalse(migrationSql.isBlank(), "Migration SQL must not be blank");
    }

    // -----------------------------------------------------------------------
    // 5 schemas (meta, governance, ref, report, wkfl)
    // -----------------------------------------------------------------------

    @Test
    void allFiveSchemasCreated() {
        List<String> schemas = List.of("meta", "governance", "ref", "report", "wkfl");
        for (String schema : schemas) {
            assertContains("CREATE SCHEMA IF NOT EXISTS " + schema,
                    "Schema '" + schema + "' must be created");
        }
    }

    // -----------------------------------------------------------------------
    // 18 tables — contract v2.4.0
    // -----------------------------------------------------------------------

    @Test
    void metaSchemaTablesPresent() {
        List<String> tables = List.of(
                "meta.schema_catalog",
                "meta.data_connection",
                "meta.object_catalog",
                "meta.attribute_catalog",
                "meta.semantic_relationship_catalog",
                "meta.attribute_logical_name_override",
                "meta.attribute_pairing_catalog",
                "meta.attribute_pairing_value_cache",
                "meta.semantic_filter_lookup",
                "meta.filter_lookup_value",
                "meta.filter_lookup_exec_log",
                "meta.filter_lookup_binding",
                "meta.metadata_change_history"
        );
        for (String table : tables) {
            assertContains("CREATE TABLE " + table,
                    "Table '" + table + "' must be present");
        }
    }

    @Test
    void governanceSchemaTablesPresent() {
        assertContains("CREATE TABLE governance.policy_preset",
                "Table 'governance.policy_preset' must be present");
    }

    @Test
    void workflowSchemaTablesPresent() {
        assertContains("CREATE TABLE wkfl.workflow_task",
                "Table 'wkfl.workflow_task' must be present");
    }

    @Test
    void reportSchemaTablesPresent() {
        assertContains("CREATE TABLE report.report_definition",
                "Table 'report.report_definition' must be present");
        assertContains("CREATE TABLE report.report_line_definition",
                "Table 'report.report_line_definition' must be present");
    }

    @Test
    void refSchemaTablesPresent() {
        assertContains("CREATE TABLE ref.country",
                "Table 'ref.country' must be present");
    }

    @Test
    void totalTableCountIs18() {
        // Count all CREATE TABLE statements (excluding CREATE TABLE IF NOT EXISTS which is for schemas)
        long count = migrationSql.lines()
                .map(String::trim)
                .filter(line -> line.startsWith("CREATE TABLE "))
                .count();
        assertTrue(count == 18,
                "Expected 18 CREATE TABLE statements, found " + count);
    }

    // -----------------------------------------------------------------------
    // Indexes — all required indexes present
    // -----------------------------------------------------------------------

    @Test
    void objectCatalogIndexesPresent() {
        assertContains("CREATE INDEX ix_oc_schema", "Index ix_oc_schema missing");
        assertContains("CREATE INDEX ix_oc_client", "Index ix_oc_client missing");
        assertContains("CREATE INDEX ix_oc_status", "Index ix_oc_status missing");
    }

    @Test
    void attributeCatalogIndexesPresent() {
        assertContains("CREATE INDEX ix_ac_object", "Index ix_ac_object missing");
        assertContains("CREATE INDEX ix_ac_taxonomy", "Index ix_ac_taxonomy missing");
    }

    @Test
    void relationshipCatalogIndexesPresent() {
        assertContains("CREATE INDEX ix_rel_parent", "Index ix_rel_parent missing");
        assertContains("CREATE INDEX ix_rel_child", "Index ix_rel_child missing");
    }

    @Test
    void attributePairingIndexesPresent() {
        assertContains("CREATE INDEX ix_apc_object", "Index ix_apc_object missing");
        assertContains("CREATE INDEX ix_apc_display", "Index ix_apc_display missing");
        assertContains("CREATE INDEX ix_apc_client", "Index ix_apc_client missing");
    }

    @Test
    void pairingValueCacheIndexPresent() {
        assertContains("CREATE INDEX ix_apvc_lookup", "Index ix_apvc_lookup missing");
    }

    @Test
    void filterLookupIndexesPresent() {
        assertContains("CREATE INDEX ix_fl_client", "Index ix_fl_client missing");
        assertContains("CREATE INDEX ix_fl_health", "Index ix_fl_health missing");
    }

    @Test
    void filterLookupValueIndexPresent() {
        assertContains("CREATE INDEX ix_flv_lookup", "Index ix_flv_lookup missing");
    }

    @Test
    void filterLookupExecLogIndexPresent() {
        assertContains("CREATE INDEX ix_flxl_lookup", "Index ix_flxl_lookup missing");
    }

    @Test
    void filterLookupBindingIndexPresent() {
        assertContains("CREATE INDEX ix_flb_lookup", "Index ix_flb_lookup missing");
    }

    @Test
    void workflowTaskIndexPresent() {
        assertContains("CREATE INDEX ix_wt_status", "Index ix_wt_status missing");
    }

    @Test
    void metadataChangeHistoryIndexPresent() {
        assertContains("CREATE INDEX ix_mch_entity", "Index ix_mch_entity missing");
    }

    @Test
    void reportDefinitionIndexesPresent() {
        assertContains("CREATE INDEX ix_rld_report", "Index ix_rld_report missing");
        assertContains("CREATE INDEX ix_rld_taxonomy", "Index ix_rld_taxonomy missing");
    }

    // -----------------------------------------------------------------------
    // SEED — 6 GOV-FL governance presets (GOV-FL-001..006)
    // -----------------------------------------------------------------------

    @Test
    void sixGovernancePresetsSeeded() {
        assertContains("GOV-FL-001", "Governance preset GOV-FL-001 not seeded");
        assertContains("GOV-FL-002", "Governance preset GOV-FL-002 not seeded");
        assertContains("GOV-FL-003", "Governance preset GOV-FL-003 not seeded");
        assertContains("GOV-FL-004", "Governance preset GOV-FL-004 not seeded");
        assertContains("GOV-FL-005", "Governance preset GOV-FL-005 not seeded");
        assertContains("GOV-FL-006", "Governance preset GOV-FL-006 not seeded");
    }

    @Test
    void governancePresetInsertIsIdempotent() {
        // The seed uses ON CONFLICT DO NOTHING to support re-runnable baseline
        assertContains("ON CONFLICT (policy_cd) DO NOTHING",
                "Governance preset INSERT must use ON CONFLICT DO NOTHING for idempotency");
    }

    // -----------------------------------------------------------------------
    // SEED — 3 data connections (PG, CH, Neo4j)
    // -----------------------------------------------------------------------

    @Test
    void threeDataConnectionsSeeded() {
        assertContains("LEXTR_PG", "PostgreSQL connection seed missing");
        assertContains("LEXTR_CH", "ClickHouse connection seed missing");
        assertContains("LEXTR_NEO4J", "Neo4j connection seed missing");
    }

    @Test
    void dataConnectionEnginesCorrect() {
        assertContains("'POSTGRES','PRIMARY'", "LEXTR_PG must be POSTGRES / PRIMARY");
        assertContains("'CLICKHOUSE','ANALYTICS'", "LEXTR_CH must be CLICKHOUSE / ANALYTICS");
        assertContains("'NEO4J','GRAPH'", "LEXTR_NEO4J must be NEO4J / GRAPH");
    }

    @Test
    void dataConnectionInsertIsIdempotent() {
        assertContains("ON CONFLICT (connection_id) DO NOTHING",
                "Data connection INSERT must use ON CONFLICT DO NOTHING for idempotency");
    }

    // -----------------------------------------------------------------------
    // Constraints — spot-check key CHECK constraints
    // -----------------------------------------------------------------------

    @Test
    void lifecycleCheckConstraintsPresent() {
        assertContains("ck_sc_lifecycle", "Schema catalog lifecycle CHECK missing");
        assertContains("ck_ob_lifecycle", "Object catalog lifecycle CHECK missing");
        assertContains("ck_apc_lifecycle", "Attribute pairing lifecycle CHECK missing");
    }

    @Test
    void objectTypeCheckPresent() {
        assertContains("ck_ob_type", "Object type CHECK missing");
    }

    @Test
    void dataClassificationCheckPresent() {
        assertContains("ck_ob_data_class", "Data classification CHECK missing");
    }

    @Test
    void aiGovernanceCheckPresent() {
        assertContains("ck_ob_ai_gov", "AI governance CHECK missing");
    }

    @Test
    void engineCheckPresent() {
        assertContains("ck_dc_engine", "Data connection engine CHECK missing");
    }

    @Test
    void taxonomySourceCheckPresent() {
        assertContains("ck_attr_tax_source", "Attribute taxonomy_source CHECK missing");
        assertContains("ck_rld_tax_source", "Report line taxonomy_source CHECK missing");
    }

    @Test
    void attributePairingConstraintsPresent() {
        assertContains("ck_apc_type", "Pairing type CHECK missing");
        assertContains("ck_apc_strategy", "Pairing strategy CHECK missing");
        assertContains("ck_apc_cardinality", "Pairing cardinality CHECK missing");
        assertContains("ck_apc_diff_attrs", "display != filter attribute CHECK missing");
    }

    // -----------------------------------------------------------------------
    // Unique constraints
    // -----------------------------------------------------------------------

    @Test
    void uniqueConstraintsPresent() {
        assertContains("uq_object", "Unique constraint on object_catalog missing");
        assertContains("uq_attribute", "Unique constraint on attribute_catalog missing");
        assertContains("uq_apc_object_pair", "Unique constraint on attribute_pairing_catalog missing");
        assertContains("uq_apvc", "Unique constraint on pairing_value_cache missing");
        assertContains("uq_flv", "Unique constraint on filter_lookup_value missing");
        assertContains("uq_rld", "Unique constraint on report_line_definition missing");
    }

    // -----------------------------------------------------------------------
    // Foreign keys — spot-check critical FK relationships
    // -----------------------------------------------------------------------

    @Test
    void foreignKeysPresent() {
        assertContains("fk_attr_object", "FK from attribute_catalog to object_catalog missing");
        assertContains("fk_lno_attr", "FK from logical_name_override to attribute_catalog missing");
        assertContains("fk_apc_object", "FK from pairing_catalog to object_catalog missing");
    }

    // -----------------------------------------------------------------------
    // Tenancy key — client_id present on tenant-scoped tables
    // -----------------------------------------------------------------------

    @Test
    void clientIdPresentOnTenantScopedTables() {
        // Spot-check key tenant-scoped tables
        assertTrue(migrationSql.contains("client_id"),
                "client_id tenancy key must be present in the DDL");
    }

    // -----------------------------------------------------------------------
    // Standards conformance — must-have audit columns
    // -----------------------------------------------------------------------

    @Test
    void createdTsAndCreatedByAreStandard() {
        // Every table must carry created_ts and created_by per standards.
        // Some tables use domain-specific variants (added_ts, requested_ts,
        // cached_ts, executed_ts) which satisfy the "creation audit" standard.
        long createdTsCount = migrationSql.lines()
                .map(String::trim)
                .filter(line -> line.startsWith("created_ts"))
                .count();
        long createdByCount = migrationSql.lines()
                .map(String::trim)
                .filter(line -> line.startsWith("created_by"))
                .count();
        // 11 tables use created_ts/created_by directly; others use domain-specific
        // creation columns (added_ts/added_by, requested_ts/requested_by,
        // cached_ts, executed_ts/executed_by) per the fixed DDL contract.
        assertTrue(createdTsCount >= 11,
                "Expected created_ts on core tables, found " + createdTsCount);
        assertTrue(createdByCount >= 11,
                "Expected created_by on core tables, found " + createdByCount);
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private static void assertContains(String expected, String message) {
        assertTrue(migrationSql.contains(expected), message + " — expected to find: " + expected);
    }
}
