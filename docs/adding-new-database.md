# Adding A New Database

Add a new database engine by extending the isolated integration layer.

## Overview

Adding a new database should not require changes to the core orchestration flow. The work should stay isolated to:

- `adapter/` for JDBC and Flyway integration
- `strategy/` for database-specific behavior and SQL validation
- `factory/` only if the new implementation is not already discovered by Spring
- `pom.xml` for Flyway/JDBC dependencies
- `database-migration-platform.yml` for new target definitions
- `tests/` for adapter, strategy, validation, and execution coverage

`application.yml` usually does not need any database-specific change. It only points the platform at `database-migration-platform.yml` and sets platform-level properties such as audit directory and rebuild policy.

## Implementation steps

1. Add the required dependencies in `pom.xml`.
   Add the Flyway database module for the engine if Flyway provides one.
   Add the JDBC driver required by the target database.

2. Create a database adapter in `src/main/java/com/lextr/migrationplatform/adapter/`.
   Typical pattern:
   - `OracleDatabaseAdapter`
   - extend `AbstractJdbcDatabaseAdapter` when JDBC behavior matches the current adapters
   - return the database name exactly as it will appear in `database-migration-platform.yml`, for example `oracle`

3. Create a Flyway adapter in `src/main/java/com/lextr/migrationplatform/adapter/`.
   Typical pattern:
   - `OracleFlywayAdapter`
   - extend `AbstractFlywayAdapter`
   - build `FlywayOperations` from the resolved `MigrationTarget`

4. Add a database strategy in `src/main/java/com/lextr/migrationplatform/strategy/`.
   Typical pattern:
   - `OracleMigrationStrategy`
   - implement database-specific warnings, capabilities, and migration-location behavior if needed

5. Add SQL validation support.
   At minimum, the engine must work with:
   - `CommonSqlValidationStrategy`
   - `DefaultRiskDetectionStrategy`

   Add a dedicated validator only when the database has SQL syntax or operational risks that differ materially from PostgreSQL and ClickHouse.
   Typical pattern:
   - `OracleSqlValidationStrategy`

6. Register the new components.
   If the new adapter and strategy classes are annotated as Spring components and implement the existing interfaces, the current factories should pick them up automatically.
   Check these factories:
   - `DatabaseAdapterFactory`
   - `FlywayAdapterFactory`
   - `DatabaseStrategyFactory`
   - `ValidationStrategyFactory`

   Only modify a factory if the new class is not already discoverable through the existing constructor-injected lists.

7. Define target databases in `database-migration-platform.yml`.
   Example:

   ```yaml
   targets:
     oracle-main-prod:
       type: oracle
       environment: prod
       url: jdbc:oracle:thin:@//oracle-prod:1521/APPDB
       username: app_user
       passwordEnv: ORACLE_MAIN_PROD_PASSWORD
       schemas:
         - APP_SCHEMA
       baselineOnMigrate: true
       cleanDisabled: true
       historyTablePrefix: flyway_history
   ```

8. Map services to the new target.
   Example:

   ```yaml
   services:
     <service-name>:
       targetMappings:
         - target: oracle-main-prod
           locations:
             - classpath:migrations/<service-name>/oracle
   ```

9. Add migration directories for the new engine.
   Example:

   ```text
   src/main/resources/migrations/<service-name>/oracle/
   ```

   Use standard Flyway naming:
   - `V001__create_entity.sql`
   - `R__refresh_reporting_view.sql`
   - `B001__baseline.sql`

10. Add and update tests.
    Add tests for:
    - database adapter config generation
    - Flyway adapter selection
    - database strategy selection
    - validation strategy behavior
    - inventory loading for the new `type`
    - plan and execution flow with a target using the new engine

11. Update documentation.
    At minimum update:
    - `docs/architecture.md`
    - `docs/adding-new-database.md`
    - `docs/configuration.md`

## Required contracts

- `DatabaseAdapter`
   - `getDatabaseName()`
   - `validateConnection(...)`
   - `getFlywayTargetConfiguration(...)`
   - `supportsTransactions()`
   - `supportsClean()`
   - `getDialectName()`
- `FlywayAdapter`
   - `getDatabaseName()`
   - `create(...)`
- `DatabaseStrategy`
   - `getDatabaseName()`
   - `databaseWarnings(...)`

## Files that usually change

- `pom.xml`
- `src/main/java/com/lextr/migrationplatform/adapter/...`
- `src/main/java/com/lextr/migrationplatform/strategy/...`
- `src/main/resources/database-migration-platform.yml`
- `src/main/resources/migrations/<service>/<database>/...`
- `src/test/java/com/lextr/migrationplatform/...`
- `docs/...`

## Files that usually do not change

- `src/main/resources/application.yml`
- controller layer
- orchestration layer
- audit persistence flow
- CLI command structure
- REST endpoint structure

In the shared-database model, new engines are introduced only as new target types. Services continue to reference target names rather than owning database configuration directly.

## Oracle example checklist

If Oracle is added later, the expected minimal change set is:

1. Add Oracle Flyway and JDBC dependencies to `pom.xml`.
2. Add `OracleDatabaseAdapter`.
3. Add `OracleFlywayAdapter`.
4. Add `OracleMigrationStrategy`.
5. Add `OracleSqlValidationStrategy` only if the common validator is not sufficient.
6. Add `oracle` targets in `database-migration-platform.yml`.
7. Add `migrations/<service>/oracle/` folders.
8. Add adapter, validation, and execution tests.

No controller, orchestrator, or audit redesign should be required.

## Reusable implementation prompt

Use the following prompt when asking for support for a new database engine:

```text
Add support for <DATABASE_NAME> to this Flyway-based migration platform.

Constraints:
- Do not reimplement Flyway.
- Do not change existing migration business behavior.
- Keep PostgreSQL and ClickHouse support working.
- Keep the shared target database model intact.
- Do not add service-owned database configs.
- Keep core orchestration database-agnostic.

Required changes:
- Add the required Flyway module and JDBC driver in pom.xml.
- Add a database adapter: <DatabaseName>DatabaseAdapter.
- Add a Flyway adapter: <DatabaseName>FlywayAdapter.
- Add a database strategy: <DatabaseName>MigrationStrategy.
- Add a database-specific SQL validation strategy only if needed.
- Ensure the existing factories can resolve the new implementations.
- Support target definitions in database-migration-platform.yml using type: <database_type>.
- Support service targetMappings pointing to the new target.
- Add sample migration folder layout under src/main/resources/migrations/<service>/<database_type>/.
- Add tests for adapter selection, config generation, validation, planning, and execution flow.
- Update docs/adding-new-database.md, docs/architecture.md, and docs/configuration.md.

Do not change:
- controller endpoints
- CLI command structure
- audit model
- shared database history isolation design unless the new engine requires a documented Flyway-safe variation

Deliverables:
1. Summary of required design changes.
2. Files changed.
3. New target config example.
4. New service mapping example.
5. Test results.
6. Any engine-specific limitations.
```

Replace:
- `<DATABASE_NAME>` with the human-readable name, for example `Oracle`
- `<DatabaseName>` with the class prefix, for example `Oracle`
- `<database_type>` with the config key, for example `oracle`
- `<service-name>` with the service folder name that owns the migrations
