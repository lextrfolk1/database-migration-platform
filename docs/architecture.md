# Architecture

The platform keeps Flyway as the migration engine and wraps it in a layered, DBA-operated migration application.

## Layers

- `controller`: REST controllers and centralized exception handling.
- `cli`: CLI command entry point.
- `service` and `service/impl`: application workflows for inventory, validation, planning, execution, and history.
- `dao` and `dao/impl`: audit persistence and inventory metadata access.
- `repository`: low-level file and configuration repositories.
- `model`: internal domain models and enums.
- `dto`: API request and response objects.
- `entity`: persistence entities for audit records.
- `mapper`: DTO/entity/domain mapping.
- `adapter`: Flyway and database integration boundaries.
- `strategy`: execution-scope, migration-mode, validation, risk, and database-specific variation points.
- `factory`: strategy and adapter selection.
- `orchestration`: end-to-end coordination facade.
- `config`: externalized platform configuration.
- `validation` and `util`: filename parsing, SQL risk scanning, and resource discovery.
- `exception`: typed platform exceptions.

## Package structure

```text
src/main/java/com/lextr/migrationplatform
  controller/
  cli/
  service/
  service/impl/
  dao/
  dao/impl/
  repository/
  model/
  dto/
  entity/
  mapper/
  config/
  strategy/
  adapter/
  factory/
  orchestration/
  validation/
  exception/
  util/
```

## Resource layout

- new sample database-specific migrations live under `src/main/resources/migrations/...`
- external inventory is loaded from `classpath:database-migration-platform.yml` by default or an alternate path via `migration.platform.config-location`

## Core concepts

- Target Database: a physical PostgreSQL or ClickHouse database endpoint identified once in config.
- Service: a logical owner of migration scripts.
- Migration Location: the Flyway location set for one service on one target database.
- Shared Database: one target database may be referenced by many services.
- Flyway History Isolation: each service gets a dedicated Flyway history table on a shared target database by default.

## Shared database relationship

```text
postgres-main-prod
  |
  +---- generic-service migrations
  +---- order-service migrations
```

The execution unit is:

```text
service + target database + migration location(s)
```

Database ownership and service ownership are independent.

## Flyway history isolation strategy

The platform uses Option A by default: one Flyway history table per service on each target database.

Examples:

- `flyway_history_customer_service`
- `flyway_history_billing_service`

Rationale:

- services can reuse `V001`, `V002`, and repeatable names on the same physical database without interfering
- Flyway state stays isolated without requiring separate schemas
- the strategy works for both shared-database and service-dedicated deployments
- a service mapping can still override the table name explicitly when needed

## Design patterns

- Strategy pattern for database behavior, execution scope, migration mode, validation, and risk handling.
- Adapter pattern for Flyway and JDBC/database connectivity.
- Factory pattern for selecting adapters and strategies.
- DAO/repository pattern for audit persistence and configuration-backed inventory access.

## Execution flow

1. Controller or CLI receives a request.
2. `MigrationRequestMapper` converts API or CLI input into `MigrationRequest`.
3. `MigrationPlatformOrchestrator` resolves service-to-target mappings through the scope strategies.
4. `MigrationInventoryService` builds the execution unit from `service + target database + migration locations + history table`.
5. `MigrationValidationService` applies common and database-specific validation.
6. `MigrationPlanService` queries Flyway metadata through the selected `FlywayAdapter`.
7. `MigrationExecutionService` runs the selected migration mode and handles stop-on-failure or continue-on-error behavior.
8. `AuditService` persists platform execution history.

## Database support

### PostgreSQL

- uses the PostgreSQL Flyway module
- supports delta migration through `migrate`
- supports rebuild through `clean` then `migrate`
- supports repair through `repair`
- emits warnings for risky locking operations

### ClickHouse

- uses the ClickHouse Flyway module and ClickHouse JDBC driver
- supports validation, planning, delta migration, repair, and audit
- warns that DDL is non-transactional and rollback may be manual
- keeps rebuild blocked by default because `clean` semantics are intentionally treated as unsafe

## Rebuild policy

- non-production rebuild: `clean` then `migrate`
- production rebuild: blocked unless `migration.platform.allow-production-rebuild=true`
- all rebuilds require explicit confirmation

## Compatibility notes

- Flyway schema history remains the source of truth for migration state
- old `--db` CLI usage is retained as a compatibility fallback when it resolves unambiguously to one target database
