# PostgreSQL Support

PostgreSQL is the default relational engine.

## Behavior

- uses the PostgreSQL Flyway database module
- supports delta migration through `migrate`
- supports rebuild through `clean` plus `migrate`
- supports repair through `repair`
- reports locking-risk warnings for index-oriented changes and other flagged DDL
- uses configured schemas when provided

## Notes

- transactional behavior is assumed where PostgreSQL and Flyway support it
- rebuild is blocked if Flyway clean is disabled or if production rebuild is not explicitly allowed
