-- ============================================================================
-- Migration: V20260916_15__lp49_evidence_chain_signature.sql
-- Sub-task: LP-49.1 (SQL / Flyway)
-- Description: Adds head_signature and head_signed_at columns to intelligence.evidence_chain
--              closing columns designed for external notary witness
-- ============================================================================

CREATE TABLE IF NOT EXISTS intelligence.evidence_chain (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    scope_kind VARCHAR(64) NOT NULL,
    scope_id VARCHAR(128) NOT NULL,
    chain_day DATE NOT NULL,
    head_hash VARCHAR(64) NOT NULL,
    event_count BIGINT NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    head_signature VARCHAR(512),
    head_signed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_evidence_chain_day UNIQUE (client_id, scope_kind, scope_id, chain_day)
);

-- Ensure columns exist if table was already created in prior migration
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'intelligence'
          AND table_name = 'evidence_chain'
          AND column_name = 'head_signature'
    ) THEN
        ALTER TABLE intelligence.evidence_chain ADD COLUMN head_signature VARCHAR(512);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'intelligence'
          AND table_name = 'evidence_chain'
          AND column_name = 'head_signed_at'
    ) THEN
        ALTER TABLE intelligence.evidence_chain ADD COLUMN head_signed_at TIMESTAMPTZ;
    END IF;
END $$;
