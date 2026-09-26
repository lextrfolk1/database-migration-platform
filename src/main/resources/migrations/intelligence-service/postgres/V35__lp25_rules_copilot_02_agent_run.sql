-- =============================================================================
-- V35: UC11 Rules Copilot - agent_run columns (LP-25.2, migration _02)
-- =============================================================================
-- Five additive NULLABLE columns, two CHECKs, two PARTIAL indexes. Only
-- ADD COLUMN / ADD CONSTRAINT; references no enum value added by V34.
--
--  invocation_origin      WHO invoked the run (DD-9): 'user:<id>' or
--                         'system_event:<id>'. The vocabulary is CLOSED here -
--                         'scheduled_scan:...' is rejected, not discouraged.
--  authoring_session_ref  the Core authoring session that bounds persistence
--                         (DD-34): opening the form persists nothing.
--  accepted_rule_ref /    the Core rule version an accepted patch landed in
--  accepted_rule_version  (DD-35) - a ref without a version (or the reverse) is
--  accepted_at            refused in BOTH directions.
-- =============================================================================

ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS invocation_origin     text,
    ADD COLUMN IF NOT EXISTS authoring_session_ref text,
    ADD COLUMN IF NOT EXISTS accepted_rule_ref     text,
    ADD COLUMN IF NOT EXISTS accepted_rule_version integer,
    ADD COLUMN IF NOT EXISTS accepted_at           timestamptz;

-- Scoped to UC11 so it validates against every historical row, while an
-- origin-less (or out-of-vocabulary) UC11 run is physically unpersistable.
ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT agent_run_uc11_origin_chk CHECK (
        use_case IS DISTINCT FROM 'UC11'
        OR (invocation_origin IS NOT NULL AND invocation_origin ~ '^(user|system_event):[A-Za-z0-9._@:-]{1,128}$')
    );

ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT agent_run_acceptance_pair_chk CHECK (
        (accepted_rule_ref IS NULL) = (accepted_rule_version IS NULL)
        AND (accepted_rule_ref IS NULL OR accepted_at IS NOT NULL)
    );

-- PARTIAL: most runs never accept, and most never sit in an authoring session.
CREATE INDEX IF NOT EXISTS agent_run_accepted_rule_idx
    ON intelligence.agent_run (client_id, accepted_rule_ref, accepted_rule_version)
    WHERE accepted_rule_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS agent_run_authoring_session_idx
    ON intelligence.agent_run (client_id, authoring_session_ref, created_at)
    WHERE authoring_session_ref IS NOT NULL;
