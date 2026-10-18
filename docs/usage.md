# Usage

The `migration` wrapper script has two modes:

- **Local** (run from a source checkout, `pom.xml` present): compiles changed code/config and runs from `target/classes`, so the latest code, config and SQL are always used. No jar is built. SQL edits never need a compile.
- **Deployed** (run from an unzipped bundle, no `pom.xml`): runs `database-migration-platform.jar` with config and SQL taken from next to the script.

## Deploying

`./mvnw package` produces `target/database-migration-platform-<version>-bundle.zip`:

```
database-migration-platform/
  database-migration-platform.jar     # contains no SQL
  migration                           # launcher (macOS/Linux)
  migration.cmd                       # launcher (Windows)
  config/database-migration-platform.yml
  migrations/<service>/<db>/V*.sql
```

Unzip it on the target machine, replace `config/database-migration-platform.yml` with that environment's config, and run `./migration ...` (or `migration.cmd ...` on Windows).

Overrides (both modes):

| Variable | Default (deployed) | Purpose |
|---|---|---|
| `DMP_CONFIG_LOCATION` | `file:<bundle>/config/database-migration-platform.yml` | platform config |
| `DMP_MIGRATIONS_ROOT` | `<bundle>/migrations` | root for relative migration locations |
| `DMP_AUDIT_DIR` | `<bundle>/audit` | audit output |

Locally the defaults are the bundled config, `src/main/resources/migrations` and `build/audit`. Relative override paths are resolved from the directory you run the command in.

## CLI

```bash
./migration inventory
./migration targets list
./migration targets show postgres-main-dev
./migration services list
./migration services show generic-service
./migration validate --service generic-service --target postgres-main-dev --env dev
./migration plan --service generic-service --target postgres-main-dev --env dev
./migration run --service generic-service --target postgres-main-dev --env dev --mode delta
./migration run --all-services --target postgres-main-dev --env dev --mode delta
./migration run --all-services --all-targets --env dev --mode delta
./migration rebuild --service generic-service --target postgres-main-dev --env dev --confirm
./migration repair --service generic-service --target postgres-main-dev --env dev
./migration history
```

### CLI flags

- `--service`: target service name
- `--target`: target database name such as `postgres-main-dev`
- `--db`: compatibility fallback for database type such as `postgres` or `clickhouse`
- `--env`: environment name from the platform config
- `--all-services`: execute every configured service in deterministic order
- `--all-targets`: valid only with `--all-services`
- `--mode delta`: default Flyway migrate mode
- `--continue-on-error`: keep executing remaining targets after a failure
- `--allow-risky`: override risky SQL validation
- `--confirm`: required for rebuild
- `--requested-by`: audit identity

## REST API

### Endpoints

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

### Run request

```http
POST /migrations/run
Content-Type: application/json
```

```json
{
  "scope": "service",
  "service": "generic-service",
  "target": "postgres-main-dev",
  "environment": "dev",
  "mode": "delta",
  "continueOnError": false,
  "allowRisky": false,
  "requestedBy": "dba-operator"
}
```

### All-services request

```json
{
  "scope": "all-services",
  "target": "postgres-main-dev",
  "environment": "dev",
  "mode": "delta",
  "continueOnError": false,
  "allowRisky": false,
  "confirm": false
}
```

### Service mapping response

```json
{
  "service": "generic-service",
  "targets": [
    "postgres-main-dev",
    "clickhouse-analytics-dev"
  ]
}
```

## External config

```bash
./migration inventory --migration.platform.config-location=file:./database-migration-platform.yml
```
