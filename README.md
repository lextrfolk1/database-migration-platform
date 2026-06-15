# Migration Platform

DBA-operated migration platform built on Flyway and Spring Boot.

It preserves the existing Flyway-based PostgreSQL migration flow and now uses a cleaner layered architecture around Flyway:

- shared target databases referenced by service migration definitions
- service-scoped and all-services execution
- PostgreSQL and ClickHouse integrations
- REST API and CLI execution paths
- planning, validation, rebuild, repair, and audit history
- DAO/repository, service, controller, strategy, adapter, factory, and orchestration layers

See [docs/architecture.md](/Users/tejal/Workspace/codebase/lextr/database-migrator/docs/architecture.md:1) for the platform layout and [docs/usage.md](/Users/tejal/Workspace/codebase/lextr/database-migrator/docs/usage.md:1) for CLI and API commands.
