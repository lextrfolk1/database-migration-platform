-- ============================================================================
-- Migration: V20260916_02__lp14_reporting_cycle_materiality_threshold.sql
-- Sub-task: LP-14.0 (SQL / Flyway)
-- Description: First-class reporting cycle lifecycle and immutable effective-dated materiality thresholds.
-- Conforms to Part-M naming standards (identifiers <= 32 chars).
-- ============================================================================

-- 1. Reporting Cycle Table
CREATE TABLE IF NOT EXISTS intelligence.reporting_cycle (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    cycle_key VARCHAR(64) NOT NULL,
    report_type VARCHAR(64) NOT NULL,
    period VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    closed_by VARCHAR(128),
    close_attestation JSONB,
    reopen_reason TEXT,
    reopened_by VARCHAR(128),
    reopened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL,
    CONSTRAINT rpt_cycle_client_key_uq UNIQUE (client_id, cycle_key),
    CONSTRAINT rpt_cycle_status_chk CHECK (status IN ('open', 'detect', 'analyse', 'closed', 'reopened'))
);

CREATE INDEX IF NOT EXISTS rpt_cycle_client_idx ON intelligence.reporting_cycle (client_id, status);

-- 2. Materiality Threshold Table (Immutable & Effective-Dated)
CREATE TABLE IF NOT EXISTS intelligence.materiality_threshold (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    specificity_tier VARCHAR(32) NOT NULL,
    specificity_key VARCHAR(64) NOT NULL,
    pct_threshold NUMERIC(10, 4) NOT NULL,
    abs_threshold NUMERIC(18, 2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    approved_by VARCHAR(128) NOT NULL,
    superseded_by_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL,
    CONSTRAINT mat_thresh_pct_abs_chk CHECK (pct_threshold IS NOT NULL AND abs_threshold IS NOT NULL),
    CONSTRAINT mat_thresh_spec_tier_chk CHECK (specificity_tier IN ('mdrm', 'schedule', 'report', 'below_threshold'))
);

CREATE INDEX IF NOT EXISTS mat_thresh_lookup_idx ON intelligence.materiality_threshold (
    client_id, specificity_tier, specificity_key, effective_from, effective_to
);

-- Refuse in-place UPDATE and DELETE at database layer (immutable audit trail)
CREATE OR REPLACE FUNCTION intelligence.fn_materiality_threshold_immutable()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'Materiality thresholds are immutable and cannot be updated in place. Supersede with a new effective row.';
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'Materiality thresholds are immutable and cannot be deleted.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mat_thresh_immutable ON intelligence.materiality_threshold;
CREATE TRIGGER trg_mat_thresh_immutable
BEFORE UPDATE OR DELETE ON intelligence.materiality_threshold
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_materiality_threshold_immutable();
