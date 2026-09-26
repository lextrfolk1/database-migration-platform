-- =============================================================================
-- V37: retention, archive and coverage (LP-26.8)
-- =============================================================================
-- * ONE retention window governs both halves. The database keeps only the
--   180-day FLOOR (a fact); everything above it is policy (lextr.ai.evidence_lifecycle).
-- * Retention is EXTEND-ONLY IN PLACE: lowering a row is refused; a lower window
--   is a NEW row effective in the future (applies prospectively).
-- * Every lawful departure leaves a receipt in evidence_archive (fenced, chained).
-- * A purged day reports PURGED, never NO_CHAIN, so 'removed lawfully' and
--   'went missing' can be told apart.
-- * R4: days predating the ledger marker may be ATTESTED by a named signer; an
--   attested day ranks BELOW a real chain and below a lawful purge and never reads
--   as covered. A marker cannot be dated in the future.
-- =============================================================================

SET search_path TO intelligence, public;

CREATE TABLE intelligence.evidence_retention (
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

CREATE TRIGGER trg_evidence_retention_extend_only
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

CREATE TRIGGER trg_evidence_retention_lowering_prospective
BEFORE INSERT ON intelligence.evidence_retention
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_retention_lowering_prospective();

-- the receipt for every lawful departure (ARCHIVED or PURGED), fenced and chained
CREATE TABLE intelligence.evidence_archive (
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

CREATE TRIGGER trg_evidence_archive_chain BEFORE INSERT ON intelligence.evidence_archive
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_chain_row();
CREATE TRIGGER trg_evidence_archive_fence BEFORE UPDATE OR DELETE ON intelligence.evidence_archive
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_evidence_fence();

-- the ledger start marker per tenant; days before it can only be ATTESTED
CREATE TABLE intelligence.evidence_ledger_marker (
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
