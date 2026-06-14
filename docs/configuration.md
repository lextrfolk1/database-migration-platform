# Configuration

The default config file is `classpath:migration-platform.yml`.

## Example

```yaml
defaultEnvironment: dev
environments:
  dev:
    services:
      customer-service:
        postgres:
          url: jdbc:postgresql://localhost:5432/customer
          username: customer_user
          passwordEnv: CUSTOMER_POSTGRES_PASSWORD
          locations:
            - migrations/customer-service/postgres
```

## Secrets

- do not hardcode credentials in the config file
- use `passwordEnv` to resolve secrets from environment variables
- the current design keeps secret resolution separate from inventory so Vault or another secret manager can be added later

## Platform settings

- `migration.platform.config-location`
- `migration.platform.audit-directory`
- `migration.platform.allow-production-rebuild`
- `migration.platform.default-requested-by`
