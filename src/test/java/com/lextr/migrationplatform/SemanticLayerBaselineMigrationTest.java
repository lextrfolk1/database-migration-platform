package com.lextr.migrationplatform;

import com.lextr.migrationplatform.adapter.FlywayOperations;
import com.lextr.migrationplatform.adapter.PostgresDatabaseAdapter;
import com.lextr.migrationplatform.adapter.PostgresFlywayAdapter;
import com.lextr.migrationplatform.model.MigrationTarget;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assumptions;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

class SemanticLayerBaselineMigrationTest {

    private static final String DATABASE_NAME = "semantic_baseline";
    private static final String USERNAME = "postgres";
    private static final String PASSWORD = "postgres";
    private static final String HISTORY_TABLE = "flyway_history_semantic_service";
    private static final String MIGRATION_PATH = "migrations/semantic-service/postgres/V1__semantic_layer_baseline.sql";
    private static final List<String> MANAGED_SCHEMAS = List.of("meta", "governance", "ref", "report", "wkfl");
    private static final Set<String> EXPECTED_TABLES = Set.of(
            "governance.policy_preset",
            "meta.attribute_catalog",
            "meta.attribute_logical_name_override",
            "meta.attribute_pairing_catalog",
            "meta.attribute_pairing_value_cache",
            "meta.data_connection",
            "meta.filter_lookup_binding",
            "meta.filter_lookup_exec_log",
            "meta.filter_lookup_value",
            "meta.metadata_change_history",
            "meta.object_catalog",
            "meta.schema_catalog",
            "meta.semantic_filter_lookup",
            "meta.semantic_relationship_catalog",
            "ref.country",
            "report.report_definition",
            "report.report_line_definition",
            "wkfl.workflow_task"
    );
    private static final Set<String> EXPECTED_INDEXES = Set.of(
            "ix_ac_object",
            "ix_ac_taxonomy",
            "ix_apc_client",
            "ix_apc_display",
            "ix_apc_object",
            "ix_apvc_lookup",
            "ix_fl_client",
            "ix_fl_health",
            "ix_flb_lookup",
            "ix_flv_lookup",
            "ix_flxl_lookup",
            "ix_mch_entity",
            "ix_oc_client",
            "ix_oc_schema",
            "ix_oc_status",
            "ix_rel_child",
            "ix_rel_parent",
            "ix_rld_report",
            "ix_rld_taxonomy",
            "ix_wt_status"
    );
    private static final Set<String> EXPECTED_CONSTRAINTS = Set.of(
            "ck_apc_cardinality",
            "ck_apc_diff_attrs",
            "ck_apc_lifecycle",
            "ck_apc_strategy",
            "ck_apc_type",
            "ck_attr_tax_source",
            "ck_dc_engine",
            "ck_fl_gov",
            "ck_fl_strat",
            "ck_fl_sub",
            "ck_fl_ctype",
            "ck_flb_ctx",
            "ck_flv_life",
            "ck_flxl_status",
            "ck_lno_status",
            "ck_ob_ai_gov",
            "ck_ob_data_class",
            "ck_ob_lifecycle",
            "ck_ob_type",
            "ck_pp_dtype",
            "ck_rel_card",
            "ck_rld_tax_source",
            "ck_sc_lifecycle",
            "ck_wt_status",
            "fk_apc_object",
            "fk_attr_object",
            "fk_lno_attr",
            "uq_apc_object_pair",
            "uq_apvc",
            "uq_attribute",
            "uq_flv",
            "uq_object",
            "uq_rld"
    );
    private static final Map<String, String> EXPECTED_POLICY_DEFAULTS = Map.of(
            "GOV-FL-001", "90",
            "GOV-FL-002", "180",
            "GOV-FL-003", "14",
            "GOV-FL-004", "true",
            "GOV-FL-005", "500",
            "GOV-FL-006", "0.5"
    );
    private static final Map<String, String> EXPECTED_POLICY_TYPES = Map.of(
            "GOV-FL-001", "INTEGER",
            "GOV-FL-002", "INTEGER",
            "GOV-FL-003", "INTEGER",
            "GOV-FL-004", "BOOLEAN",
            "GOV-FL-005", "INTEGER",
            "GOV-FL-006", "DECIMAL"
    );
    private static final Map<String, ConnectionSeedExpectation> EXPECTED_CONNECTIONS = Map.of(
            "LEXTR_CH", new ConnectionSeedExpectation("CLICKHOUSE", "ANALYTICS", false),
            "LEXTR_NEO4J", new ConnectionSeedExpectation("NEO4J", "GRAPH", false),
            "LEXTR_PG", new ConnectionSeedExpectation("POSTGRES", "PRIMARY", true)
    );
    private static final Pattern PORT_PATTERN = Pattern.compile(".*:(\\d+)$");

    private static String containerName;
    private static String jdbcUrl;
    private static String migrationSql;

    private static boolean isDockerRunning() {
        try {
            Process process = new ProcessBuilder("docker", "info").start();
            boolean completed = process.waitFor(5, TimeUnit.SECONDS);
            return completed && process.exitValue() == 0;
        } catch (Exception exception) {
            return false;
        }
    }

    @BeforeAll
    static void migrateBaselineIntoPostgres16() throws Exception {
        loadMigrationSql();
        if (!isDockerRunning()) {
            return;
        }
        containerName = "semantic-layer-baseline-" + UUID.randomUUID().toString().replace("-", "");
        startPostgres16Container();
        waitForDatabase();
        runFlywayCleanAndMigrate();
    }

    @AfterAll
    static void stopPostgres16Container() {
        if (containerName == null) {
            return;
        }
        try {
            runCommand(List.of("docker", "rm", "-f", containerName), Duration.ofSeconds(30), false);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
        } catch (IOException ignored) {
        }
    }

    @Test
    void sqlFileContainsSchemasAnd18TablesAnd20IndexesAndSeedStatements() throws IOException {
        if (migrationSql == null) {
            loadMigrationSql();
        }
        for (String schema : MANAGED_SCHEMAS) {
            assertTrue(migrationSql.contains("CREATE SCHEMA IF NOT EXISTS " + schema + ";"),
                    "Missing schema declaration for " + schema);
        }
        for (String qualifiedTable : EXPECTED_TABLES) {
            assertTrue(migrationSql.contains("CREATE TABLE " + qualifiedTable + " ("),
                    "Missing CREATE TABLE statement for " + qualifiedTable);
        }
        for (String indexName : EXPECTED_INDEXES) {
            assertTrue(migrationSql.contains("CREATE INDEX " + indexName + " "),
                    "Missing CREATE INDEX statement for " + indexName);
        }
        for (String policyCd : EXPECTED_POLICY_DEFAULTS.keySet()) {
            assertTrue(migrationSql.contains("'" + policyCd + "'"),
                    "Missing seed insert statement for governance policy preset " + policyCd);
        }
        for (String connCd : EXPECTED_CONNECTIONS.keySet()) {
            assertTrue(migrationSql.contains("'" + connCd + "'"),
                    "Missing seed insert statement for data connection " + connCd);
        }
    }

    @Test
    void flywayCleanAndMigrateAppliedV1Baseline() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "select version, success from meta." + HISTORY_TABLE + " where version = ?")) {
            statement.setString(1, "1");
            try (ResultSet resultSet = statement.executeQuery()) {
                assertTrue(resultSet.next(), "Expected Flyway history entry for V1 baseline migration");
                assertTrue(resultSet.getBoolean("success"), "V1 baseline migration must succeed");
                assertFalse(resultSet.next(), "Expected a single Flyway history row for version 1");
            }
        }
    }

    @Test
    void allExpectedTablesExist() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        String sql = """
                select table_schema || '.' || table_name as qualified_name
                from information_schema.tables
                where table_schema in ('meta', 'governance', 'ref', 'report', 'wkfl')
                  and table_type = 'BASE TABLE'
                  and table_name <> ?
                order by qualified_name
                """;
        Set<String> actualTables = new LinkedHashSet<>();
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, HISTORY_TABLE);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    actualTables.add(resultSet.getString("qualified_name"));
                }
            }
        }
        assertEquals(EXPECTED_TABLES, actualTables, "Baseline migration must create the fixed 18 semantic-layer tables");
    }

    @Test
    void allExpectedIndexesExist() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        String sql = """
                select indexname
                from pg_indexes
                where schemaname in ('meta', 'governance', 'ref', 'report', 'wkfl')
                """;
        Set<String> actualIndexes = querySingleColumnSet(sql, "indexname");
        assertTrue(actualIndexes.containsAll(EXPECTED_INDEXES),
                "Baseline migration is missing required indexes: " + difference(EXPECTED_INDEXES, actualIndexes));
    }

    @Test
    void allExpectedNamedConstraintsExist() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        String sql = """
                select constraint_name
                from information_schema.table_constraints
                where table_schema in ('meta', 'governance', 'ref', 'report', 'wkfl')
                """;
        Set<String> actualConstraints = querySingleColumnSet(sql, "constraint_name");
        assertTrue(actualConstraints.containsAll(EXPECTED_CONSTRAINTS),
                "Baseline migration is missing required constraints: " + difference(EXPECTED_CONSTRAINTS, actualConstraints));
    }

    @Test
    void filterLookupBindingConstraintAllowsQueryStudioBindingContext() {
        if (migrationSql == null) {
            try {
                loadMigrationSql();
            } catch (IOException e) {
                fail(e);
            }
        }
        assertTrue(migrationSql.contains("CONSTRAINT ck_flb_ctx CHECK (binding_context_cd IN"));
        assertTrue(migrationSql.contains("('RULE','QUERY_STUDIO','PIPELINE','LEXIE')"));
    }

    @Test
    void sixGovernancePresetsSeeded() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        Map<String, String> defaultValues = new LinkedHashMap<>();
        Map<String, String> dataTypes = new LinkedHashMap<>();
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "select policy_cd, default_value_txt, data_type_cd from governance.policy_preset where policy_cd like 'GOV-FL-%' order by policy_cd");
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                defaultValues.put(resultSet.getString("policy_cd"), resultSet.getString("default_value_txt"));
                dataTypes.put(resultSet.getString("policy_cd"), resultSet.getString("data_type_cd"));
            }
        }

        assertEquals(6, defaultValues.size(), "Expected 6 seeded governance presets");
        assertEquals(EXPECTED_POLICY_DEFAULTS, defaultValues, "Unexpected governance preset defaults");
        assertEquals(EXPECTED_POLICY_TYPES, dataTypes, "Unexpected governance preset data types");
    }

    @Test
    void postgresClickhouseAndNeo4jConnectionsSeeded() throws SQLException {
        Assumptions.assumeTrue(isDockerRunning(), "Docker daemon must be running to execute database integration tests");
        Map<String, ConnectionSeedExpectation> actualConnections = new LinkedHashMap<>();
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "select connection_cd, engine_cd, connection_type_cd, is_default_flg from meta.data_connection order by connection_cd");
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                actualConnections.put(
                        resultSet.getString("connection_cd"),
                        new ConnectionSeedExpectation(
                                resultSet.getString("engine_cd"),
                                resultSet.getString("connection_type_cd"),
                                resultSet.getBoolean("is_default_flg"))
                );
            }
        }

        assertEquals(EXPECTED_CONNECTIONS, actualConnections, "Unexpected seeded connection registry rows");
    }

    private static void startPostgres16Container() throws Exception {
        CommandResult result = runCommand(List.of(
                "docker",
                "run",
                "--rm",
                "-d",
                "--name",
                containerName,
                "-e",
                "POSTGRES_DB=" + DATABASE_NAME,
                "-e",
                "POSTGRES_USER=" + USERNAME,
                "-e",
                "POSTGRES_PASSWORD=" + PASSWORD,
                "-P",
                "postgres:16"
        ), Duration.ofMinutes(5), true);
        assertEquals(0, result.exitCode(), "Failed to start PostgreSQL 16 container: " + result.output());

        CommandResult portResult = runCommand(
                List.of("docker", "port", containerName, "5432/tcp"),
                Duration.ofSeconds(30),
                true
        );
        assertEquals(0, portResult.exitCode(), "Failed to resolve PostgreSQL port: " + portResult.output());
        jdbcUrl = "jdbc:postgresql://127.0.0.1:" + extractPort(portResult.output()) + "/" + DATABASE_NAME;
    }

    private static void waitForDatabase() throws Exception {
        Instant deadline = Instant.now().plus(Duration.ofSeconds(60));
        SQLException lastFailure = null;
        while (Instant.now().isBefore(deadline)) {
            try (Connection ignored = openConnection()) {
                return;
            } catch (SQLException exception) {
                lastFailure = exception;
                Thread.sleep(1_000L);
            }
        }
        throw new IllegalStateException("PostgreSQL 16 container never became ready", lastFailure);
    }

    private static void runFlywayCleanAndMigrate() {
        FlywayOperations flyway = new PostgresFlywayAdapter(new PostgresDatabaseAdapter()) {
            @Override
            public FlywayOperations create(MigrationTarget target) {
                PostgresDatabaseAdapter dbAdapter = new PostgresDatabaseAdapter();
                com.lextr.migrationplatform.adapter.FlywayTargetConfiguration targetConfiguration = dbAdapter.getFlywayTargetConfiguration(target);
                org.flywaydb.core.api.configuration.FluentConfiguration configuration = org.flywaydb.core.Flyway.configure()
                        .dataSource(targetConfiguration.url(), targetConfiguration.username(), targetConfiguration.password())
                        .baselineOnMigrate(targetConfiguration.baselineOnMigrate())
                        .cleanDisabled(targetConfiguration.cleanDisabled())
                        .locations(targetConfiguration.locations().toArray(String[]::new))
                        .target("1");

                if (targetConfiguration.baselineVersion() != null && !targetConfiguration.baselineVersion().isBlank()) {
                    configuration.baselineVersion(org.flywaydb.core.api.MigrationVersion.fromVersion(targetConfiguration.baselineVersion()));
                }

                if (targetConfiguration.driverClassName() != null && !targetConfiguration.driverClassName().isBlank()) {
                    configuration.driver(targetConfiguration.driverClassName());
                }
                if (!targetConfiguration.schemas().isEmpty()) {
                    configuration.schemas(targetConfiguration.schemas().toArray(String[]::new));
                }
                if (targetConfiguration.historyTable() != null && !targetConfiguration.historyTable().isBlank()) {
                    configuration.table(targetConfiguration.historyTable());
                }
                if (!targetConfiguration.placeholders().isEmpty()) {
                    configuration.placeholders(targetConfiguration.placeholders());
                }

                return new com.lextr.migrationplatform.adapter.FlywayClient(configuration.load());
            }
        }.create(new MigrationTarget(
                "test",
                "semantic-service",
                "postgres16-baseline",
                "postgres",
                jdbcUrl,
                USERNAME,
                PASSWORD,
                "org.postgresql.Driver",
                List.of("classpath:migrations/semantic-service/postgres"),
                MANAGED_SCHEMAS,
                true,
                "0",
                false,
                HISTORY_TABLE,
                Map.of()
        ));
        flyway.clean();
        flyway.migrate();
    }

    private static void loadMigrationSql() throws IOException {
        try (InputStream inputStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(MIGRATION_PATH)) {
            if (inputStream == null) {
                fail("Migration file not found on classpath: " + MIGRATION_PATH);
            }
            migrationSql = new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private static Connection openConnection() throws SQLException {
        return DriverManager.getConnection(jdbcUrl, USERNAME, PASSWORD);
    }

    private static Set<String> querySingleColumnSet(String sql, String columnLabel) throws SQLException {
        Set<String> values = new LinkedHashSet<>();
        try (Connection connection = openConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                values.add(resultSet.getString(columnLabel));
            }
        }
        return values;
    }

    private static Set<String> difference(Set<String> expected, Set<String> actual) {
        Set<String> difference = new LinkedHashSet<>(expected);
        difference.removeAll(actual);
        return difference;
    }

    private static int extractPort(String dockerPortOutput) {
        Matcher matcher = PORT_PATTERN.matcher(dockerPortOutput.trim());
        if (!matcher.find()) {
            fail("Unable to parse mapped PostgreSQL port from: " + dockerPortOutput);
        }
        return Integer.parseInt(matcher.group(1));
    }

    private static CommandResult runCommand(List<String> command, Duration timeout, boolean failOnNonZero)
            throws IOException, InterruptedException {
        Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
        boolean completed = process.waitFor(timeout.toMillis(), TimeUnit.MILLISECONDS);
        if (!completed) {
            process.destroyForcibly();
            fail("Command timed out: " + String.join(" ", command));
        }
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
        CommandResult result = new CommandResult(process.exitValue(), output);
        if (failOnNonZero && result.exitCode() != 0) {
            fail("Command failed: " + String.join(" ", command) + System.lineSeparator() + output);
        }
        return result;
    }

    private record ConnectionSeedExpectation(String engineCode, String connectionTypeCode, boolean defaultFlag) {
    }

    private record CommandResult(int exitCode, String output) {
    }
}
