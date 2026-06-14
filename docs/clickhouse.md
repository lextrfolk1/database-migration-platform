# ClickHouse Support

ClickHouse is supported through the Flyway ClickHouse module and the ClickHouse JDBC driver.

## Behavior

- supports validation, planning, delta migration, repair, and audit
- warns that DDL is non-transactional and rollback may be manual
- uses isolated ClickHouse target configuration and driver selection

## Current rebuild policy

- the current integration marks ClickHouse rebuild as unsupported because clean semantics are high risk and not assumed safe by default
- if a future DBA standard for ClickHouse rebuild is defined, the integration can be extended without changing orchestration code
