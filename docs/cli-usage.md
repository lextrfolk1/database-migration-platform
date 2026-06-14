# CLI Usage

The repo includes a `migration` wrapper script. It runs the packaged jar when available and falls back to Spring Boot during development.

## Commands

```bash
./migration inventory
./migration validate --service customer-service --db postgres --env dev
./migration plan --service customer-service --db postgres --env dev
./migration run --service customer-service --db postgres --env dev --mode delta
./migration run --all-services --db postgres --env dev --mode delta
./migration run --all-services --all-databases --env dev --mode delta
./migration rebuild --service customer-service --db postgres --env dev --confirm
./migration repair --service customer-service --db postgres --env dev
./migration history
```

## Flags

- `--service`: target service name
- `--db`: database name such as `postgres` or `clickhouse`
- `--env`: environment name from the platform config
- `--all-services`: execute every configured service in deterministic order
- `--all-databases`: valid only with `--all-services`
- `--mode delta`: default Flyway migrate mode
- `--continue-on-error`: keep executing remaining targets after a failure
- `--allow-risky`: override risky SQL validation
- `--confirm`: required for rebuild
- `--requested-by`: audit identity

## External config

```bash
./migration inventory --migration.platform.config-location=file:./migration-platform.yml
```
