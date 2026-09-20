-- ============================================================================
-- Migration: V20260916_14__lp49_evidence_notarization.sql
-- Sub-task: LP-49.1 (SQL / Flyway)
-- Description: Creates intelligence.evidence_notarization carrying witnessed segment receipts
-- Enforces:
-- 1. evidence_notarization_valid_chk: CHECK (chain_valid) - broken chain physically unpersistable
-- 2. segment_from_day <= segment_to_day
-- 3. evidence_notarization_sig_chk: ((signature IS NULL) = (signing_key_id IS NULL))
-- 4. Content-addressed sha256 hash length checks on root_hash and receipt_hash
-- 5. client_id included in every unique constraint (db_conventions[8])
-- 6. chain_discontinuity table for explicable operations (failover/partition/restore)
-- 7. BEFORE UPDATE/DELETE trigger gated on lextr.evidence_maintenance
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS intelligence;

-- 1. Evidence Notarization Table
CREATE TABLE IF NOT EXISTS intelligence.evidence_notarization (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    scope_kind VARCHAR(64) NOT NULL,
    scope_id VARCHAR(128) NOT NULL,
    segment_from_day DATE NOT NULL,
    segment_to_day DATE NOT NULL,
    root_hash VARCHAR(64) NOT NULL,
    event_count BIGINT NOT NULL,
    chain_valid BOOLEAN NOT NULL DEFAULT TRUE,
    notarized_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notarized_by VARCHAR(128) NOT NULL,
    coverage JSONB NOT NULL DEFAULT '[]'::jsonb,
    receipt_hash VARCHAR(64) NOT NULL,
    object_uri VARCHAR(512) NOT NULL,
    signature VARCHAR(512),
    signing_key_id VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- First and load-bearing: receipt over a broken chain is physically unpersistable
    CONSTRAINT evidence_notarization_valid_chk CHECK (chain_valid = TRUE),

    -- Second: valid day range
    CONSTRAINT chk_notarization_day_range CHECK (segment_from_day <= segment_to_day),

    -- Third: signature and signing_key_id must either both be present or both be null
    CONSTRAINT evidence_notarization_sig_chk CHECK (
        (signature IS NULL AND signing_key_id IS NULL) OR
        (signature IS NOT NULL AND signing_key_id IS NOT NULL)
    ),

    -- Content-addressed hash length checks (SHA-256)
    CONSTRAINT chk_root_hash_len CHECK (length(root_hash) = 64),
    CONSTRAINT chk_receipt_hash_len CHECK (length(receipt_hash) = 64),
    CONSTRAINT chk_notarization_event_count CHECK (event_count >= 0),

    -- client_id is inside every unique constraint (db_conventions[8])
    CONSTRAINT uq_evidence_notarization_receipt UNIQUE (client_id, receipt_hash)
);

CREATE INDEX IF NOT EXISTS idx_evidence_notarization_scope
    ON intelligence.evidence_notarization (client_id, scope_kind, scope_id);

CREATE INDEX IF NOT EXISTS idx_evidence_notarization_days
    ON intelligence.evidence_notarization (client_id, segment_from_day, segment_to_day);

-- 2. Chain Discontinuity Table (LP-49.1)
-- Explicable disruption (restore, failover, partition) recorded with actor and reason
CREATE TABLE IF NOT EXISTS intelligence.chain_discontinuity (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    scope_kind VARCHAR(64) NOT NULL,
    scope_id VARCHAR(128) NOT NULL,
    discontinuity_day DATE NOT NULL,
    operation VARCHAR(64) NOT NULL,
    actor VARCHAR(128) NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_discontinuity_actor CHECK (length(trim(actor)) > 0),
    CONSTRAINT chk_discontinuity_reason CHECK (length(trim(reason)) > 0),
    CONSTRAINT uq_chain_discontinuity UNIQUE (client_id, scope_kind, scope_id, discontinuity_day)
);

-- 3. Append-only fence: BEFORE UPDATE/DELETE trigger gated on lextr.evidence_maintenance
CREATE OR REPLACE FUNCTION intelligence.fn_prevent_evidence_modification()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('lextr.evidence_maintenance', true) = 'on' THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Modification of evidence records is forbidden without lextr.evidence_maintenance enabled';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_evidence_notarization_no_modify ON intelligence.evidence_notarization;
CREATE TRIGGER trg_evidence_notarization_no_modify
    BEFORE UPDATE OR DELETE ON intelligence.evidence_notarization
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_evidence_modification();
