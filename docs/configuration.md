# Configuration

The default config file is `classpath:migration-platform.yml`.

## Example

```yaml
defaultEnvironment: dev
targets:
  postgres-main-dev:
    type: postgres
    environment: dev
    url: jdbc:postgresql://localhost:5432/app_db
    username: app_user
    passwordEnv: DEV_POSTGRES_PASSWORD
    schema: public
    historyTablePrefix: flyway_history

  clickhouse-analytics-dev:
    type: clickhouse
    environment: dev
    url: jdbc:clickhouse://localhost:8123/analytics
    username: default
    passwordEnv: DEV_CLICKHOUSE_PASSWORD

services:
  generic-service:
    targetMappings:
      - target: postgres-main-dev
        locations:
          - classpath:migrations/generic-service/postgres
      - target: clickhouse-analytics-dev
        locations:
          - classpath:migrations/generic-service/clickhouse
```

## Model

- database configuration exists once under `targets`
- services reference targets under `services.<service>.targetMappings`
- service-to-target mappings may override schemas, placeholders, and history table name
- multiple services may reference the same target database

## Secrets

- do not hardcode credentials in the config file
- use `passwordEnv` to resolve secrets from environment variables
- the current design keeps secret resolution separate from inventory so Vault or another secret manager can be added later

## Flyway history isolation

- by default the platform derives one Flyway history table per service, for example `flyway_history_customer_service`
- this is the default isolation strategy for shared databases
- a service mapping can override the history table explicitly when needed

## Migration path from the old model

Old shape:

```yaml
environments:
  dev:
    services:
      generic-service:
        postgres:
          ...
```

New shape:

1. move each physical database definition into `targets`
2. give each target a stable name such as `postgres-main-dev`
3. replace service-owned database blocks with `services.<service>.targetMappings[]`
4. point each service mapping at the shared target name

## Platform settings

- `migration.platform.config-location`
- `migration.platform.audit-directory`
- `migration.platform.allow-production-rebuild`
- `migration.platform.default-requested-by`

`application.yml` stays small on purpose. Database engines, targets, service mappings, schemas, and migration locations belong in `migration-platform.yml`, not in Spring datasource properties.
