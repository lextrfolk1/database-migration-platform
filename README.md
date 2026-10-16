# Database Migration Platform

`database-migration-platform` is a Spring Boot application that wraps Flyway in a DBA-operated execution layer for shared service databases.

It is responsible for:

- inventorying target databases and service-to-target mappings
- validating migration sets before execution
- planning pending migrations
- running delta migrations
- rebuilding non-production databases when explicitly confirmed
- repairing Flyway history
- recording execution audit history

This README documents only the `database-migration-platform` repository.

## Stack

- Java 21
- Spring Boot 3.4.4
- Flyway 10.18.0
- PostgreSQL JDBC
- ClickHouse JDBC
- Spring Web
- Spring Validation

## Repository layout

```text
src/main/java/com/lextr/migrationplatform
  adapter/
  cli/
  config/
  controller/
  dao/
  dto/
  entity/
  exception/
  factory/
  mapper/
  model/
  orchestration/
  repository/
  service/
  service/impl/
  strategy/
  util/
  validation/
```

Key resource locations:

```text
src/main/resources/
  application.yml
  database-migration-platform.yml
  migrations/
    generic-service/
      postgres/
      clickhouse/
    semantic-service/
      postgres/
```

Supporting docs:

- [docs/architecture.md](docs/architecture.md)
- [docs/usage.md](docs/usage.md)

## Core architecture

The application keeps Flyway as the migration engine and layers operational concerns around it:

- `controller`: REST endpoints and exception handling
- `cli`: command-line entry point
- `service` / `service.impl`: validation, planning, execution, history, and audit workflows
- `dao` and `repository`: inventory and audit persistence access
- `adapter`: Flyway and database integration
- `strategy`: execution-scope, migration-mode, validation, and database-specific behavior
- `factory`: adapter and strategy selection
- `orchestration`: end-to-end coordination facade

Database-specific behavior is isolated behind:

- `PostgresDatabaseAdapter`
- `ClickHouseDatabaseAdapter`
- `PostgresFlywayAdapter`
- `ClickHouseFlywayAdapter`

Execution behavior is isolated behind strategies such as:

- `SingleServiceExecutionStrategy`
- `AllServicesExecutionStrategy`
- `AllDatabasesExecutionStrategy`
- `DeltaMigrationStrategy`
- `FreshRebuildStrategy`
- `PostgresSqlValidationStrategy`
- `ClickHouseSqlValidationStrategy`

## Runtime configuration

Application defaults live in:

- `src/main/resources/application.yml`
- `src/main/resources/database-migration-platform.yml`

Current defaults:

- HTTP port: `8049`
- config source: `classpath:database-migration-platform.yml` (`migration.platform.config-location`)
- migrations root: `src/main/resources/migrations` (`migration.platform.migrations-root`)
- audit directory: `build/audit` (`migration.platform.audit-directory`)
- production rebuild: disabled by default

All three locations can be overridden without rebuilding — see [Run modes](#run-modes) and [Externalizing config and SQL](#externalizing-config-and-sql).

## Current inventory

Configured target databases:

- `postgres-main-dev`
  - type: `postgres`
  - environment: `dev`
  - schemas: `meta`, `data`
- `clickhouse-analytics-dev`
  - type: `clickhouse`
  - environment: `dev`

Configured services (locations are relative to the migrations root):

- `database-scripts`
  - `database-scripts/postgres` (`baselineOnMigrate: false`, so V0 is never skipped)
  - `database-scripts/clickhouse`
- `semantic-service`
  - `semantic-service/postgres`
- `intelligence-service`
  - `intelligence-service/postgres`
- `workflow-service`
  - `workflow-service/postgres`
- `lexie-ai` (VarianceAI + Variance Knowledge Hub: `variance`, `audit` schemas)
  - `lexie-ai/postgres`

The ClickHouse URL carries `?clickhouse.jdbc.v1=true`: the v2 driver in `clickhouse-jdbc 0.9.x` cannot parse Flyway's parameterized history-table queries.

## Flyway history isolation

The platform isolates Flyway history by service on shared target databases by default.

Examples:

- `flyway_history_generic_service`
- `flyway_history_semantic_service`

This allows multiple services to share one physical database without colliding on version numbers or repeatable migration names.

## REST API

Main endpoints:

- `GET /health`
- `GET /inventory`
- `GET /targets`
- `GET /targets/{target}`
- `GET /services`
- `GET /services/{service}`
- `GET /services/{service}/databases`
- `POST /migrations/validate`
- `POST /migrations/plan`
- `POST /migrations/run`
- `POST /migrations/rebuild`
- `POST /migrations/repair`
- `GET /migrations/history`
- `GET /migrations/status/{execution_id}`

Example run request:

```json
{
  "scope": "service",
  "service": "semantic-service",
  "target": "postgres-main-dev",
  "environment": "dev",
  "mode": "delta",
  "continueOnError": false,
  "allowRisky": false,
  "requestedBy": "dba-operator"
}
```

## CLI

The repo includes wrapper scripts at the project root. They run in **local mode** from a source checkout and in **deployed mode** from an unzipped bundle — see [Run modes](#run-modes).

| OS | CLI Script | Start Server | Stop Server |
|---|---|---|---|
| Linux / macOS | `./migration` | `./scripts/start.sh` | `./scripts/stop.sh` |
| Windows | `migration.cmd` | `scripts\start.cmd` | `scripts\stop.cmd` |

When a recognized CLI command is the first argument, the application boots **without a web server**, executes the command, prints JSON to stdout, and exits. Without a recognized command, it starts the full web server on port `8049`.

### Commands

#### `inventory`

List all resolved migration targets (every service × target database combination).

```bash
./migration inventory
```

---

#### `targets`

Manage and inspect configured target databases.

```bash
# List all target databases
./migration targets list
./migration targets              # "list" is the default

# Show details for a specific target
./migration targets show postgres-main-dev
./migration targets show clickhouse-analytics-dev
```

---

#### `services`

Manage and inspect registered services.

```bash
# List all registered service names
./migration services list
./migration services              # "list" is the default

# Show which targets a service maps to
./migration services show generic-service
./migration services show semantic-service
```

---

#### `validate`

Validate SQL migration files and verify database connectivity for a service. Returns the migration plan with any validation issues.

```bash
# Validate a single service against a specific target
./migration validate --service semantic-service --target postgres-main-dev --env dev

# Validate a service against a specific database type
./migration validate --service generic-service --db postgres --env dev

# Validate all services across all targets
./migration validate --all-services --all-targets --env dev
```

---

#### `plan`

Show what migrations would run without executing anything (dry run). Returns pending versioned migrations and repeatable migrations to re-run.

```bash
# Plan for a single service/target
./migration plan --service semantic-service --target postgres-main-dev --env dev

# Plan for a service against a specific database type
./migration plan --service generic-service --db postgres --env dev

# Plan for all services across all targets
./migration plan --all-services --all-targets --env dev
```

---

#### `run`

Execute pending migrations in **delta** mode (apply only new migrations).

```bash
# Run migrations for a single service/target
./migration run --service semantic-service --target postgres-main-dev --env dev

# Run for a service against a specific database type
./migration run --service generic-service --db postgres --env dev

# Run for all services across all targets
./migration run --all-services --all-targets --env dev

# Run for all services on a specific target
./migration run --all-services --target postgres-main-dev --env dev

# Continue executing remaining targets even if one fails
./migration run --all-services --all-targets --env dev --continue-on-error

# Allow risky SQL (DROP, TRUNCATE, etc.)
./migration run --service generic-service --target postgres-main-dev --allow-risky

# Specify who requested the migration (recorded in audit trail)
./migration run --service semantic-service --target postgres-main-dev --requested-by john.doe

# Confirm execution (required for certain operations)
./migration run --service semantic-service --target postgres-main-dev --confirm
```

---

#### `rebuild`

Drop and rebuild the database from scratch using all migrations (**rebuild** mode). Calls Flyway `clean()` before `migrate()`.

```bash
# Rebuild a specific service/target
./migration rebuild --service generic-service --target postgres-main-dev --confirm

# Rebuild with risky SQL allowed
./migration rebuild --service generic-service --target postgres-main-dev --allow-risky --confirm
```

> **Warning:** `rebuild` is disabled for production environments by default (`allow-production-rebuild: false`).

---

#### `repair`

Repair the Flyway history table by removing failed migration entries and realigning checksums.

```bash
# Repair a single service/target
./migration repair --service semantic-service --target postgres-main-dev --env dev

# Repair a service against a specific database type
./migration repair --service generic-service --db postgres --env dev
```

---

#### `history`

Show the audit history of all past migration executions.

```bash
./migration history
```

---

### Fresh Execution Workflows

Step-by-step command sequences for common scenarios.

#### First-time setup (fresh database, no history)

```bash
# 1. Start local databases
docker compose up -d postgres clickhouse

# 2. Check what targets and services are configured
./migration targets list
./migration services list

# 3. Inspect what a specific service maps to
./migration services show generic-service

# 4. Validate connectivity and SQL files before touching anything
./migration validate --service generic-service --db postgres --env dev

# 5. Preview the migration plan (dry run)
./migration plan --service generic-service --db postgres --env dev

# 6. Execute all pending migrations for one service
./migration run --service generic-service --db postgres --env dev

# 7. Do the same for the other service
./migration run --service semantic-service --target postgres-main-dev --env dev

# 8. Verify with history
./migration history
```

#### Running all services at once (fresh or delta)

```bash
# Validate everything first
./migration validate --all-services --all-targets --env dev

# Dry-run plan across all services
./migration plan --all-services --all-targets --env dev

# Execute all pending migrations for every service
./migration run --all-services --all-targets --env dev

# If you want execution to continue past failures
./migration run --all-services --all-targets --env dev --continue-on-error
```

#### Full database rebuild (wipe and re-create from scratch)

```bash
# Preview what will happen
./migration plan --service generic-service --target postgres-main-dev --env dev

# Rebuild: drops all objects, then re-runs every migration from V1
# Requires --confirm (and clean must be enabled on the target)
./migration rebuild --service generic-service --target postgres-main-dev --confirm

# Rebuild with risky DDL allowed
./migration rebuild --service generic-service --target postgres-main-dev --allow-risky --confirm

# Rebuild a service against a specific database type
./migration rebuild --service generic-service --db postgres --confirm
```

> **Note:** `rebuild` calls Flyway `clean()` → `migrate()`. It is **blocked** on production by default. To enable, set `allow-production-rebuild: true` in `application.yml`.

#### Recovering from a failed migration

```bash
# 1. Check what happened
./migration history

# 2. Repair the Flyway history table (removes failed entries, realigns checksums)
./migration repair --service semantic-service --target postgres-main-dev --env dev

# 3. Fix the SQL file, then re-run
./migration run --service semantic-service --target postgres-main-dev --env dev

# 4. If the SQL contains risky statements (e.g., you're fixing a DROP)
./migration run --service semantic-service --target postgres-main-dev --env dev --allow-risky
```

#### Targeted execution by database type

```bash
# Run only postgres targets for a service
./migration run --service generic-service --db postgres --env dev

# Run only clickhouse targets for a service
./migration run --service generic-service --db clickhouse --env dev
```

#### Audited execution with requester tracking

```bash
# Record who initiated the migration
./migration run --service semantic-service --target postgres-main-dev \
  --env dev --requested-by lextrfolk1.patel --confirm
```

---

### Global Options

All action commands (`validate`, `plan`, `run`, `rebuild`, `repair`) accept the following options:

| Option | Description | Default |
|---|---|---|
| `--service <name>` | Target a specific service | *(required unless `--all-services`)* |
| `--target <name>` | Target a specific database | *(optional — defaults to all mapped targets)* |
| `--db <type>` | Filter by database type (`postgres` or `clickhouse`) | *(none — all types)* |
| `--env <environment>` | Target environment (`dev`, `staging`, `prod`) | `dev` |
| `--mode <mode>` | Migration mode (`delta` or `rebuild`) | `delta` |
| `--all-services` | Run across all registered services | *(flag)* |
| `--all-targets` | Run across all targets mapped to the selected service(s) | *(flag)* |
| `--all-databases` | Alias for `--all-targets` | *(flag)* |
| `--continue-on-error` | Don't stop on first target failure; continue to remaining targets | *(flag — off by default)* |
| `--allow-risky` | Allow risky SQL statements (DROP, TRUNCATE, etc.) | *(flag — off by default)* |
| `--confirm` | Confirm execution | *(flag)* |
| `--requested-by <name>` | Who requested the migration (for audit trail) | `dba-operator` |

### Output

- **Success:** JSON result printed to **stdout**, exit code `0`.
- **Failure:** Error message printed to **stderr**, exit code `1`.

All commands return structured JSON. Example output from `./migration plan`:

```json
{
  "targets": [
    {
      "service": "semantic-service",
      "targetName": "postgres-main-dev",
      "databaseType": "postgres",
      "environment": "dev",
      "pendingVersionedMigrations": ["V2__add_embeddings_table.sql"],
      "repeatableMigrationsToRerun": [],
      "validationIssues": []
    }
  ]
}
```

## Run modes

The `migration` / `migration.cmd` launcher picks its mode automatically.

| | Local mode | Deployed mode |
|---|---|---|
| When | `pom.xml` is next to the script (source checkout) | no `pom.xml` (unzipped bundle) |
| What runs | `target/classes` — no jar is built | `database-migration-platform.jar` |
| Code / config changes | compiled automatically on the next run | rebuild and redeploy the bundle |
| SQL changes | picked up immediately (read from disk, no compile) | picked up immediately from the bundle's `migrations/` or an external folder |
| Default config | `src/main/resources/database-migration-platform.yml` | `<bundle>/config/database-migration-platform.yml` |
| Default migrations root | `src/main/resources/migrations` | `<bundle>/migrations` |
| Default audit folder | `build/audit` | `<bundle>/audit` |

### Local mode

```bash
./migration plan --service semantic-service --target postgres-main-dev --env dev
```

- The launcher compiles only when something under `src/main` (except `migrations/`) or `pom.xml` is newer than the last compile, then runs `java -cp target/classes:<runtime dependencies>`.
- The dependency classpath is cached in `target/classpath.txt` and regenerated when `pom.xml` or the launcher changes. `./mvnw clean` resets everything.

### Deployed mode

`./mvnw package` produces `target/database-migration-platform-<version>-bundle.zip`:

```text
database-migration-platform/
  database-migration-platform.jar     # contains no SQL
  migration                           # launcher (macOS/Linux)
  migration.cmd                       # launcher (Windows)
  config/database-migration-platform.yml
  migrations/<service>/<db>/V*.sql
```

Deploy it with:

```bash
unzip database-migration-platform-<version>-bundle.zip -d /opt
cp qa-database-migration-platform.yml /opt/database-migration-platform/config/database-migration-platform.yml
export LEXTR_POSTGRES_PASSWORD=...  LEXTR_CLICKHOUSE_PASSWORD=...
/opt/database-migration-platform/migration plan --all-services --all-targets --env qa
```

### Overrides (both modes)

| Variable | Purpose | Example |
|---|---|---|
| `DMP_CONFIG_LOCATION` | platform config | `file:/etc/dmp/qa.yml` |
| `DMP_MIGRATIONS_ROOT` | root folder for relative migration locations | `/opt/lextr-migrations/1.4.0` |
| `DMP_AUDIT_DIR` | audit output folder | `/var/log/dmp/audit` |

Relative values are resolved from the directory you run the command in. `scripts/start.sh` / `start.cmd` accept the same variables for the API server.

## Externalizing config and SQL

Nothing in the platform requires the SQL or the config to live in this repository.

### Config

Keep one config file per environment outside the jar and point `DMP_CONFIG_LOCATION` at it (or drop it into the bundle's `config/` folder). Secrets stay in environment variables via `passwordEnv`.

### SQL from outside this project

1. **Lay out the external SQL** as `<root>/<service>/<db>/V<n>__<description>.sql`, matching the relative locations in the config:

   ```text
   /opt/lextr-migrations/1.4.0/
     database-scripts/postgres/V0__schema_creation.sql
     semantic-service/postgres/V1__semantic_layer_baseline.sql
     ...
   ```

2. **Point the platform at it:**

   ```bash
   DMP_MIGRATIONS_ROOT=/opt/lextr-migrations/1.4.0 ./migration plan --all-services --all-targets --env qa
   ```

   Alternatively, a single service can use an absolute location in the config, e.g. `filesystem:/opt/semantic-service/db/postgres`, which lets each service own its SQL in its own repository.

3. **Ship SQL as a versioned artifact** (a tagged git repo or versioned zip), so it is always clear which SQL set was deployed.

4. **Never edit an applied file.** Flyway validates checksums; fixes always go into a new version.

### When the SQL is removed from this repository

| Area | Change needed |
|---|---|
| `src/assembly/bundle.xml` | remove the `migrations` `<fileSet>`; the bundle then contains only the jar, launchers and config |
| Local mode | set `DMP_MIGRATIONS_ROOT` to your local SQL checkout, or change the `migrations-root` default |
| SQL tests (`*MigrationTest`) | they read SQL from the classpath — move them with the SQL or remove them |
| `maven-jar-plugin` exclude in `pom.xml` | no longer needed (harmless if left) |

## Testing

### Unit and integration tests

```bash
./mvnw test        # mvnw.cmd test on Windows
```

`SemanticLayerBaselineMigrationTest` starts its own throwaway PostgreSQL container and is skipped when Docker is not running. No test touches a shared database.

### End-to-end: both modes against fresh Docker databases

Never run this against a shared database. Each mode gets its own PostgreSQL and ClickHouse instance so the results can be compared.

**1. Start the databases**

```bash
docker run -d --name dmp-test-pg-local -p 5544:5432 -e POSTGRES_USER=lextr_user -e POSTGRES_PASSWORD=dmp_test -e POSTGRES_DB=lextr_local pgvector/pgvector:pg16
docker run -d --name dmp-test-pg-jar   -p 5545:5432 -e POSTGRES_USER=lextr_user -e POSTGRES_PASSWORD=dmp_test -e POSTGRES_DB=lextr_jar   pgvector/pgvector:pg16
docker run -d --name dmp-test-ch-local -p 18123:8123 -e CLICKHOUSE_PASSWORD=dmp_test clickhouse/clickhouse-server:24.8
docker run -d --name dmp-test-ch-jar   -p 18124:8123 -e CLICKHOUSE_PASSWORD=dmp_test clickhouse/clickhouse-server:24.8
export LEXTR_POSTGRES_PASSWORD=dmp_test LEXTR_CLICKHOUSE_PASSWORD=dmp_test
```

The `pgvector` image is required: the migrations create the `vector`, `pgcrypto` and `pg_trgm` extensions and assign objects to `lextr_user`.

**2. Create one config per mode** (copies of the real config with only the URLs changed)

```bash
mkdir -p /tmp/dmp-e2e && cd /tmp/dmp-e2e
CFG=<repo>/src/main/resources/database-migration-platform.yml
sed -e 's#localhost:5433/lextr#localhost:5544/lextr_local#' -e 's#localhost:8123/#localhost:18123/#' $CFG > local.yml
sed -e 's#localhost:5433/lextr#localhost:5545/lextr_jar#'   -e 's#localhost:8123/#localhost:18124/#' $CFG > jar.yml
grep url: local.yml jar.yml    # confirm no shared database is referenced
```

**3. Local mode**

```bash
DMP_CONFIG_LOCATION=file:local.yml DMP_AUDIT_DIR=audit-local \
  <repo>/migration run --all-services --all-targets --env dev --allow-risky
```

**4. Deployed (jar) mode**

```bash
(cd <repo> && ./mvnw package)
unzip -q <repo>/target/*-bundle.zip -d bundle
cp jar.yml bundle/database-migration-platform/config/database-migration-platform.yml
bundle/database-migration-platform/migration run --all-services --all-targets --env dev --allow-risky
```

`--allow-risky` is needed because existing `database-scripts` files contain `DROP COLUMN` / `RENAME COLUMN`.

**5. Compare the two databases**

```bash
pg_local() { docker exec -i dmp-test-pg-local "$@" -U lextr_user -d lextr_local; }
pg_jar()   { docker exec -i dmp-test-pg-jar   "$@" -U lextr_user -d lextr_jar; }
HIST="select string_agg(t, ' union all ' order by t) from (select format('select %L, version, script, checksum, success from %I.%I', table_name, table_schema, table_name) t from information_schema.tables where table_name like 'flyway_history%') x"

# Flyway history (should be identical, no failed rows)
diff <(pg_local psql -Atc "$(pg_local psql -Atc "$HIST") order by 1,2" </dev/null) \
     <(pg_jar   psql -Atc "$(pg_jar   psql -Atc "$HIST") order by 1,2" </dev/null) && echo "history identical"

# Schema
strip() { grep -vE '^--|^$|^SET |set_config|^\\(un)?restrict '; }
diff <(pg_local pg_dump --schema-only --no-owner --no-privileges | strip) \
     <(pg_jar   pg_dump --schema-only --no-owner --no-privileges | strip) && echo "schema identical"

# ClickHouse
for p in 18123 18124; do curl -s -u default:dmp_test "http://localhost:$p/" \
  --data-binary "SELECT version, script, checksum, success FROM default.flyway_history_database_scripts FORMAT TSV"; done
```

Expected: every run returns `"status" : "SUCCESS"`, history/schema/ClickHouse are identical between modes, and every configured SQL file appears in history with `success = t`. Re-running step 3 or 4 applies nothing.

**6. Clean up**

```bash
docker rm -f dmp-test-pg-local dmp-test-pg-jar dmp-test-ch-local dmp-test-ch-jar
```

### Quick checks

| Check | Command | Expected |
|---|---|---|
| Local recompiles only when needed | run `./migration services list` twice | second run has no "Compiling…" |
| SQL edits need no compile | add a SQL file, run `./migration plan …` | no compile; file listed as pending |
| Jar has no SQL | `unzip -l target/database-migration-platform-*.jar \| grep -c '\.sql$'` | `0` |
| Missing migrations root | `DMP_MIGRATIONS_ROOT=/nope ./migration inventory` | `Migrations root does not exist` |
| Missing config | `DMP_CONFIG_LOCATION=file:/nope.yml ./migration inventory` | `Migration platform config not found` |

## Local development

### Run tests

```bash
# Linux / macOS
./mvnw test

# Windows
mvnw.cmd test
```

### Run locally with Spring Boot

```bash
# Linux / macOS
./mvnw spring-boot:run

# Windows
mvnw.cmd spring-boot:run
```

### Run with the wrapper

```bash
# Linux / macOS
./migration inventory

# Windows
migration.cmd inventory
```

### Start the API server

```bash
# Linux / macOS
./scripts/start.sh
./scripts/stop.sh

# Windows
scripts\start.cmd
scripts\stop.cmd
```

### Start local dependencies

```bash
docker compose up -d postgres clickhouse
```

### Start the full stack

```bash
docker compose up --build
```

## Container setup

- `docker-compose.yml` provisions:
  - PostgreSQL 16 on `5434`
  - ClickHouse on `8123` / `9000`
  - the migration-platform application on `8049`
- `Dockerfile` builds the application jar with Maven and runs it on Temurin 21.

## Important files

- `src/main/resources/application.yml`
- `src/main/resources/database-migration-platform.yml`
- `src/main/resources/migrations/**`
- `src/assembly/bundle.xml` — deployable bundle layout
- `docs/architecture.md`
- `docs/usage.md`
- `migration` — CLI entry point (Linux / macOS)
- `migration.cmd` — CLI entry point (Windows)
- `scripts/start.sh` / `scripts/start.cmd` — start the API server
- `scripts/stop.sh` / `scripts/stop.cmd` — stop the API server
- `docker-compose.yml`
- `Dockerfile`


## Sample commands

#### PostgreSQL
./migration run --service database-scripts --target postgres-main-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm
./migration run --service semantic-service --target postgres-main-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm
./migration run --service workflow-service --target postgres-main-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm
./migration run --service intelligence-service --target postgres-main-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm
./migration run --service lexie-ai --target postgres-main-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm

### Clickhouse
./migration run --service database-scripts --target clickhouse-analytics-dev --env dev --allow-risky --requested-by lextrfolk1 --confirm