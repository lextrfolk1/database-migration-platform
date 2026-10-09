-- Demo-data generator tracking table (routes/variance_demo_data_routers.py).
--
-- The generator records every period it creates here and only ever deletes
-- periods listed here. Until now the table existed only as runtime DDL in the
-- route (CREATE TABLE IF NOT EXISTS on first use), so a database built from
-- these migrations did not have it and a service role without CREATE on
-- schema variance could not use the generator at all. The route keeps its
-- IF NOT EXISTS; this migration makes the schema own the table.
--
-- Same definition as the route's TRACKING_TABLE, byte-for-byte in columns and
-- constraints, so either one may run first.
--
-- Managed pipelines: apply after variance_ddl.sql / variance_dml.sql, together
-- with 010 (the consolidated files cover 001..009 only).

CREATE TABLE IF NOT EXISTS variance.demo_generated_period (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_nm    TEXT NOT NULL,
    period       DATE NOT NULL,
    restatement_version INT NOT NULL DEFAULT 0,
    exec_id      BIGINT,
    copied_from  DATE,
    row_count    INT,
    created_by   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (report_nm, period, restatement_version)
);
