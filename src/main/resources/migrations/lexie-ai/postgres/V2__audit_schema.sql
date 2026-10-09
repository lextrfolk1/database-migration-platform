-- Audit schema — append-only, hash-chained event log (architecture §18).
-- The application role gets INSERT + SELECT only; UPDATE/DELETE are not
-- granted and additionally blocked by trigger for defense in depth.

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.event_log (
    event_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    analysis_id  TEXT,
    cycle_id     BIGINT,
    actor        TEXT NOT NULL,                 -- user id or service name
    actor_type   TEXT NOT NULL CHECK (actor_type IN ('SYSTEM','USER')),
    action       TEXT NOT NULL,                 -- e.g. PIPELINE_STEP, REVIEW_APPROVE, CONFIG_RESOLVED
    payload_hash TEXT NOT NULL,                 -- sha256 of payload stored in object store
    payload_ref  TEXT,                          -- object store URI of full payload
    prev_hash    TEXT NOT NULL,                 -- chain: sha256(prev_chain ‖ payload_hash)
    chain_hash   TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_audit_analysis ON audit.event_log (analysis_id, event_id);
CREATE INDEX IF NOT EXISTS ix_audit_cycle    ON audit.event_log (cycle_id, event_id);

-- Block UPDATE/DELETE regardless of role grants
CREATE OR REPLACE FUNCTION audit.reject_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit.event_log is append-only';
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_no_mutation ON audit.event_log;
CREATE TRIGGER trg_audit_no_mutation
    BEFORE UPDATE OR DELETE ON audit.event_log
    FOR EACH ROW EXECUTE FUNCTION audit.reject_mutation();

-- Example role grants (execute with adapted role names):
--   GRANT USAGE ON SCHEMA audit TO vai_app;
--   GRANT INSERT, SELECT ON audit.event_log TO vai_app;
--   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA audit TO vai_app;
