# Migration Conventions

Flyway naming is enforced by validation:

- `V001__create_table.sql`
- `V002__add_index.sql`
- `R__refresh_view.sql`
- `U001__rollback_table.sql`
- `B001__baseline.sql`

## Rules

- version numbers must be unique within one service and one database target
- repeatable migrations do not use a numeric version
- risky SQL requires `--allow-risky` or `allowRisky: true`
- shared schema bootstrap can remain in a common location that is included in multiple service targets
