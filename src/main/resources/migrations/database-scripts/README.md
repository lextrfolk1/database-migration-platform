# Database Scripts Migration Directory

This directory contains database migration scripts for the core application database objects (`postgres` and `clickhouse`).

> **Sync Notice**: These migration scripts are sourced from the primary database scripts repository and should be kept in sync periodically whenever database schemas, seed data, or stored procedures are updated upstream.

---

## Directory Structure

```text
database-scripts/
├── README.md
├── clickhouse/       # ClickHouse analytics database migration scripts
└── postgres/         # PostgreSQL core database migration scripts
    ├── V0__schema_creation.sql      # Schema definitions (meta, data, adhoc, ai)
    ├── V1__meta_ddl.sql             # Metadata schema DDL, sequences, and indexes
    ├── V2__data_ddl.sql             # Data schema DDL and constraints
    ├── V3__meta_dml.sql             # Metadata master seed data
    ├── V4__data_dml.sql             # Initial data seed entries
    ├── V5__trigger_function.sql     # PL/pgSQL trigger functions & triggers
    └── V6__form_setup.sql           # Form configuration setup entries
```