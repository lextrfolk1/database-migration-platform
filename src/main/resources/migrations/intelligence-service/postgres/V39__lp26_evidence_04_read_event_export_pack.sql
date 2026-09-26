-- =============================================================================
-- V39: the evidence read log and the issued-pack registry - ONE migration (LP-26.24)
-- =============================================================================
-- fixed_contracts[13]: both land in ONE migration (one CONTRACT approval, one coverage
-- re-run, one purge re-run, and no chance of fencing the two differently).
-- Fenced and chained EXACTLY as the others: chain columns, the lextr.evidence_maintenance
-- fence, client_id inside every unique constraint, registered for coverage.
--
-- evidence_read_event: NIST AU-3 content for an access event. The entitlement decision
--   and the POLICY VERSION that produced it are NOT NULL with no default - a read
--   recorded without the authority that permitted it is impossible. The door is the
--   surface's taxonomy: FORWARD is built; REVERSE and SEARCH are declared but
--   UNREACHABLE today (asserted by a check, not quietly used).
-- evidence_export_pack: scope, the versioned format_id stamped INSIDE the pack,
--   manifest_hash and root_hash (RECORDED, never computed here), issued_to/at.
--   is_final is NOT a column: LP-26.20 derives it from agent_run.review_decision.
-- =============================================================================

SET search_path TO intelligence, public;

CREATE TABLE intelligence.evidence_read_event (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id          text NOT NULL,
    read_ref           text NOT NULL,
    principal          text NOT NULL,
    principal_roles    text[] NOT NULL,
    subject_anchor     text NOT NULL,
    subject_role       text NOT NULL,
    door               text NOT NULL,
    decision           text NOT NULL,
    decision_rule      text NOT NULL,
    policy_version     text NOT NULL,
    manifest_hash      char(64),
    read_at            timestamptz NOT NULL DEFAULT now(),
    chain_day          date,
    prev_hash          char(64),
    content_hash       char(64),
    row_hash           char(64),
    CONSTRAINT evidence_read_event_uq UNIQUE (client_id, read_ref),
    CONSTRAINT evidence_read_event_door_chk CHECK (door IN ('FORWARD', 'REVERSE', 'SEARCH')),
    CONSTRAINT evidence_read_event_decision_chk CHECK (decision IN ('ALLOW')),
    CONSTRAINT evidence_read_event_role_chk CHECK (subject_role IN ('asked', 'touched', 'produced', 'filed'))
);
CREATE INDEX evidence_read_event_principal_idx ON intelligence.evidence_read_event (client_id, principal, read_at);

CREATE TABLE intelligence.evidence_export_pack (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id          text NOT NULL,
    pack_ref           text NOT NULL,
    scope_kind         text NOT NULL,
    scope_ref          text NOT NULL,
    format_id          text NOT NULL,
    manifest_hash      char(64) NOT NULL,
    root_hash          char(64),
    chain_break_index  integer,
    issued_to          text NOT NULL,
    issued_at          timestamptz NOT NULL DEFAULT now(),
    chain_day          date,
    prev_hash          char(64),
    content_hash       char(64),
    row_hash           char(64),
    CONSTRAINT evidence_export_pack_uq UNIQUE (client_id, pack_ref),
    CONSTRAINT evidence_export_pack_manifest_uq UNIQUE (client_id, manifest_hash),
    -- a chain that did not re-derive has NO root and a MANDATORY break index
    CONSTRAINT evidence_export_pack_root_chk CHECK ((root_hash IS NULL) = (chain_break_index IS NOT NULL))
);

CREATE TRIGGER trg_evidence_read_event_chain BEFORE INSERT ON intelligence.evidence_read_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE TRIGGER trg_evidence_read_event_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_read_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();
CREATE TRIGGER trg_evidence_export_pack_chain BEFORE INSERT ON intelligence.evidence_export_pack
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE TRIGGER trg_evidence_export_pack_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_export_pack
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

INSERT INTO intelligence.evidence_coverage (table_name, registered_by) VALUES
    ('evidence_read_event', 'LP-26.24'), ('evidence_export_pack', 'LP-26.24');
