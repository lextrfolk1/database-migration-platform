-- =============================================================================
-- V36: the evidence ledger core (LP-26.1)
-- =============================================================================
-- WHAT DID THE AI DO, ON WHOSE AUTHORITY, WHO RELIED ON IT, WHAT HAPPENED NEXT.
--
-- * Append-only is enforced by BEFORE UPDATE/DELETE triggers gated on the session
--   GUC lextr.evidence_maintenance (set via set_config(key, value, true)), never
--   by convention. The GUC is the ONLY way past.
-- * Every chained row is hash-chained to its predecessor in its TENANT-DAY chain:
--       content_hash = sha256_hex(to_jsonb(row) minus chain columns)
--       row_hash     = sha256_hex(prev_hash || '|' || content_hash)
--       genesis      = 64 x '0'
--   The head lives in intelligence.evidence_chain (scope TENANT_DAY / ledger): a
--   chain-day is opened once and its head advances monotonically. The formula is
--   the one the offline verifier (LP-26.17) re-derives - two implementations,
--   one corpus (LP-26.19).
-- * client_id is inside every unique constraint.
-- * Extends, never duplicates: evidence_chain (V18) is reused as the head table and
--   agent_run_event (V21) keeps its own columns and fence.
--
-- DEVIATION, recorded: agent_run_step is fenced, but LP-42.4 / LP-45.4 merge
-- evidence onto an existing step's `input`. The fence therefore admits exactly
-- one update shape - an ADDITIVE input merge with every other column unchanged -
-- and refuses everything else (including nulling payload_ref). See tracker.
-- =============================================================================

SET search_path TO intelligence, public;

-- ---------------------------------------------------------------- fence
CREATE OR REPLACE FUNCTION intelligence.fn_evidence_fence()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('lextr.evidence_maintenance', true) = 'on' THEN
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;
    IF TG_TABLE_NAME = 'agent_run_step' AND TG_OP = 'UPDATE'
       AND (to_jsonb(NEW) - 'input') = (to_jsonb(OLD) - 'input')
       AND COALESCE(NEW.input, '{}'::jsonb) @> COALESCE(OLD.input, '{}'::jsonb) THEN
        RETURN NEW;   -- additive evidence merge (LP-42.4 / LP-45.4) - the only admitted update
    END IF;
    RAISE EXCEPTION 'EVIDENCE_APPEND_ONLY: % on intelligence.% is refused (maintenance gate closed)', TG_OP, TG_TABLE_NAME
        USING ERRCODE = 'insufficient_privilege';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------- chain
CREATE OR REPLACE FUNCTION intelligence.fn_evidence_chain_row()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = intelligence, public
AS $$
DECLARE
    v_day  date := (now() AT TIME ZONE 'UTC')::date;
    v_prev text;
BEGIN
    NEW.chain_day := v_day;
    INSERT INTO intelligence.evidence_chain (client_id, scope_kind, scope_id, chain_day, head_hash, event_count)
    VALUES (NEW.client_id, 'TENANT_DAY', 'ledger', v_day, repeat('0', 64), 0)
    ON CONFLICT (client_id, scope_kind, scope_id, chain_day) DO NOTHING;

    SELECT head_hash INTO v_prev
      FROM intelligence.evidence_chain
     WHERE client_id = NEW.client_id AND scope_kind = 'TENANT_DAY' AND scope_id = 'ledger' AND chain_day = v_day
       FOR UPDATE;

    NEW.prev_hash := v_prev;
    NEW.content_hash := encode(sha256(convert_to(
        (to_jsonb(NEW) - 'chain_day' - 'prev_hash' - 'row_hash' - 'content_hash')::text, 'UTF8')), 'hex');
    NEW.row_hash := encode(sha256(convert_to(v_prev || '|' || NEW.content_hash, 'UTF8')), 'hex');

    UPDATE intelligence.evidence_chain
       SET head_hash = NEW.row_hash, event_count = event_count + 1
     WHERE client_id = NEW.client_id AND scope_kind = 'TENANT_DAY' AND scope_id = 'ledger' AND chain_day = v_day;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- the head only ever moves FORWARD: a count that goes down, or a head rewritten without a new row, is refused
CREATE OR REPLACE FUNCTION intelligence.fn_evidence_chain_head_monotonic()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('lextr.evidence_maintenance', true) = 'on' THEN
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        IF OLD.scope_kind = 'TENANT_DAY' THEN
            RAISE EXCEPTION 'EVIDENCE_APPEND_ONLY: a chain-day head is never deleted' USING ERRCODE = 'insufficient_privilege';
        END IF;
        RETURN OLD;
    END IF;
    IF NEW.scope_kind <> 'TENANT_DAY' THEN
        RETURN NEW;
    END IF;
    IF NEW.event_count <> OLD.event_count + 1 OR NEW.chain_day <> OLD.chain_day OR NEW.client_id <> OLD.client_id THEN
        RAISE EXCEPTION 'EVIDENCE_CHAIN_HEAD_MONOTONIC: the head advances one row at a time' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_evidence_chain_head_monotonic ON intelligence.evidence_chain;
CREATE TRIGGER trg_evidence_chain_head_monotonic
BEFORE UPDATE OR DELETE ON intelligence.evidence_chain
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_head_monotonic();

-- ---------------------------------------------------------------- run / step provenance (skill, plan, refusal)
ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS skill_ref     text,
    ADD COLUMN IF NOT EXISTS skill_version text,
    ADD COLUMN IF NOT EXISTS plan          jsonb,
    ADD COLUMN IF NOT EXISTS actor_id      text;

ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT agent_run_skill_pair_chk CHECK ((skill_ref IS NULL) = (skill_version IS NULL));

ALTER TABLE intelligence.agent_run_step
    ADD COLUMN IF NOT EXISTS skill_ref         text,
    ADD COLUMN IF NOT EXISTS skill_version     text,
    ADD COLUMN IF NOT EXISTS step_kind         text,
    ADD COLUMN IF NOT EXISTS refusal_op        text,
    ADD COLUMN IF NOT EXISTS refusal_rule      text,
    ADD COLUMN IF NOT EXISTS refusal_policy    text,
    ADD COLUMN IF NOT EXISTS refusal_reason    text,
    ADD COLUMN IF NOT EXISTS graph_snapshot_id text,
    ADD COLUMN IF NOT EXISTS subgraph_digest   char(64),
    ADD COLUMN IF NOT EXISTS chain_day         date,
    ADD COLUMN IF NOT EXISTS prev_hash         char(64),
    ADD COLUMN IF NOT EXISTS content_hash      char(64),
    ADD COLUMN IF NOT EXISTS row_hash          char(64);

ALTER TABLE intelligence.agent_run_step
    ADD CONSTRAINT agent_run_step_skill_pair_chk CHECK ((skill_ref IS NULL) = (skill_version IS NULL)),
    -- a DENIED step names the op, the rule, the policy package and the policy's own reason - all or none
    ADD CONSTRAINT agent_run_step_refusal_chk CHECK (
        (refusal_op IS NULL AND refusal_rule IS NULL AND refusal_policy IS NULL AND refusal_reason IS NULL)
        OR (refusal_op IS NOT NULL AND refusal_rule IS NOT NULL AND refusal_policy IS NOT NULL AND refusal_reason IS NOT NULL)),
    -- a traversal carries a graph snapshot id OR the content hash of the subgraph it returned
    ADD CONSTRAINT agent_run_step_traversal_chk CHECK (
        step_kind IS DISTINCT FROM 'TRAVERSAL' OR graph_snapshot_id IS NOT NULL OR subgraph_digest IS NOT NULL),
    ADD CONSTRAINT agent_run_step_kind_chk CHECK (
        step_kind IS NULL OR step_kind IN ('PLAN', 'TOOL', 'MODEL', 'TRAVERSAL', 'DENIAL', 'ASSEMBLY'));

-- a plan is step ZERO and there is exactly one per run
CREATE UNIQUE INDEX IF NOT EXISTS agent_run_step_one_plan_uq
    ON intelligence.agent_run_step (client_id, run_id) WHERE step_kind = 'PLAN';

DROP TRIGGER IF EXISTS trg_agent_run_step_chain ON intelligence.agent_run_step;
CREATE TRIGGER trg_agent_run_step_chain
BEFORE INSERT ON intelligence.agent_run_step
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();

DROP TRIGGER IF EXISTS trg_agent_run_step_fence ON intelligence.agent_run_step;
CREATE TRIGGER trg_agent_run_step_fence
BEFORE UPDATE OR DELETE ON intelligence.agent_run_step
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- ---------------------------------------------------------------- anchors (four roles)
CREATE TABLE intelligence.agent_run_anchor (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    text NOT NULL,
    run_id       text NOT NULL,
    anchor_kind  text NOT NULL,
    anchor_ref   text NOT NULL,
    role         text NOT NULL,
    recorded_at  timestamptz NOT NULL DEFAULT now(),
    chain_day    date,
    prev_hash    char(64),
    content_hash char(64),
    row_hash     char(64),
    CONSTRAINT agent_run_anchor_role_chk CHECK (role IN ('asked', 'touched', 'produced', 'filed')),
    CONSTRAINT agent_run_anchor_uq UNIQUE (client_id, run_id, anchor_kind, anchor_ref, role)
);
CREATE INDEX agent_run_anchor_subject_idx ON intelligence.agent_run_anchor (client_id, anchor_kind, anchor_ref);

CREATE TRIGGER trg_agent_run_anchor_chain BEFORE INSERT ON intelligence.agent_run_anchor
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE TRIGGER trg_agent_run_anchor_fence BEFORE UPDATE OR DELETE ON intelligence.agent_run_anchor
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- ---------------------------------------------------------------- the tenant-day coverage state
CREATE TABLE intelligence.evidence_ledger_day (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id    text NOT NULL,
    chain_day    date NOT NULL,
    status       text NOT NULL DEFAULT 'CHAINED',
    signer       text,
    reference    text,
    reason       text,
    actor        text,
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT evidence_ledger_day_uq UNIQUE (client_id, chain_day),
    CONSTRAINT evidence_ledger_day_status_chk CHECK (status IN ('CHAINED', 'ARCHIVED', 'PURGED', 'ATTESTED')),
    -- an ATTESTED day names who attested it; a PURGED day names who removed it and why
    CONSTRAINT evidence_ledger_day_attested_chk CHECK (status <> 'ATTESTED' OR (signer IS NOT NULL AND reference IS NOT NULL)),
    CONSTRAINT evidence_ledger_day_purged_chk CHECK (status <> 'PURGED' OR (actor IS NOT NULL AND reason IS NOT NULL))
);
