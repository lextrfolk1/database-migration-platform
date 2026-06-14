# Adding A New Database

Add a new database engine by extending the isolated integration layer.

## Steps

1. Add the Flyway database module and JDBC driver to `pom.xml`.
2. Create a `DatabaseIntegration` implementation under `integrations/databases/<engine>/`.
3. Implement:
   - `getDatabaseName()`
   - `validateConnection(...)`
   - `getFlywayConfig(...)`
   - `supportsTransactions()`
   - `supportsClean()`
   - `getDialectName()`
4. Add engine-specific validation if needed.
5. Reference the new engine in `migration-platform.yml`.

The orchestration, API, CLI, planning, and audit layers do not need database-specific changes when the new integration is registered as a Spring bean.
