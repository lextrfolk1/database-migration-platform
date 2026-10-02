-- =============================================================================
-- V6: the evidence ledger - WHAT DID THE AI DO, ON WHOSE AUTHORITY, WHO RELIED
--     ON IT, WHAT HAPPENED NEXT
-- =============================================================================
-- Folds in old V11, V12, V17, V18, V21, V25, V36 (fence/chain), V37, V38, V39,
-- V40, V44, V45 (governed action vocabulary).
--
-- * Append-only is enforced by BEFORE UPDATE/DELETE triggers gated on the session
--   GUC lextr.evidence_maintenance (set via set_config(key, value, true)), never
--   by convention. The GUC is the ONLY way past.
-- * Every chained row is hash-chained to its predecessor in its TENANT-DAY chain:
--       content_hash = sha256_hex(to_jsonb(row) minus chain columns)
--       row_hash     = sha256_hex(prev_hash || '|' || content_hash)
--       genesis      = 64 x '0'
--   The head lives in evidence_chain (scope TENANT_DAY / ledger) and advances
--   monotonically. The offline verifier (LP-26.17) re-derives the same formula.
-- * agent_run_step admits exactly one update shape - an ADDITIVE input merge with
--   every other column unchanged (LP-42.4 / LP-45.4).
-- * client_id is inside every unique constraint.
-- * Retention: the database keeps only the 180-day FLOOR; it is extend-only in
--   place, and a lower window is a NEW future-dated row. Days are removed WHOLE.
-- =============================================================================

-- ---------------------------------------------------------------------
-- Merkle tree audit ledger (LP-25.1)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.merkle_tree_ledger (
    id BIGSERIAL PRIMARY KEY,
    tree_id VARCHAR(64) NOT NULL UNIQUE,
    client_id VARCHAR(64) NOT NULL,
    root_hash VARCHAR(64) NOT NULL,
    leaf_count INT NOT NULL DEFAULT 0,
    tree_depth INT NOT NULL DEFAULT 0,
    is_sealed BOOLEAN NOT NULL DEFAULT FALSE,
    sealed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS intelligence.merkle_tree_node (
    id BIGSERIAL PRIMARY KEY,
    tree_id VARCHAR(64) NOT NULL REFERENCES intelligence.merkle_tree_ledger(tree_id) ON DELETE CASCADE,
    node_hash VARCHAR(64) NOT NULL,
    level INT NOT NULL,
    position INT NOT NULL,
    is_leaf BOOLEAN NOT NULL DEFAULT FALSE,
    leaf_data_hash VARCHAR(64),
    leaf_run_id VARCHAR(64),
    left_child_hash VARCHAR(64),
    right_child_hash VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_merkle_node_pos UNIQUE (tree_id, level, position)
);

CREATE INDEX IF NOT EXISTS idx_merkle_tree_client ON intelligence.merkle_tree_ledger(client_id);
CREATE INDEX IF NOT EXISTS idx_merkle_tree_root ON intelligence.merkle_tree_ledger(root_hash);
CREATE INDEX IF NOT EXISTS idx_merkle_node_tree_pos ON intelligence.merkle_tree_node(tree_id, level, position);
CREATE INDEX IF NOT EXISTS idx_merkle_node_leaf_run ON intelligence.merkle_tree_node(leaf_run_id);

-- ---------------------------------------------------------------------
-- evidence_store_record - multi-layer tamper-evident record (LP-26.1)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.evidence_store_record (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    ON intelligence.evidence_store_record (client_id, run_id, step_number);

CREATE INDEX IF NOT EXISTS idx_evidence_chain_hash
    ON intelligence.evidence_store_record (cumulative_chain_hash);

CREATE INDEX IF NOT EXISTS idx_evidence_created
    ON intelligence.evidence_store_record (client_id, created_at DESC);

-- ---------------------------------------------------------------------
-- evidence_chain - the chain-day head table (head_signature for an external notary)
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- evidence_notarization - witnessed segment receipts; chain_discontinuity -
-- explicable disruptions (restore, failover, partition) with actor and reason (LP-49.1)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.evidence_notarization (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    scope_kind VARCHAR(64) NOT NULL,
    scope_id VARCHAR(128) NOT NULL,
    segment_from_day DATE NOT NULL,
    segment_to_day DATE NOT NULL,
    root_hash VARCHAR(64) NOT NULL,
    event_count BIGINT NOT NULL,
    chain_valid BOOLEAN NOT NULL DEFAULT TRUE,
    notarized_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notarized_by VARCHAR(128) NOT NULL,
    coverage JSONB NOT NULL DEFAULT '[]'::jsonb,
    receipt_hash VARCHAR(64) NOT NULL,
    object_uri VARCHAR(512) NOT NULL,
    signature VARCHAR(512),
    signing_key_id VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- a receipt over a broken chain is physically unpersistable
    CONSTRAINT evidence_notarization_valid_chk CHECK (chain_valid = TRUE),
    CONSTRAINT chk_notarization_day_range CHECK (segment_from_day <= segment_to_day),
    CONSTRAINT evidence_notarization_sig_chk CHECK (
        (signature IS NULL AND signing_key_id IS NULL) OR
        (signature IS NOT NULL AND signing_key_id IS NOT NULL)
    ),
    CONSTRAINT chk_root_hash_len CHECK (length(root_hash) = 64),
    CONSTRAINT chk_receipt_hash_len CHECK (length(receipt_hash) = 64),
    CONSTRAINT chk_notarization_event_count CHECK (event_count >= 0),
    CONSTRAINT uq_evidence_notarization_receipt UNIQUE (client_id, receipt_hash)
);

CREATE INDEX IF NOT EXISTS idx_evidence_notarization_scope
    ON intelligence.evidence_notarization (client_id, scope_kind, scope_id);

CREATE INDEX IF NOT EXISTS idx_evidence_notarization_days
    ON intelligence.evidence_notarization (client_id, segment_from_day, segment_to_day);

CREATE TABLE IF NOT EXISTS intelligence.chain_discontinuity (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    scope_kind VARCHAR(64) NOT NULL,
    scope_id VARCHAR(128) NOT NULL,
    discontinuity_day DATE NOT NULL,
    operation VARCHAR(64) NOT NULL,
    actor VARCHAR(128) NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_discontinuity_actor CHECK (length(trim(actor)) > 0),
    CONSTRAINT chk_discontinuity_reason CHECK (length(trim(reason)) > 0),
    CONSTRAINT uq_chain_discontinuity UNIQUE (client_id, scope_kind, scope_id, discontinuity_day)
);

CREATE OR REPLACE FUNCTION intelligence.fn_prevent_evidence_modification()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('lextr.evidence_maintenance', true) = 'on' THEN
        IF (TG_OP = 'DELETE') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    RAISE EXCEPTION 'Modification of evidence records is forbidden without lextr.evidence_maintenance enabled';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_evidence_notarization_no_modify
    BEFORE UPDATE OR DELETE ON intelligence.evidence_notarization
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_evidence_modification();

CREATE OR REPLACE TRIGGER trg_evidence_store_no_modify
    BEFORE UPDATE OR DELETE ON intelligence.evidence_store_record
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_evidence_modification();

-- ---------------------------------------------------------------------
-- Fence, chain and head functions (LP-26.1)
-- ---------------------------------------------------------------------
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

CREATE OR REPLACE TRIGGER trg_evidence_chain_head_monotonic
BEFORE UPDATE OR DELETE ON intelligence.evidence_chain
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_head_monotonic();

-- agent_run_step (table in V4) is chained and fenced
CREATE OR REPLACE TRIGGER trg_agent_run_step_chain
BEFORE INSERT ON intelligence.agent_run_step
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();

CREATE OR REPLACE TRIGGER trg_agent_run_step_fence
BEFORE UPDATE OR DELETE ON intelligence.agent_run_step
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- ---------------------------------------------------------------------
-- agent_run_event - the estate ledger: governance decisions + header history.
-- Record First, Apply Second: a refusal has NO destination. Closed action vocabulary.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.agent_run_event (
    id BIGSERIAL PRIMARY KEY,
    event_id VARCHAR(64) NOT NULL UNIQUE,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64),                              -- nullable: a refusal can have no run
    step_number INTEGER,
    event_type VARCHAR(64) NOT NULL DEFAULT 'GOVERNANCE_DECISION',
    payload_hash VARCHAR(64),
    canonical_payload JSONB,
    previous_event_hash VARCHAR(64),
    cumulative_chain_hash VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subject_kind VARCHAR(64),
    subject_id VARCHAR(64),
    capability VARCHAR(64),
    action VARCHAR(64),
    track VARCHAR(64) DEFAULT 'EVIDENTIAL',
    actor VARCHAR(64),
    authority VARCHAR(64),
    outcome VARCHAR(32),
    decision_id VARCHAR(64),
    destination VARCHAR(64),
    estate_seq BIGINT,
    chain_day    date,
    prev_hash    char(64),
    content_hash char(64),
    row_hash     char(64),
    CONSTRAINT chk_event_refusal_destination_null
        CHECK (outcome <> 'refused' OR destination IS NULL),
    CONSTRAINT chk_event_governed_action
        CHECK (action IS NULL OR action IN (
            'PIPELINE', 'ASSR_STARTED', 'ASSR_MEASURED', 'ASSR_JUDGED',
            'ATTEST', 'SUBMIT', 'APPROVE', 'REJECT',
            'RETIRE', 'SUPERSEDE', 'ROLLBACK', 'ESCALATE',
            'PRE_SUBMIT', 'PRE_APPROVE', 'PRE_REJECT',
            'TDM_SUBMIT', 'TDM_ATTEST', 'TDM_APPROVE', 'TDM_REJECT',
            'SKL_PROMOTE', 'SKL_ACTIVATE', 'SKL_REJECT', 'SKL_RETIRE',
            'FREEZE', 'TDM_LIFECYCLE', 'KH_LIFECYCLE', 'EXPORT',
            'SANDBOX_RUN', 'PARSE', 'PARSE_REFUSED', 'DROP_DECLARED',
            'INGESTED',
            'RUN', 'ACCEPT_BATCH',                   -- UC10 Analytical Assist
            'SUGGEST', 'ACCEPT'                      -- UC11 Rules Copilot
        ))
);

CREATE INDEX IF NOT EXISTS idx_agent_run_event_tenant_subject
    ON intelligence.agent_run_event (client_id, subject_id, subject_kind);

CREATE INDEX IF NOT EXISTS idx_agent_run_event_capability_track
    ON intelligence.agent_run_event (client_id, capability, track);

CREATE INDEX IF NOT EXISTS idx_agent_run_event_estate_seq
    ON intelligence.agent_run_event (estate_seq ASC);

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

CREATE OR REPLACE TRIGGER trg_agent_run_event_immutable
BEFORE UPDATE OR DELETE ON intelligence.agent_run_event
FOR EACH ROW
EXECUTE FUNCTION intelligence.fn_agent_run_event_immutability();

CREATE OR REPLACE TRIGGER trg_agent_run_event_chain BEFORE INSERT ON intelligence.agent_run_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();

-- agent_run records EVERY header change through a trigger, not call sites
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

CREATE OR REPLACE TRIGGER trg_agent_run_header_history
AFTER INSERT OR UPDATE ON intelligence.agent_run
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_agent_run_header_history();

-- ---------------------------------------------------------------------
-- agent_run_anchor - four roles (asked / touched / produced / filed)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.agent_run_anchor (
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
CREATE INDEX IF NOT EXISTS agent_run_anchor_subject_idx ON intelligence.agent_run_anchor (client_id, anchor_kind, anchor_ref);

CREATE OR REPLACE TRIGGER trg_agent_run_anchor_chain BEFORE INSERT ON intelligence.agent_run_anchor
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE OR REPLACE TRIGGER trg_agent_run_anchor_fence BEFORE UPDATE OR DELETE ON intelligence.agent_run_anchor
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- ---------------------------------------------------------------------
-- evidence_ledger_day - the tenant-day coverage state
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.evidence_ledger_day (
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

-- ---------------------------------------------------------------------
-- Retention (extend-only), archive receipts, ledger start marker (LP-26.8)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.evidence_retention (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    retention_days  integer NOT NULL,
    effective_from  date NOT NULL DEFAULT current_date,
    set_by          text NOT NULL,
    reason          text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT evidence_retention_floor_chk CHECK (retention_days >= 180),
    CONSTRAINT evidence_retention_uq UNIQUE (client_id, effective_from)
);

CREATE OR REPLACE FUNCTION intelligence.fn_evidence_retention_extend_only()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'EVIDENCE_RETENTION_EXTEND_ONLY: a retention row is never deleted' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NEW.retention_days < OLD.retention_days THEN
        RAISE EXCEPTION 'EVIDENCE_RETENTION_EXTEND_ONLY: lower the window with a NEW future-dated row, never in place'
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.client_id <> OLD.client_id OR NEW.effective_from <> OLD.effective_from THEN
        RAISE EXCEPTION 'EVIDENCE_RETENTION_EXTEND_ONLY: tenant and effective date are fixed' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_evidence_retention_extend_only
BEFORE UPDATE OR DELETE ON intelligence.evidence_retention
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_retention_extend_only();

-- a lowering applies prospectively: a new row that lowers the window must be future-dated
CREATE OR REPLACE FUNCTION intelligence.fn_evidence_retention_lowering_prospective()
RETURNS TRIGGER AS $$
DECLARE v_current integer;
BEGIN
    SELECT retention_days INTO v_current FROM intelligence.evidence_retention
     WHERE client_id = NEW.client_id AND effective_from <= current_date
     ORDER BY effective_from DESC LIMIT 1;
    IF v_current IS NOT NULL AND NEW.retention_days < v_current AND NEW.effective_from <= current_date THEN
        RAISE EXCEPTION 'EVIDENCE_RETENTION_LOWERING_PROSPECTIVE: a lower window must be dated in the future'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_evidence_retention_lowering_prospective
BEFORE INSERT ON intelligence.evidence_retention
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_retention_lowering_prospective();

-- the receipt for every lawful departure (ARCHIVED or PURGED), fenced and chained
CREATE TABLE IF NOT EXISTS intelligence.evidence_archive (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    departed_day    date NOT NULL,
    departure       text NOT NULL,
    archive_ref     text,
    day_root_hash   char(64),
    actor           text NOT NULL,
    reason          text NOT NULL,
    departed_at     timestamptz NOT NULL DEFAULT now(),
    chain_day       date,
    prev_hash       char(64),
    content_hash    char(64),
    row_hash        char(64),
    CONSTRAINT evidence_archive_departure_chk CHECK (departure IN ('ARCHIVED', 'PURGED')),
    CONSTRAINT evidence_archive_ref_chk CHECK (departure <> 'ARCHIVED' OR archive_ref IS NOT NULL),
    CONSTRAINT evidence_archive_uq UNIQUE (client_id, departed_day, departure)
);

CREATE OR REPLACE TRIGGER trg_evidence_archive_chain BEFORE INSERT ON intelligence.evidence_archive
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE OR REPLACE TRIGGER trg_evidence_archive_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_archive
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- the ledger start marker per tenant; days before it can only be ATTESTED
CREATE TABLE IF NOT EXISTS intelligence.evidence_ledger_marker (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id   text NOT NULL,
    marker_day  date NOT NULL,
    set_by      text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT evidence_ledger_marker_uq UNIQUE (client_id),
    CONSTRAINT evidence_ledger_marker_not_future_chk CHECK (marker_day <= current_date)
);

-- coverage of one tenant-day, ranked: CHAINED > PURGED > ARCHIVED > ATTESTED > NO_CHAIN
CREATE OR REPLACE FUNCTION intelligence.evidence_day_coverage(p_client_id text, p_day date)
RETURNS text AS $$
DECLARE v_status text;
BEGIN
    SELECT status INTO v_status FROM intelligence.evidence_ledger_day WHERE client_id = p_client_id AND chain_day = p_day;
    IF v_status IN ('PURGED', 'ARCHIVED', 'ATTESTED') THEN
        RETURN v_status;
    END IF;
    IF EXISTS (SELECT 1 FROM intelligence.evidence_chain
                WHERE client_id = p_client_id AND scope_kind = 'TENANT_DAY' AND scope_id = 'ledger' AND chain_day = p_day) THEN
        RETURN 'CHAINED';
    END IF;
    RETURN 'NO_CHAIN';
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------------------------------
-- Read log and issued-pack registry (LP-26.24); payload erasure event (LP-26.28)
-- ---------------------------------------------------------------------
-- A read is recorded with the entitlement decision and the POLICY VERSION that
-- permitted it. Doors REVERSE and SEARCH are declared but unreachable today.
CREATE TABLE IF NOT EXISTS intelligence.evidence_read_event (
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
CREATE INDEX IF NOT EXISTS evidence_read_event_principal_idx ON intelligence.evidence_read_event (client_id, principal, read_at);

-- manifest_hash / root_hash are RECORDED, never computed here; is_final is derived, not stored
CREATE TABLE IF NOT EXISTS intelligence.evidence_export_pack (
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

CREATE OR REPLACE TRIGGER trg_evidence_read_event_chain BEFORE INSERT ON intelligence.evidence_read_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE OR REPLACE TRIGGER trg_evidence_read_event_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_read_event
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();
CREATE OR REPLACE TRIGGER trg_evidence_export_pack_chain BEFORE INSERT ON intelligence.evidence_export_pack
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE OR REPLACE TRIGGER trg_evidence_export_pack_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_export_pack
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- The OBJECT is deleted outside the database and a row is APPENDED here; readers
-- resolve availability from the later event. No agent_run_step row is changed.
CREATE TABLE IF NOT EXISTS intelligence.evidence_payload_erasure (
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

CREATE OR REPLACE TRIGGER trg_evidence_payload_erasure_chain BEFORE INSERT ON intelligence.evidence_payload_erasure
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE OR REPLACE TRIGGER trg_evidence_payload_erasure_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_payload_erasure
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- ---------------------------------------------------------------------
-- Chain coverage: the CATALOGUE says which tables are chained and fenced; the
-- registry (evidence_coverage, rows in V7) says which the verifier can see.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intelligence.evidence_coverage (
    table_name    text PRIMARY KEY,
    registered_by text NOT NULL,
    registered_at timestamptz NOT NULL DEFAULT now()
);

-- tables with BEFORE triggers on BOTH UPDATE and DELETE
CREATE OR REPLACE FUNCTION intelligence.fn_get_structurally_fenced_tables()
RETURNS TABLE (table_name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT c.relname::TEXT
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_trigger t ON t.tgrelid = c.oid
    WHERE n.nspname = 'intelligence'
      AND (t.tgtype & 2) = 2 -- BEFORE trigger
    GROUP BY c.relname
    HAVING BOOL_OR((t.tgtype & 16) = 16) -- UPDATE
       AND BOOL_OR((t.tgtype & 8) = 8);  -- DELETE
END;
$$ LANGUAGE plpgsql;

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

-- ---------------------------------------------------------------------
-- Whole-day purge: removes a tenant-day from every structurally fenced chained
-- table, leaves a PURGED tombstone and a receipt; refuses without a named actor
-- and a stated reason, inside the retention window, or for a day already purged.
-- ---------------------------------------------------------------------
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

-- Deployment-time key custody check: 'VERIFIED_SEGREGATED', 'COLLISION_DETECTED',
-- or 'UNVERIFIABLE' when the IDP is not shared.
CREATE OR REPLACE FUNCTION intelligence.fn_verify_notary_key_custody(
    p_idp_shared BOOLEAN,
    p_app_principal VARCHAR(128),
    p_notary_key_holder VARCHAR(128)
)
RETURNS VARCHAR(32) AS $$
BEGIN
    IF NOT p_idp_shared THEN
        RETURN 'UNVERIFIABLE';
    END IF;

    IF p_app_principal IS NOT NULL AND p_app_principal = p_notary_key_holder THEN
        RETURN 'COLLISION_DETECTED';
    END IF;

    RETURN 'VERIFIED_SEGREGATED';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- Segregated evidence roles (LP-26.10 / LP-49.3), cloud-safe and idempotent:
--   evidence_owner       - schema ownership, migration, DDL
--   evidence_application - write ledger events, append chains
--   evidence_retention   - lawful purge under retention policy
--   notary_role          - READ evidence, INSERT notarization receipt, CANNOT rewrite ledger
-- Roles are created only when the migrating user holds CREATEROLE; otherwise they are
-- assumed provisioned by infrastructure. Runs after every table in V2..V6 exists, so the
-- sequence grant covers all of them.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_role_names TEXT[] := ARRAY['evidence_owner', 'evidence_application', 'evidence_retention', 'notary_role'];
    v_role TEXT;
BEGIN
    FOREACH v_role IN ARRAY v_role_names
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role) THEN
            BEGIN
                EXECUTE format('CREATE ROLE %I NOLOGIN', v_role);
                RAISE NOTICE 'Successfully created role: %', v_role;
            EXCEPTION
                WHEN insufficient_privilege THEN
                    RAISE NOTICE 'Current user lacks CREATEROLE privilege to create %. Assuming role is provisioned via cloud infrastructure.', v_role;
                WHEN duplicate_object THEN
                    NULL;
            END;
        END IF;
    END LOOP;

    FOREACH v_role IN ARRAY ARRAY['evidence_application', 'evidence_retention', 'notary_role']
    LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role) THEN
            BEGIN
                EXECUTE format('GRANT USAGE ON SCHEMA intelligence TO %I', v_role);
            EXCEPTION
                WHEN insufficient_privilege THEN
                    RAISE NOTICE 'Insufficient privilege to grant USAGE on schema intelligence to %', v_role;
            END;
        END IF;
    END LOOP;

    -- Application: append-only evidence write
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'evidence_application') THEN
        BEGIN
            GRANT SELECT, INSERT ON TABLE intelligence.evidence_store_record TO evidence_application;
            GRANT SELECT, INSERT, UPDATE ON TABLE intelligence.evidence_chain TO evidence_application;
            GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA intelligence TO evidence_application;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant application permissions to evidence_application';
        END;
    END IF;

    -- Retention: lawful purge (DELETE only; no in-place UPDATE, to preserve chain hashes)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'evidence_retention') THEN
        BEGIN
            GRANT SELECT, DELETE ON TABLE intelligence.evidence_store_record TO evidence_retention;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant retention permissions to evidence_retention';
        END;
    END IF;

    -- Notary: READ evidence and INSERT receipt ONLY
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'notary_role') THEN
        BEGIN
            GRANT SELECT ON TABLE intelligence.evidence_store_record TO notary_role;
            GRANT SELECT ON TABLE intelligence.evidence_chain TO notary_role;
            GRANT SELECT, INSERT ON TABLE intelligence.evidence_notarization TO notary_role;
            GRANT SELECT ON TABLE intelligence.chain_discontinuity TO notary_role;

            REVOKE INSERT, UPDATE, DELETE ON TABLE intelligence.evidence_chain FROM notary_role;
            REVOKE UPDATE, DELETE ON TABLE intelligence.evidence_notarization FROM notary_role;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant/revoke notary permissions for notary_role';
        END;
    END IF;
END $$;
