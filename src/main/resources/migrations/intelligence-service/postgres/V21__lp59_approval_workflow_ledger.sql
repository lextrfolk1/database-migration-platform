-- Migration V20260916_18__lp59_approval_workflow_ledger.sql
-- Approval workflow substrate — Extend LP-26 evidence ledger (LP-59.8_SQL)

-- Ensure baseline agent_run_event table exists in intelligence schema
CREATE TABLE IF NOT EXISTS intelligence.agent_run_event (
    id BIGSERIAL PRIMARY KEY,
    event_id VARCHAR(64) NOT NULL UNIQUE,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64),
    step_number INTEGER,
    event_type VARCHAR(64) NOT NULL DEFAULT 'GOVERNANCE_DECISION',
    payload_hash VARCHAR(64),
    canonical_payload JSONB,
    previous_event_hash VARCHAR(64),
    cumulative_chain_hash VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Extend agent_run_event with governance decision columns (no parallel ledger table)
ALTER TABLE intelligence.agent_run_event
    ADD COLUMN IF NOT EXISTS subject_kind VARCHAR(64),
    ADD COLUMN IF NOT EXISTS subject_id VARCHAR(64),
    ADD COLUMN IF NOT EXISTS capability VARCHAR(64),
    ADD COLUMN IF NOT EXISTS action VARCHAR(64),
    ADD COLUMN IF NOT EXISTS track VARCHAR(64) DEFAULT 'EVIDENTIAL',
    ADD COLUMN IF NOT EXISTS actor VARCHAR(64),
    ADD COLUMN IF NOT EXISTS authority VARCHAR(64),
    ADD COLUMN IF NOT EXISTS outcome VARCHAR(32),
    ADD COLUMN IF NOT EXISTS decision_id VARCHAR(64),
    ADD COLUMN IF NOT EXISTS destination VARCHAR(64),
    ADD COLUMN IF NOT EXISTS estate_seq BIGINT;

-- Ensure run_id is nullable for governance decisions (refusal case has no run)
ALTER TABLE intelligence.agent_run_event
    ALTER COLUMN run_id DROP NOT NULL;

-- Invariant: Record First, Apply Second -> Refusal has NO destination
ALTER TABLE intelligence.agent_run_event
    DROP CONSTRAINT IF EXISTS chk_event_refusal_destination_null;

ALTER TABLE intelligence.agent_run_event
    ADD CONSTRAINT chk_event_refusal_destination_null
    CHECK (outcome <> 'refused' OR destination IS NULL);

-- 30-Action Governed Vocabulary Constraint
ALTER TABLE intelligence.agent_run_event
    DROP CONSTRAINT IF EXISTS chk_event_governed_action;

ALTER TABLE intelligence.agent_run_event
    ADD CONSTRAINT chk_event_governed_action
    CHECK (action IS NULL OR action IN (
        'PIPELINE', 'ASSR_STARTED', 'ASSR_MEASURED', 'ASSR_JUDGED',
        'ATTEST', 'SUBMIT', 'APPROVE', 'REJECT',
        'RETIRE', 'SUPERSEDE', 'ROLLBACK', 'ESCALATE',
        'PRE_SUBMIT', 'PRE_APPROVE', 'PRE_REJECT',
        'TDM_SUBMIT', 'TDM_ATTEST', 'TDM_APPROVE', 'TDM_REJECT',
        'SKL_PROMOTE', 'SKL_ACTIVATE', 'SKL_REJECT', 'SKL_RETIRE',
        'FREEZE', 'TDM_LIFECYCLE', 'KH_LIFECYCLE', 'EXPORT',
        'SANDBOX_RUN', 'PARSE', 'PARSE_REFUSED', 'DROP_DECLARED',
        'INGESTED'
    ));

-- Tenant isolation: client_id is NOT NULL and indexed
CREATE INDEX IF NOT EXISTS idx_agent_run_event_tenant_subject
    ON intelligence.agent_run_event (client_id, subject_id, subject_kind);

CREATE INDEX IF NOT EXISTS idx_agent_run_event_capability_track
    ON intelligence.agent_run_event (client_id, capability, track);

CREATE INDEX IF NOT EXISTS idx_agent_run_event_estate_seq
    ON intelligence.agent_run_event (estate_seq ASC);

-- Append-Only Immutability Trigger gated by lextr.evidence_maintenance GUC
CREATE OR REPLACE FUNCTION intelligence.fn_agent_run_event_immutability()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('lextr.evidence_maintenance', true) = 'on' THEN
        IF (TG_OP = 'DELETE') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    RAISE EXCEPTION 'agent_run_event is append-only. Updates and deletes are prohibited.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_agent_run_event_immutable ON intelligence.agent_run_event;

CREATE TRIGGER trg_agent_run_event_immutable
BEFORE UPDATE OR DELETE ON intelligence.agent_run_event
FOR EACH ROW
EXECUTE FUNCTION intelligence.fn_agent_run_event_immutability();
