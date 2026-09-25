-- ============================================================================
-- Migration: V20260916_16__lp50_population_reconciliation.sql
-- Sub-task: LP-50.1 (PostgreSQL 16 / Flyway)
-- Description: Creates population_reconciliation and reported_inventory_receipt tables.
-- Enforces:
-- 1. Generated ALWAYS columns for all 5 gates (detection_complete, analysis_complete, review_complete, integrity_verified, submission_ready)
-- 2. Fail-safe state: reported_inventory_state IN ('RECEIVED', 'NOT_AVAILABLE')
-- 3. NOT_AVAILABLE yields FALSE on all 5 gates by construction
-- 4. No count columns - populations stored as identifier lists (JSONB arrays)
-- 5. No token 'coverage' in DDL, column names, index names or constraint names
-- 6. client_id in every unique constraint (db_conventions[8])
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS intelligence;

-- 1. Reported Inventory Receipt Table
-- Proves a fetch from Core actually occurred with metadata only
CREATE TABLE IF NOT EXISTS intelligence.reported_inventory_receipt (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    report_id VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    contract_version VARCHAR(32) NOT NULL,
    line_count INTEGER NOT NULL,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    fetched_by VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_inventory_receipt_line_count CHECK (line_count >= 0),
    CONSTRAINT uq_reported_inventory_receipt UNIQUE (client_id, report_id, version)
);

-- 2. Population Reconciliation Table
CREATE TABLE IF NOT EXISTS intelligence.population_reconciliation (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    cycle_id VARCHAR(128) NOT NULL,
    report_id VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    reported_inventory_state VARCHAR(32) NOT NULL,
    inventory_receipt_id BIGINT,

    -- Identifier lists, never counts
    missing_from_detection JSONB,
    missing_analyses JSONB,
    unreviewed JSONB,
    exempt_below_threshold JSONB,

    -- Witness receipt reference
    receipt_hash VARCHAR(64),
    receipt_from_day DATE,
    receipt_to_day DATE,
    cycle_from_day DATE NOT NULL,
    cycle_to_day DATE NOT NULL,

    attested_at TIMESTAMPTZ,
    attested_by VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Five GENERATED ALWAYS columns (stored)
    detection_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_from_detection IS NOT NULL AND
        jsonb_array_length(missing_from_detection) = 0
    ) STORED,

    analysis_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_analyses IS NOT NULL AND
        jsonb_array_length(missing_analyses) = 0
    ) STORED,

    review_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        unreviewed IS NOT NULL AND
        jsonb_array_length(unreviewed) = 0
    ) STORED,

    integrity_verified BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        receipt_hash IS NOT NULL AND
        receipt_from_day IS NOT NULL AND
        receipt_to_day IS NOT NULL AND
        receipt_from_day <= cycle_from_day AND
        receipt_to_day >= cycle_to_day
    ) STORED,

    -- submission_ready repeats full conjunction because Postgres generated columns cannot reference each other
    submission_ready BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_from_detection IS NOT NULL AND
        jsonb_array_length(missing_from_detection) = 0 AND
        missing_analyses IS NOT NULL AND
        jsonb_array_length(missing_analyses) = 0 AND
        unreviewed IS NOT NULL AND
        jsonb_array_length(unreviewed) = 0 AND
        receipt_hash IS NOT NULL AND
        receipt_from_day IS NOT NULL AND
        receipt_to_day IS NOT NULL AND
        receipt_from_day <= cycle_from_day AND
        receipt_to_day >= cycle_to_day
    ) STORED,

    CONSTRAINT chk_pop_inventory_state CHECK (
        reported_inventory_state IN ('RECEIVED', 'NOT_AVAILABLE')
    ),

    -- Load-bearing fail-safe:
    -- Under RECEIVED: lists must NOT be NULL and inventory_receipt_id must be present
    -- Under NOT_AVAILABLE: lists must be NULL and inventory_receipt_id must be NULL
    CONSTRAINT chk_pop_state_lists_consistency CHECK (
        (reported_inventory_state = 'RECEIVED' AND
         inventory_receipt_id IS NOT NULL AND
         missing_from_detection IS NOT NULL AND
         missing_analyses IS NOT NULL AND
         unreviewed IS NOT NULL AND
         exempt_below_threshold IS NOT NULL) OR
        (reported_inventory_state = 'NOT_AVAILABLE' AND
         inventory_receipt_id IS NULL AND
         missing_from_detection IS NULL AND
         missing_analyses IS NULL AND
         unreviewed IS NULL AND
         exempt_below_threshold IS NULL)
    ),

    CONSTRAINT chk_pop_cycle_day_range CHECK (cycle_from_day <= cycle_to_day),

    CONSTRAINT uq_population_reconciliation UNIQUE (client_id, cycle_id, report_id, version),

    CONSTRAINT fk_pop_inventory_receipt FOREIGN KEY (inventory_receipt_id)
        REFERENCES intelligence.reported_inventory_receipt (id)
);

CREATE INDEX IF NOT EXISTS idx_pop_reconciliation_client_cycle
    ON intelligence.population_reconciliation (client_id, cycle_id);

CREATE INDEX IF NOT EXISTS idx_pop_reconciliation_report
    ON intelligence.population_reconciliation (client_id, report_id, version);
