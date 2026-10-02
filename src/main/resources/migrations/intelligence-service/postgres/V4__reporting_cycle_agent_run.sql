-- =============================================================================
-- V4: reporting cycles, materiality, population reconciliation, and the run
--     ledger (agent_run, agent_run_step and their child tables)
-- =============================================================================
-- Folds in old V1 (agent_run / agent_run_step), V2, V3, V5, V6, V7, V10, V14
-- (agent_run_step tenant_id + its dormant policies), V15, V16, V19, V28, V29,
-- V30, V31, V35, V36 (run/step provenance columns), V42, V43, V45 (accepted_by).
--
-- Tenancy: client_id is the tenant key. agent_run.client_id references
-- tenant_profile. agent_run_step keeps tenant_id, locked to client_id, because the
-- column is inside the content_hash of every chained step row (see V6).
-- Row-level security is OFF (isolation is enforced in OPA); the two agent_run_step
-- policies stay defined but dormant.
-- The evidence chain / fence / header-history triggers on these tables are in V6.
-- =============================================================================

-- ---------------------------------------------------------------------
-- reporting_cycle - close is an attestation, reopen carries its reason
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.reporting_cycle (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    cycle_key VARCHAR(64) NOT NULL,
    report_type VARCHAR(64) NOT NULL,
    period VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    closed_by VARCHAR(128),
    close_attestation JSONB,
    reopen_reason TEXT,
    reopened_by VARCHAR(128),
    reopened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL,
    CONSTRAINT rpt_cycle_client_key_uq UNIQUE (client_id, cycle_key),
    CONSTRAINT rpt_cycle_status_chk CHECK (status IN ('open', 'detect', 'analyse', 'closed', 'reopened'))
);

CREATE INDEX rpt_cycle_client_idx ON intelligence.reporting_cycle (client_id, status);

-- ---------------------------------------------------------------------
-- materiality_threshold - immutable and effective-dated
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.materiality_threshold (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    specificity_tier VARCHAR(32) NOT NULL,
    specificity_key VARCHAR(64) NOT NULL,
    pct_threshold NUMERIC(10, 4) NOT NULL,
    abs_threshold NUMERIC(18, 2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    approved_by VARCHAR(128) NOT NULL,
    superseded_by_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL,
    CONSTRAINT mat_thresh_pct_abs_chk CHECK (pct_threshold IS NOT NULL AND abs_threshold IS NOT NULL),
    CONSTRAINT mat_thresh_spec_tier_chk CHECK (specificity_tier IN ('mdrm', 'schedule', 'report', 'below_threshold'))
);

CREATE INDEX mat_thresh_lookup_idx ON intelligence.materiality_threshold (
    client_id, specificity_tier, specificity_key, effective_from, effective_to
);

CREATE OR REPLACE FUNCTION intelligence.fn_materiality_threshold_immutable()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'Materiality thresholds are immutable and cannot be updated in place. Supersede with a new effective row.';
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'Materiality thresholds are immutable and cannot be deleted.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mat_thresh_immutable
BEFORE UPDATE OR DELETE ON intelligence.materiality_threshold
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_materiality_threshold_immutable();

-- ---------------------------------------------------------------------
-- agent_run - one row per Intelligence call: run header + review outcome.
-- part1_context stores MASKED/structured context only.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id              text NOT NULL,              -- human-readable, e.g. 'run_20250527_001'
    client_id           text NOT NULL,
    preset_id           bigint REFERENCES intelligence.preset (id),
    preset_version      integer,
    model_id            bigint REFERENCES intelligence.model_registry (id),
    use_case            text,
    intent              text,
    skill_pattern       text,
    part1_context       jsonb,
    part3_user_input    text,
    output              jsonb,
    output_type         intelligence.output_type,
    confidence_score    numeric(4,3),
    status              intelligence.run_status NOT NULL DEFAULT 'created',
    observed_mode       boolean NOT NULL DEFAULT true,
    evidence_trace_id   text,
    review_level        intelligence.review_level,
    reviewer_id         text,
    reviewer_role       text,
    review_decision     intelligence.review_decision,
    review_rationale    text,
    correction          jsonb,
    confidence_at_review numeric(4,3),
    reviewed_at         timestamptz,
    parent_run_id       bigint REFERENCES intelligence.agent_run (id),  -- senior-mgmt synthesis -> analyst run
    user_id             text,
    started_at          timestamptz,
    completed_at        timestamptz,
    duration_ms         integer,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    cycle_id            BIGINT REFERENCES intelligence.reporting_cycle(id),  -- NULL reads as UNBOUND
    rerun_audit         jsonb,
    rerun_lineage_run_id bigint REFERENCES intelligence.agent_run (id),      -- re-run lineage, NOT parent_run_id
    catalog_state       VARCHAR(32),
    route_out_uc        VARCHAR(32),
    catalog_profile     VARCHAR(32),
    output_hash            text,
    determinism_mode       text,
    unsupported_parameters jsonb,
    correlation_state      text,
    correlation_id         text,
    convergence_provenance jsonb,
    review_due_at          timestamptz,
    assignee_id            text,
    claimed_at             timestamptz,
    second_reviewer_id     text,
    variance_explanation jsonb,
    locale        text,
    locale_source text,
    invocation_origin     text,                    -- UC11: 'user:<id>' or 'system_event:<id>'
    authoring_session_ref text,
    accepted_rule_ref     text,
    accepted_rule_version integer,
    accepted_at           timestamptz,
    skill_ref     text,
    skill_version text,
    plan          jsonb,
    actor_id      text,
    accepted_by   text,                            -- who accepted (X-User-Id on Core's receipt)
    CONSTRAINT agent_run_run_id_uq UNIQUE (client_id, run_id),
    CONSTRAINT agent_run_conf_chk CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
    CONSTRAINT agent_run_conf_rev_chk CHECK (confidence_at_review IS NULL OR confidence_at_review BETWEEN 0 AND 1),
    CONSTRAINT chk_agent_run_catalog_state
        CHECK (catalog_state IS NULL OR catalog_state IN ('MATCHED', 'NO_MATCH_IN_INVENTORY', 'CATALOG_NOT_READY')),
    CONSTRAINT chk_agent_run_catalog_profile
        CHECK (catalog_profile IS NULL OR catalog_profile IN ('RICH', 'STRUCTURE_ONLY', 'DEFAULT')),
    CONSTRAINT agent_run_determinism_mode_chk
        CHECK (determinism_mode IS NULL OR determinism_mode IN ('seeded', 'provider_default')),
    CONSTRAINT agent_run_correlation_state_chk
        CHECK (correlation_state IS NULL OR correlation_state IN ('PRESENT', 'ABSENT', 'MALFORMED')),
    -- An id is carried only when one was PRESENT; ABSENT/MALFORMED carry none.
    CONSTRAINT agent_run_correlation_id_only_when_present_chk
        CHECK (correlation_id IS NULL OR correlation_state = 'PRESENT'),
    -- A claim has both halves or neither.
    CONSTRAINT agent_run_claim_pair_chk
        CHECK ((assignee_id IS NULL) = (claimed_at IS NULL)),
    -- Target for composite, tenant-carrying foreign keys.
    CONSTRAINT agent_run_client_id_uq UNIQUE (client_id, id),
    CONSTRAINT agent_run_locale_source_chk
        CHECK (locale_source IS NULL OR locale_source IN ('REQUEST', 'DEFAULT')),
    CONSTRAINT agent_run_locale_pair_chk
        CHECK ((locale IS NULL) = (locale_source IS NULL)),
    -- an origin-less (or out-of-vocabulary) UC11 run is unpersistable
    CONSTRAINT agent_run_uc11_origin_chk CHECK (
        use_case IS DISTINCT FROM 'UC11'
        OR (invocation_origin IS NOT NULL AND invocation_origin ~ '^(user|system_event):[A-Za-z0-9._@:-]{1,128}$')
    ),
    CONSTRAINT agent_run_acceptance_pair_chk CHECK (
        (accepted_rule_ref IS NULL) = (accepted_rule_version IS NULL)
        AND (accepted_rule_ref IS NULL OR accepted_at IS NOT NULL)
    ),
    CONSTRAINT agent_run_skill_pair_chk CHECK ((skill_ref IS NULL) = (skill_version IS NULL)),
    CONSTRAINT fk_agent_run_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT
);
CREATE INDEX agent_run_status_idx ON intelligence.agent_run (client_id, status);
CREATE INDEX agent_run_preset_idx ON intelligence.agent_run (preset_id);
CREATE INDEX agent_run_parent_idx ON intelligence.agent_run (parent_run_id);
CREATE INDEX agent_run_cycle_idx ON intelligence.agent_run (client_id, cycle_id);
CREATE INDEX agent_run_rerun_lineage_idx
    ON intelligence.agent_run (rerun_lineage_run_id)
    WHERE rerun_lineage_run_id IS NOT NULL;
CREATE INDEX idx_agent_run_analytical_cat
    ON intelligence.agent_run (client_id, use_case, catalog_state)
    WHERE use_case = 'UC10';
-- the stranded-completed sweep scans (client_id, status, updated_at)
CREATE INDEX agent_run_status_updated_idx
    ON intelligence.agent_run (client_id, status, updated_at, id);
CREATE INDEX agent_run_cycle_line_idx
    ON intelligence.agent_run (client_id, cycle_id, ((variance_explanation -> 'subject' ->> 'mdrm_id')))
    WHERE cycle_id IS NOT NULL;
CREATE INDEX agent_run_accepted_rule_idx
    ON intelligence.agent_run (client_id, accepted_rule_ref, accepted_rule_version)
    WHERE accepted_rule_ref IS NOT NULL;
CREATE INDEX agent_run_authoring_session_idx
    ON intelligence.agent_run (client_id, authoring_session_ref, created_at)
    WHERE authoring_session_ref IS NOT NULL;

COMMENT ON TABLE intelligence.agent_run      IS 'Evidence ledger header: one row per Intelligence call. Output stores placeholder tokens only; raw RESTRICTED values are resolved at render by the reporting layer under entitlement.';

COMMENT ON COLUMN intelligence.agent_run.rerun_audit IS
    'Jsonb recording the CHANGE between the preset resolved for this re-run and the '
    'original run preset. NULL for any run that is not itself a re-run (pre-existing rows, '
    'original runs). Schema: {"preset_changed": bool, "original_preset_id": bigint, '
    '"original_preset_version": int, "new_preset_id": bigint, "new_preset_version": int, '
    '"changed_keys": [string]}. A re-run under the same preset stores preset_changed=false '
    'so the two states are always distinguishable. Added LP-19.2.';

COMMENT ON COLUMN intelligence.agent_run.rerun_lineage_run_id IS
    'FK to the immediate parent agent_run.id in a re-run chain. NULL for original runs. '
    'parent_run_id carries a different semantic (senior-mgmt synthesis -> analyst drill-down) '
    'and is NOT used for re-run lineage to avoid overloading a committed meaning. '
    'Added LP-19.2.';

COMMENT ON COLUMN intelligence.agent_run.catalog_state IS 'UC10 discovery state: MATCHED, NO_MATCH_IN_INVENTORY, CATALOG_NOT_READY';
COMMENT ON COLUMN intelligence.agent_run.route_out_uc IS 'UC10 route out destination use case (e.g. UC1, UC3, UC12)';
COMMENT ON COLUMN intelligence.agent_run.catalog_profile IS 'UC10 catalog profile: RICH, STRUCTURE_ONLY, DEFAULT';

-- ---------------------------------------------------------------------
-- agent_run_step - the per-step evidence ledger (fenced and chained in V6)
-- Payload availability: INLINE (input set), ARCHIVED (payload_ref + payload_hash), NO_PAYLOAD.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run_step (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trace_id           text NOT NULL,
    run_id             bigint NOT NULL REFERENCES intelligence.agent_run (id) ON DELETE CASCADE,
    client_id          text NOT NULL,
    step_number        smallint NOT NULL,
    step_name          text NOT NULL,
    skill              intelligence.skill_type,
    tool_called        text,
    input              jsonb,
    output_summary     text,
    output_node_count  integer,
    masking_applied    boolean NOT NULL DEFAULT false,
    masking_types      intelligence.masking_type[] NOT NULL DEFAULT '{}',
    data_classification intelligence.data_classification,
    model_id           bigint REFERENCES intelligence.model_registry (id),
    output_type        intelligence.output_type,
    preset_id          bigint,                         -- snapshot
    user_id            text,
    "timestamp"        timestamptz NOT NULL DEFAULT now(),
    duration_ms        integer,
    created_at         timestamptz NOT NULL DEFAULT now(),
    payload_hash                text,
    payload_ref                 text,
    payload_truncated           boolean,
    model_input_hash            text,
    model_input_ref             text,
    payload_classification      intelligence.data_classification,
    model_input_classification  intelligence.data_classification,
    tenant_id          VARCHAR(64) NOT NULL,
    skill_ref         text,
    skill_version     text,
    step_kind         text,
    refusal_op        text,
    refusal_rule      text,
    refusal_policy    text,
    refusal_reason    text,
    graph_snapshot_id text,
    subgraph_digest   char(64),
    chain_day         date,
    prev_hash         char(64),
    content_hash      char(64),
    row_hash          char(64),
    CONSTRAINT agent_run_step_uq UNIQUE (run_id, step_number),
    CONSTRAINT agent_run_step_payload_ref_hash_chk
        CHECK (payload_ref IS NULL OR payload_hash IS NOT NULL),
    CONSTRAINT agent_run_step_model_input_ref_hash_chk
        CHECK (model_input_ref IS NULL OR model_input_hash IS NOT NULL),
    CONSTRAINT fk_agent_run_step_tenant FOREIGN KEY (tenant_id)
        REFERENCES intelligence.tenant_profile(tenant_id) ON DELETE RESTRICT,
    CONSTRAINT ck_agent_run_step_tenant_is_client CHECK (tenant_id = client_id),
    CONSTRAINT agent_run_step_skill_pair_chk CHECK ((skill_ref IS NULL) = (skill_version IS NULL)),
    -- a DENIED step names the op, the rule, the policy package and the policy's own reason - all or none
    CONSTRAINT agent_run_step_refusal_chk CHECK (
        (refusal_op IS NULL AND refusal_rule IS NULL AND refusal_policy IS NULL AND refusal_reason IS NULL)
        OR (refusal_op IS NOT NULL AND refusal_rule IS NOT NULL AND refusal_policy IS NOT NULL AND refusal_reason IS NOT NULL)),
    -- a traversal carries a graph snapshot id OR the content hash of the subgraph it returned
    CONSTRAINT agent_run_step_traversal_chk CHECK (
        step_kind IS DISTINCT FROM 'TRAVERSAL' OR graph_snapshot_id IS NOT NULL OR subgraph_digest IS NOT NULL),
    CONSTRAINT agent_run_step_kind_chk CHECK (
        step_kind IS NULL OR step_kind IN ('PLAN', 'TOOL', 'MODEL', 'TRAVERSAL', 'DENIAL', 'ASSEMBLY'))
);
CREATE INDEX agent_run_step_run_idx   ON intelligence.agent_run_step (run_id);
CREATE INDEX agent_run_step_trace_idx ON intelligence.agent_run_step (trace_id);
CREATE INDEX idx_agent_run_step_tenant ON intelligence.agent_run_step(tenant_id, created_at DESC);
-- a plan is step ZERO and there is exactly one per run
CREATE UNIQUE INDEX agent_run_step_one_plan_uq
    ON intelligence.agent_run_step (client_id, run_id) WHERE step_kind = 'PLAN';

COMMENT ON TABLE intelligence.agent_run_step IS 'Per-step evidence ledger (MRM explainability artifact). The full trace is written before any output surfaces to a human reviewer.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_hash IS 'RFC 8785 canonical SHA-256 hash of step payload. Required if payload_ref is present.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_ref IS 'Content-addressed object store URI for offloaded step payload body.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_truncated IS 'Indicates if payload body exceeded size limits prior to hashing/archiving.';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_hash IS 'RFC 8785 canonical SHA-256 hash of direct model prompt input.';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_ref IS 'Content-addressed object store URI for model prompt input.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_classification IS 'Per-object data classification (independent of step classification).';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_classification IS 'Per-object data classification for model prompt input.';

-- Dormant RLS policies (RLS is disabled; isolation is enforced in OPA)
CREATE POLICY rls_agent_run_step_select ON intelligence.agent_run_step
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_agent_run_step_insert ON intelligence.agent_run_step
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ---------------------------------------------------------------------
-- agent_run_resolved_value - domain-value resolution provenance (UC10)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run_resolved_value (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    step_number INT NOT NULL,
    domain_key VARCHAR(64) NOT NULL,
    phrase TEXT NOT NULL,
    resolution_status VARCHAR(32) NOT NULL,
    resolved_value VARCHAR(128),
    resolution_basis VARCHAR(32) NOT NULL,
    domain_version VARCHAR(64),
    as_of_date DATE NOT NULL,
    effective_from DATE,
    effective_to DATE,
    candidates TEXT[],
    assumed_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',

    CONSTRAINT chk_res_status CHECK (
        resolution_status IN ('EXACT', 'AMBIGUOUS', 'UNRESOLVED')
    ),

    CONSTRAINT chk_res_basis CHECK (
        resolution_basis IN ('GOVERNED', 'HEURISTIC', 'ASSUMED', 'NONE')
    ),

    CONSTRAINT chk_governed_ver_date CHECK (
        resolution_basis != 'GOVERNED' OR (domain_version IS NOT NULL AND effective_from IS NOT NULL)
    ),

    CONSTRAINT chk_assumed_no_ver CHECK (
        resolution_basis != 'ASSUMED' OR domain_version IS NULL
    ),

    CONSTRAINT chk_ambiguous_spec CHECK (
        resolution_status != 'AMBIGUOUS' OR (resolved_value IS NULL AND array_length(candidates, 1) >= 2)
    ),

    CONSTRAINT chk_effective_window CHECK (
        effective_from IS NULL OR (as_of_date >= effective_from AND (effective_to IS NULL OR as_of_date <= effective_to))
    ),

    CONSTRAINT chk_unresolved_no_val CHECK (
        resolution_status != 'UNRESOLVED' OR resolved_value IS NULL
    )
);

CREATE INDEX idx_resolved_val_step
    ON intelligence.agent_run_resolved_value (client_id, run_id, step_number);

CREATE INDEX idx_resolved_val_ungoverned
    ON intelligence.agent_run_resolved_value (client_id, domain_key)
    WHERE resolution_basis != 'GOVERNED';

-- ---------------------------------------------------------------------
-- agent_run_kg_traversal - KG traversal evidence per step
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run_kg_traversal (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    step_number INT NOT NULL,
    op_name VARCHAR(64) NOT NULL,
    root_node_id VARCHAR(128) NOT NULL,
    snapshot_id VARCHAR(128),
    degradation_hash VARCHAR(128),
    is_degraded BOOLEAN NOT NULL DEFAULT FALSE,
    depth_walked INT NOT NULL,
    is_complete BOOLEAN NOT NULL DEFAULT TRUE,
    stop_bound VARCHAR(64),
    node_count INT NOT NULL DEFAULT 0,
    edge_count INT NOT NULL DEFAULT 0,
    edges JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',

    -- Snapshot ID or declared degradation required
    CONSTRAINT chk_snapshot_or_degraded CHECK (
        snapshot_id IS NOT NULL OR (is_degraded = TRUE AND degradation_hash IS NOT NULL)
    ),

    -- Degraded hash is never written into snapshot_id field
    CONSTRAINT chk_degradation_distinct CHECK (
        is_degraded = FALSE OR snapshot_id IS NULL
    ),

    -- Incomplete run must record stop bound
    CONSTRAINT chk_stop_bound_on_incomplete CHECK (
        is_complete = TRUE OR stop_bound IS NOT NULL
    ),

    -- every edge with provenance = 'RULE' carries a rule_kind (AMD-DAT-38)
    CONSTRAINT graph_edge_rule_kind_chk CHECK (
        NOT (edges @> '[{"provenance": "RULE", "rule_kind": null}]'::jsonb)
    )
);

CREATE INDEX idx_kg_traversal_step
    ON intelligence.agent_run_kg_traversal (client_id, run_id, step_number);

CREATE INDEX idx_kg_traversal_snapshot
    ON intelligence.agent_run_kg_traversal (client_id, snapshot_id)
    WHERE snapshot_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- agent_run_review_event - review-side event log, one ENQUEUED event per run
-- ---------------------------------------------------------------------
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

CREATE UNIQUE INDEX agent_run_review_event_enqueued_uq
    ON intelligence.agent_run_review_event (client_id, run_id)
    WHERE event_type = 'ENQUEUED';

CREATE INDEX agent_run_review_event_run_idx
    ON intelligence.agent_run_review_event (client_id, run_id, created_at);

COMMENT ON TABLE intelligence.agent_run_review_event IS
    'Review-side event log (LP-06.2 sweep, LP-07). SYSTEM events never carry an accepting action; one ENQUEUED event per run.';

-- ---------------------------------------------------------------------
-- reporting cycle close guard: a CLOSE is refused while bound analyses await
-- review unless an override names every outstanding run; a REOPEN carries its reason
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION intelligence.fn_reporting_cycle_close_guard()
RETURNS TRIGGER AS $$
DECLARE
    outstanding text[];
    named       text[];
BEGIN
    IF NEW.status = 'closed' AND OLD.status IS DISTINCT FROM 'closed' THEN
        SELECT coalesce(array_agg(r.run_id ORDER BY r.run_id), '{}')
          INTO outstanding
          FROM intelligence.agent_run r
         WHERE r.client_id = NEW.client_id
           AND r.cycle_id = NEW.id
           AND r.status IN ('completed', 'in_review');

        IF cardinality(outstanding) > 0 THEN
            IF NEW.close_attestation IS NULL
               OR jsonb_typeof(NEW.close_attestation -> 'override' -> 'outstanding_run_ids') <> 'array'
               OR coalesce(btrim(NEW.close_attestation -> 'override' ->> 'reason'), '') = '' THEN
                RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: % analyses await review in cycle %; an override must name each run and give a reason',
                    cardinality(outstanding), NEW.cycle_key
                    USING ERRCODE = 'check_violation';
            END IF;

            SELECT coalesce(array_agg(v ORDER BY v), '{}')
              INTO named
              FROM jsonb_array_elements_text(NEW.close_attestation -> 'override' -> 'outstanding_run_ids') AS v;

            IF NOT (named @> outstanding) THEN
                RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: override does not name every outstanding run in cycle %', NEW.cycle_key
                    USING ERRCODE = 'check_violation';
            END IF;
        END IF;

        IF NEW.closed_by IS NULL THEN
            RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: a close is an attestation and must name closed_by'
                USING ERRCODE = 'check_violation';
        END IF;
        NEW.closed_at := coalesce(NEW.closed_at, now());
    END IF;

    IF NEW.status = 'reopened' AND OLD.status IS DISTINCT FROM 'reopened' THEN
        IF coalesce(btrim(NEW.reopen_reason), '') = '' OR NEW.reopened_by IS NULL THEN
            RAISE EXCEPTION 'CYCLE_REOPEN_REFUSED: a reopen must carry reopen_reason and reopened_by'
                USING ERRCODE = 'check_violation';
        END IF;
        NEW.reopened_at := coalesce(NEW.reopened_at, now());
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reporting_cycle_close_guard
BEFORE UPDATE ON intelligence.reporting_cycle
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_reporting_cycle_close_guard();

-- ---------------------------------------------------------------------
-- Population reconciliation (LP-50). Populations are identifier lists, never
-- counts; NOT_AVAILABLE yields FALSE on all five generated gates by construction.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.reported_inventory_receipt (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    report_id VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    contract_version VARCHAR(32) NOT NULL,
    line_count INTEGER NOT NULL,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    fetched_by VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_inventory_receipt_line_count CHECK (line_count >= 0),
    CONSTRAINT uq_reported_inventory_receipt UNIQUE (client_id, report_id, version)
);

CREATE TABLE intelligence.population_reconciliation (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    cycle_id VARCHAR(128) NOT NULL,
    report_id VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    reported_inventory_state VARCHAR(32) NOT NULL,
    inventory_receipt_id BIGINT,

    -- Identifier lists, never counts
    missing_from_detection JSONB,
    missing_analyses JSONB,
    unreviewed JSONB,
    exempt_below_threshold JSONB,

    -- Witness receipt reference
    receipt_hash VARCHAR(64),
    receipt_from_day DATE,
    receipt_to_day DATE,
    cycle_from_day DATE NOT NULL,
    cycle_to_day DATE NOT NULL,

    attested_at TIMESTAMPTZ,
    attested_by VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    detection_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_from_detection IS NOT NULL AND
        jsonb_array_length(missing_from_detection) = 0
    ) STORED,

    analysis_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_analyses IS NOT NULL AND
        jsonb_array_length(missing_analyses) = 0
    ) STORED,

    review_complete BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        unreviewed IS NOT NULL AND
        jsonb_array_length(unreviewed) = 0
    ) STORED,

    integrity_verified BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        receipt_hash IS NOT NULL AND
        receipt_from_day IS NOT NULL AND
        receipt_to_day IS NOT NULL AND
        receipt_from_day <= cycle_from_day AND
        receipt_to_day >= cycle_to_day
    ) STORED,

    -- repeats the full conjunction: generated columns cannot reference each other
    submission_ready BOOLEAN GENERATED ALWAYS AS (
        reported_inventory_state = 'RECEIVED' AND
        missing_from_detection IS NOT NULL AND
        jsonb_array_length(missing_from_detection) = 0 AND
        missing_analyses IS NOT NULL AND
        jsonb_array_length(missing_analyses) = 0 AND
        unreviewed IS NOT NULL AND
        jsonb_array_length(unreviewed) = 0 AND
        receipt_hash IS NOT NULL AND
        receipt_from_day IS NOT NULL AND
        receipt_to_day IS NOT NULL AND
        receipt_from_day <= cycle_from_day AND
        receipt_to_day >= cycle_to_day
    ) STORED,

    CONSTRAINT chk_pop_inventory_state CHECK (
        reported_inventory_state IN ('RECEIVED', 'NOT_AVAILABLE')
    ),

    -- RECEIVED: lists and receipt present; NOT_AVAILABLE: lists and receipt NULL
    CONSTRAINT chk_pop_state_lists_consistency CHECK (
        (reported_inventory_state = 'RECEIVED' AND
         inventory_receipt_id IS NOT NULL AND
         missing_from_detection IS NOT NULL AND
         missing_analyses IS NOT NULL AND
         unreviewed IS NOT NULL AND
         exempt_below_threshold IS NOT NULL) OR
        (reported_inventory_state = 'NOT_AVAILABLE' AND
         inventory_receipt_id IS NULL AND
         missing_from_detection IS NULL AND
         missing_analyses IS NULL AND
         unreviewed IS NULL AND
         exempt_below_threshold IS NULL)
    ),

    CONSTRAINT chk_pop_cycle_day_range CHECK (cycle_from_day <= cycle_to_day),

    CONSTRAINT uq_population_reconciliation UNIQUE (client_id, cycle_id, report_id, version),

    CONSTRAINT fk_pop_inventory_receipt FOREIGN KEY (inventory_receipt_id)
        REFERENCES intelligence.reported_inventory_receipt (id)
);

CREATE INDEX idx_pop_reconciliation_client_cycle
    ON intelligence.population_reconciliation (client_id, cycle_id);

CREATE INDEX idx_pop_reconciliation_report
    ON intelligence.population_reconciliation (client_id, report_id, version);
