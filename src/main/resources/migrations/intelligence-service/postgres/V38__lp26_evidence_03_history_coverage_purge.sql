-- =============================================================================
-- V38: header transition history, chain coverage and the whole-day purge
--      (LP-26.9 + the database half of LP-26.10)
-- =============================================================================
-- * agent_run_event records EVERY header change, written by an AFTER INSERT OR
--   UPDATE trigger on agent_run rather than by call sites - so a write path nobody
--   remembered is still recorded. The rows are fenced (V21) and now chained.
-- * verify_chain_coverage() asks the CATALOGUE which chained tables exist (a
--   row_hash column + a BEFORE UPDATE/DELETE fence) and compares them with the
--   verifier's coverage registry: a chained table the verifier cannot see is
--   reported CHAINED_BUT_UNSEEN - a hand-maintained list goes stale silently.
-- * evidence_purge_day() removes a tenant-day WHOLE (no row or range variant)
--   from every structurally fenced chained table - identified by its trigger,
--   never by name - leaves a PURGED tombstone and a receipt, and refuses without a
--   named actor and a stated reason, or for a day already purged.
-- =============================================================================

SET search_path TO intelligence, public;

-- ---------------------------------------------------------------- chain agent_run_event
ALTER TABLE intelligence.agent_run_event
    ADD COLUMN IF NOT EXISTS chain_day    date,
    ADD COLUMN IF NOT EXISTS prev_hash    char(64),
    ADD COLUMN IF NOT EXISTS content_hash char(64),
    ADD COLUMN IF NOT EXISTS row_hash     char(64);

DROP TRIGGER IF EXISTS trg_agent_run_event_chain ON intelligence.agent_run_event;
CREATE TRIGGER trg_agent_run_event_chain BEFORE INSERT ON intelligence.agent_run_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();

-- ---------------------------------------------------------------- header history
CREATE OR REPLACE FUNCTION intelligence.fn_agent_run_header_history()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = intelligence, public
AS $$
DECLARE v_payload jsonb;
BEGIN
    IF TG_OP = 'UPDATE' AND (to_jsonb(NEW) - 'updated_at') = (to_jsonb(OLD) - 'updated_at') THEN
        RETURN NEW;   -- nothing changed but the timestamp
    END IF;
    v_payload := jsonb_build_object(
        'op', TG_OP,
        'status', NEW.status::text,
        'previous_status', CASE WHEN TG_OP = 'UPDATE' THEN OLD.status::text END,
        'review_decision', NEW.review_decision::text,
        'reviewer_id', NEW.reviewer_id,
        'accepted_rule_ref', NEW.accepted_rule_ref,
        'accepted_rule_version', NEW.accepted_rule_version);
    INSERT INTO intelligence.agent_run_event (event_id, client_id, run_id, event_type, payload_hash, canonical_payload, actor)
    VALUES ('hdr-' || gen_random_uuid()::text, NEW.client_id, NEW.run_id, 'HEADER_TRANSITION',
            encode(sha256(convert_to(v_payload::text, 'UTF8')), 'hex'), v_payload, NEW.reviewer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_agent_run_header_history ON intelligence.agent_run;
CREATE TRIGGER trg_agent_run_header_history
AFTER INSERT OR UPDATE ON intelligence.agent_run
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_agent_run_header_history();

-- ---------------------------------------------------------------- coverage
CREATE TABLE intelligence.evidence_coverage (
    table_name    text PRIMARY KEY,
    registered_by text NOT NULL,
    registered_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO intelligence.evidence_coverage (table_name, registered_by) VALUES
    ('agent_run_step', 'LP-26.1'), ('agent_run_anchor', 'LP-26.1'),
    ('evidence_archive', 'LP-26.8'), ('agent_run_event', 'LP-26.9');

-- tables the CATALOGUE says are chained and fenced (structural: a row_hash column + BEFORE UPDATE and DELETE triggers)
CREATE OR REPLACE FUNCTION intelligence.evidence_chained_tables()
RETURNS TABLE (table_name text) AS $$
    SELECT c.relname::text
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'intelligence'
      JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'row_hash' AND NOT a.attisdropped
     WHERE c.relkind = 'r'
       AND c.relname IN (SELECT f.table_name FROM intelligence.fn_get_structurally_fenced_tables() f);
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION intelligence.verify_chain_coverage()
RETURNS TABLE (table_name text, coverage text) AS $$
    SELECT t.table_name, CASE WHEN cov.table_name IS NULL THEN 'CHAINED_BUT_UNSEEN' ELSE 'COVERED' END
      FROM intelligence.evidence_chained_tables() t
      LEFT JOIN intelligence.evidence_coverage cov ON cov.table_name = t.table_name
    UNION ALL
    SELECT cov.table_name, 'SEEN_BUT_NOT_CHAINED'
      FROM intelligence.evidence_coverage cov
     WHERE cov.table_name NOT IN (SELECT ct.table_name FROM intelligence.evidence_chained_tables() ct);
$$ LANGUAGE sql STABLE;

-- ---------------------------------------------------------------- whole-day purge
CREATE OR REPLACE FUNCTION intelligence.evidence_purge_day(p_client_id text, p_day date, p_actor text, p_reason text)
RETURNS integer AS $$
DECLARE
    v_table   text;
    v_removed integer := 0;
    v_n       integer;
    v_root    text;
    v_window  integer;
BEGIN
    IF p_actor IS NULL OR btrim(p_actor) = '' OR p_reason IS NULL OR btrim(p_reason) = '' THEN
        RAISE EXCEPTION 'EVIDENCE_PURGE_REFUSED: a removal names its actor and states its reason' USING ERRCODE = 'check_violation';
    END IF;
    IF EXISTS (SELECT 1 FROM intelligence.evidence_ledger_day WHERE client_id = p_client_id AND chain_day = p_day AND status = 'PURGED') THEN
        RAISE EXCEPTION 'EVIDENCE_PURGE_REFUSED: day % is already purged', p_day USING ERRCODE = 'check_violation';
    END IF;
    SELECT retention_days INTO v_window FROM intelligence.evidence_retention
     WHERE client_id = p_client_id AND effective_from <= current_date ORDER BY effective_from DESC LIMIT 1;
    IF p_day > current_date - COALESCE(v_window, 180) THEN
        RAISE EXCEPTION 'EVIDENCE_PURGE_REFUSED: day % is inside the retention window', p_day USING ERRCODE = 'check_violation';
    END IF;

    SELECT head_hash INTO v_root FROM intelligence.evidence_chain
     WHERE client_id = p_client_id AND scope_kind = 'TENANT_DAY' AND scope_id = 'ledger' AND chain_day = p_day;

    PERFORM set_config('lextr.evidence_maintenance', 'on', true);
    FOR v_table IN SELECT table_name FROM intelligence.evidence_chained_tables() LOOP
        EXECUTE format('DELETE FROM intelligence.%I WHERE client_id = $1 AND chain_day = $2', v_table)
            USING p_client_id, p_day;
        GET DIAGNOSTICS v_n = ROW_COUNT;
        v_removed := v_removed + v_n;
    END LOOP;
    UPDATE intelligence.evidence_chain SET status = 'PURGED'
     WHERE client_id = p_client_id AND scope_kind = 'TENANT_DAY' AND scope_id = 'ledger' AND chain_day = p_day;
    PERFORM set_config('lextr.evidence_maintenance', 'off', true);

    INSERT INTO intelligence.evidence_ledger_day (client_id, chain_day, status, actor, reason)
    VALUES (p_client_id, p_day, 'PURGED', p_actor, p_reason)
    ON CONFLICT (client_id, chain_day) DO UPDATE SET status = 'PURGED', actor = p_actor, reason = p_reason, updated_at = now();

    INSERT INTO intelligence.evidence_archive (client_id, departed_day, departure, day_root_hash, actor, reason)
    VALUES (p_client_id, p_day, 'PURGED', v_root, p_actor, p_reason);
    RETURN v_removed;
END;
$$ LANGUAGE plpgsql;
