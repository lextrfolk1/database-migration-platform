-- Migration V20260916_09__lp26_evidence_store_ledger.sql
-- Multi-layer tamper-evident evidence store ledger schema (LP-26.1)

CREATE TABLE IF NOT EXISTS evidence_store_record (
    id BIGSERIAL PRIMARY KEY,
    evidence_id VARCHAR(64) NOT NULL UNIQUE,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    step_number INTEGER NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    payload_hash VARCHAR(64) NOT NULL,
    canonical_payload JSONB NOT NULL,
    previous_evidence_hash VARCHAR(64),
    cumulative_chain_hash VARCHAR(64) NOT NULL,
    is_immutable BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_evidence_run_step UNIQUE (run_id, step_number)
);

CREATE INDEX IF NOT EXISTS idx_evidence_client_run
    ON evidence_store_record (client_id, run_id, step_number);

CREATE INDEX IF NOT EXISTS idx_evidence_chain_hash
    ON evidence_store_record (cumulative_chain_hash);

CREATE INDEX IF NOT EXISTS idx_evidence_created
    ON evidence_store_record (client_id, created_at DESC);
