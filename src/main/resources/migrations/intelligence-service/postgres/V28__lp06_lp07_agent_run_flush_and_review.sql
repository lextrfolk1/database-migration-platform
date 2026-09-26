-- =============================================================================
-- V28: agent_run flush + review columns and the review event log (LP-06.1 / LP-07.1)
-- =============================================================================
-- AgentRunRecord already carries output_hash, determinism_mode, unsupported_parameters
-- and correlation_id, but agent_run had no columns for them, so the persisted run lost
-- its idempotency/evidence hash and its correlation. This adds them (correlation is
-- three-state, an id only when PRESENT), the LP-07 review-claim columns, and the
-- review-side event log with one ENQUEUED event per run (the sweep relies on it).
-- Additive; no existing column changes.
-- =============================================================================

ALTER TABLE intelligence.agent_run
    ADD COLUMN output_hash            text,
    ADD COLUMN determinism_mode       text,
    ADD COLUMN unsupported_parameters jsonb,
    ADD COLUMN correlation_state      text,
    ADD COLUMN correlation_id         text,
    ADD COLUMN convergence_provenance jsonb,
    ADD COLUMN review_due_at          timestamptz,
    ADD COLUMN assignee_id            text,
    ADD COLUMN claimed_at             timestamptz,
    ADD COLUMN second_reviewer_id     text;

ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT agent_run_determinism_mode_chk
        CHECK (determinism_mode IS NULL OR determinism_mode IN ('seeded', 'provider_default')),
    ADD CONSTRAINT agent_run_correlation_state_chk
        CHECK (correlation_state IS NULL OR correlation_state IN ('PRESENT', 'ABSENT', 'MALFORMED')),
    -- An id is carried only when one was PRESENT; ABSENT/MALFORMED carry none.
    ADD CONSTRAINT agent_run_correlation_id_only_when_present_chk
        CHECK (correlation_id IS NULL OR correlation_state = 'PRESENT'),
    -- A claim has both halves or neither.
    ADD CONSTRAINT agent_run_claim_pair_chk
        CHECK ((assignee_id IS NULL) = (claimed_at IS NULL)),
    -- Target for composite, tenant-carrying foreign keys.
    ADD CONSTRAINT agent_run_client_id_uq UNIQUE (client_id, id);

CREATE TABLE intelligence.agent_run_review_event (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id   text NOT NULL,
    run_id      bigint NOT NULL,
    event_type  text NOT NULL,
    actor_type  text NOT NULL,
    actor_id    text,
    action      text,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT agent_run_review_event_run_fk
        FOREIGN KEY (client_id, run_id) REFERENCES intelligence.agent_run (client_id, id) ON DELETE CASCADE,
    CONSTRAINT agent_run_review_event_type_chk
        CHECK (event_type IN ('ENQUEUED', 'CLAIMED', 'DECIDED')),
    CONSTRAINT agent_run_review_event_actor_type_chk
        CHECK (actor_type IN ('SYSTEM', 'USER')),
    -- The sweep's events are SYSTEM and carry no accepting action.
    CONSTRAINT agent_run_review_event_system_no_decision_chk
        CHECK (actor_type <> 'SYSTEM' OR action IS NULL OR action NOT IN ('ACCEPT', 'CORRECT', 'REJECT'))
);

-- Exactly one ENQUEUED event per run: the sweep run twice writes it once.
CREATE UNIQUE INDEX agent_run_review_event_enqueued_uq
    ON intelligence.agent_run_review_event (client_id, run_id)
    WHERE event_type = 'ENQUEUED';

CREATE INDEX agent_run_review_event_run_idx
    ON intelligence.agent_run_review_event (client_id, run_id, created_at);

-- The stranded-completed sweep scans (client_id, status, updated_at); the worklist
-- reads (client_id, status) and agent_run_status_idx serves it.
CREATE INDEX agent_run_status_updated_idx
    ON intelligence.agent_run (client_id, status, updated_at, id);

COMMENT ON TABLE intelligence.agent_run_review_event IS
    'Review-side event log (LP-06.2 sweep, LP-07). SYSTEM events never carry an accepting action; one ENQUEUED event per run.';
