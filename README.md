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
- config source: `classpath:database-migration-platform.yml`
- audit directory: `build/audit`
- production rebuild: disabled by default

## Current inventory

Configured target databases:

- `postgres-main-dev`
  - type: `postgres`
  - environment: `dev`
  - schemas: `meta`, `data`
- `clickhouse-analytics-dev`
  - type: `clickhouse`
  - environment: `dev`

Configured services:

- `generic-service`
  - `classpath:migrations/generic-service/postgres`
  - `classpath:migrations/generic-service/clickhouse`
- `semantic-service`
  - `classpath:migrations/semantic-service/postgres`

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

The repo includes a `migration` wrapper script at the project root. It runs the packaged JAR when available and falls back to `spring-boot:run` during development.

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

# Validate a service against all its mapped targets
./migration validate --service generic-service --all-targets --env dev

# Validate all services
./migration validate --all-services --env dev
```

---

#### `plan`

Show what migrations would run without executing anything (dry run). Returns pending versioned migrations and repeatable migrations to re-run.

```bash
# Plan for a single service/target
./migration plan --service semantic-service --target postgres-main-dev --env dev

# Plan for a service across all its targets
./migration plan --service generic-service --all-targets --env dev

# Plan for all services
./migration plan --all-services --env dev
```

---

#### `run`

Execute pending migrations in **delta** mode (apply only new migrations).

```bash
# Run migrations for a single service/target
./migration run --service semantic-service --target postgres-main-dev --env dev

# Run for a service across all its targets
./migration run --service generic-service --all-targets --env dev

# Run for all services
./migration run --all-services --env dev

# Continue executing remaining targets even if one fails
./migration run --all-services --env dev --continue-on-error

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

# Repair across all targets for a service
./migration repair --service generic-service --all-targets --env dev
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
./migration validate --service generic-service --all-targets --env dev

# 5. Preview the migration plan (dry run)
./migration plan --service generic-service --all-targets --env dev

# 6. Execute all pending migrations for one service
./migration run --service generic-service --all-targets --env dev

# 7. Do the same for the other service
./migration run --service semantic-service --target postgres-main-dev --env dev

# 8. Verify with history
./migration history
```

#### Running all services at once (fresh or delta)

```bash
# Validate everything first
./migration validate --all-services --env dev

# Dry-run plan across all services
./migration plan --all-services --env dev

# Execute all pending migrations for every service
./migration run --all-services --env dev

# If you want execution to continue past failures
./migration run --all-services --env dev --continue-on-error
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

# Rebuild all targets for a service
./migration rebuild --service generic-service --all-targets --confirm
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
  --env dev --requested-by tejal.patel --confirm
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

## Local development

### Run tests

```bash
./mvnw test
```

### Run locally with Spring Boot

```bash
./mvnw spring-boot:run
```

### Run with the wrapper

```bash
./migration inventory
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
- `docs/architecture.md`
- `docs/usage.md`
- `migration`
- `docker-compose.yml`
- `Dockerfile`
