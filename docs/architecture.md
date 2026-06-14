# Architecture

The platform keeps Flyway as the migration engine and adds orchestration around it for DBA use.

## Runtime layers

- `apps/api`: Spring MVC controllers for health, inventory, planning, execution, rebuild, repair, and history.
- `apps/cli`: command runner that exposes `inventory`, `validate`, `plan`, `run`, `history`, `rebuild`, and `repair`.
- `platform/config`: external YAML loading and platform settings.
- `platform/inventory`: service/database/environment target discovery plus migration resource lookup.
- `platform/validation`: filename checks, duplicate version detection, missing location detection, and SQL risk scanning.
- `platform/planning`: non-executing plan generation using Flyway `validate` and `info`.
- `platform/orchestration`: target selection, execution ordering, stop-on-failure, continue-on-error, rebuild safety, and repair.
- `platform/audit`: execution audit persisted outside Flyway schema history.
- `integrations/flyway`: Flyway factory and adapter.
- `integrations/databases`: isolated PostgreSQL and ClickHouse behavior.

## Resource layout

- legacy migrations remain under `src/main/resources/db/init/...`
- new sample database-specific migrations live under `src/main/resources/migrations/...`
- external inventory is loaded from `classpath:migration-platform.yml` by default or an alternate path via `migration.platform.config-location`

## Compatibility

- the legacy endpoint `/api/migration` still works
- existing Spring datasource and Flyway properties still provide a fallback inventory when no external config is defined
- Flyway schema history remains the source of truth for migration state
