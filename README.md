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

The repo includes a `migration` wrapper script. It runs the packaged jar when available and falls back to `spring-boot:run` during development.

Representative commands:

```bash
./migration inventory
./migration targets list
./migration targets show postgres-main-dev
./migration services list
./migration services show semantic-service
./migration validate --service semantic-service --target postgres-main-dev --env dev
./migration plan --service semantic-service --target postgres-main-dev --env dev
./migration run --service semantic-service --target postgres-main-dev --env dev --mode delta
./migration run --all-services --target postgres-main-dev --env dev --mode delta
./migration repair --service semantic-service --target postgres-main-dev --env dev
./migration history
```

Important flags:

- `--service`
- `--target`
- `--db`
- `--env`
- `--all-services`
- `--all-targets`
- `--mode delta`
- `--continue-on-error`
- `--allow-risky`
- `--confirm`
- `--requested-by`

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
