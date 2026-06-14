# Rebuild Mode

Rebuild is intended for DBA-controlled fresh rebuilds.

## Flow

- non-production: `clean` then `migrate`
- production: blocked unless `migration.platform.allow-production-rebuild=true`
- all rebuilds require explicit confirmation

## CLI

```bash
./migration rebuild --service customer-service --db postgres --env dev --confirm
```

## API

```json
{
  "scope": "service",
  "service": "customer-service",
  "database": "postgres",
  "environment": "dev",
  "confirm": true
}
```
