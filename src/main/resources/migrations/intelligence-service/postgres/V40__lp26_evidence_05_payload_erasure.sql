-- =============================================================================
-- V40: the payload erasure EVENT - appended, never an update (LP-26.28)
-- =============================================================================
-- The OBJECT is deleted outside the database and a row is APPENDED here; readers
-- resolve availability from the LATER event. No agent_run_step row is deleted,
-- updated or renumbered (the step fence refuses nulling payload_ref), and there is
-- still no row-level or range-level DAY variant - days are removed whole.
-- Authority, actor and policy version are NOT NULL with no default.
-- Fenced and chained exactly as the others and registered for coverage; purged
-- with its day. Written to fold into V39's shape: same fence, GUC, chain columns.
-- Its vocabulary is deliberately NOT shared with evidence_archive (departures of a
-- DAY) or evidence_notarization (external witness receipts).
-- =============================================================================

SET search_path TO intelligence, public;

CREATE TABLE intelligence.evidence_payload_erasure (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id          text NOT NULL,
    erasure_ref        text NOT NULL,
    run_id             text NOT NULL,
    step_id            text NOT NULL,
    payload_hash       char(64) NOT NULL,
    discharged_ref     text NOT NULL,
    subject_anchor     text NOT NULL,
    subject_role       text NOT NULL,
    authority          text NOT NULL,
    actor              text NOT NULL,
    policy_version     text NOT NULL,
    erased_at          timestamptz NOT NULL DEFAULT now(),
    chain_day          date,
    prev_hash          char(64),
    content_hash       char(64),
    row_hash           char(64),
    CONSTRAINT evidence_payload_erasure_uq UNIQUE (client_id, erasure_ref),
    CONSTRAINT evidence_payload_erasure_once_uq UNIQUE (client_id, run_id, step_id, discharged_ref),
    CONSTRAINT evidence_payload_erasure_ref_chk CHECK (discharged_ref IN ('payload', 'model_input')),
    CONSTRAINT evidence_payload_erasure_role_chk CHECK (subject_role IN ('asked', 'touched', 'produced', 'filed'))
);

CREATE TRIGGER trg_evidence_payload_erasure_chain BEFORE INSERT ON intelligence.evidence_payload_erasure
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE TRIGGER trg_evidence_payload_erasure_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_payload_erasure
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

INSERT INTO intelligence.evidence_coverage (table_name, registered_by) VALUES ('evidence_payload_erasure', 'LP-26.28');
