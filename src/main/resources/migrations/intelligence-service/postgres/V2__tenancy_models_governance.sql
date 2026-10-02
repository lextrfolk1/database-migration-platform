-- =============================================================================
-- V2: tenancy, model registry, governance envelope, presets, skill registry,
--     calibration thresholds
-- =============================================================================
-- Folds in old V1 (model/governance layer), V4, V8, V13, V14 (tenancy tables),
-- V20 (calibration), V33 (model_registry lineage), V43 (tenant FK on client_id).
--
-- One tenant identifier: client_id. preset and registered_definition carry a
-- foreign key from client_id into tenant_profile, so a row for an unregistered
-- tenant is refused. Seed rows are in V7.
-- =============================================================================

-- ---------------------------------------------------------------------
-- Tenancy
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.tenant_profile (
    tenant_id VARCHAR(64) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    tier VARCHAR(32) NOT NULL DEFAULT 'ENTERPRISE',
    isolation_level VARCHAR(32) NOT NULL DEFAULT 'ROW_LEVEL_SECURITY',
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    config_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE intelligence.tenant_membership (
    membership_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL REFERENCES intelligence.tenant_profile(tenant_id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL,
    assigned_role VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_tenant_user UNIQUE (tenant_id, user_id)
);

CREATE INDEX idx_tenant_profile_status ON intelligence.tenant_profile(status);
CREATE INDEX idx_tenant_membership_user ON intelligence.tenant_membership(user_id);
CREATE INDEX idx_tenant_membership_tenant ON intelligence.tenant_membership(tenant_id);

-- ABAC attribute store - per-user per-tenant role/attribute binding
CREATE TABLE intelligence.abac_attribute_binding (
    binding_id      VARCHAR(64) PRIMARY KEY,
    tenant_id       VARCHAR(64) NOT NULL REFERENCES intelligence.tenant_profile(tenant_id) ON DELETE CASCADE,
    user_id         VARCHAR(64) NOT NULL,
    attribute_key   VARCHAR(128) NOT NULL,   -- e.g. "role", "data_classification", "region"
    attribute_value VARCHAR(255) NOT NULL,
    granted_by      VARCHAR(64) NOT NULL,
    granted_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uk_abac_user_attr UNIQUE (tenant_id, user_id, attribute_key)
);

CREATE INDEX idx_abac_tenant_user ON intelligence.abac_attribute_binding(tenant_id, user_id);
CREATE INDEX idx_abac_expires     ON intelligence.abac_attribute_binding(expires_at) WHERE expires_at IS NOT NULL;

-- Per-tenant encryption key references (key material is never stored)
CREATE TABLE intelligence.tenant_key_registry (
    key_id          VARCHAR(64) PRIMARY KEY,
    tenant_id       VARCHAR(64) NOT NULL REFERENCES intelligence.tenant_profile(tenant_id) ON DELETE CASCADE,
    key_alias       VARCHAR(128) NOT NULL,
    key_type        VARCHAR(32) NOT NULL DEFAULT 'AES_256_GCM', -- AES_256_GCM | RSA_4096 | EC_P384
    key_status      VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',      -- ACTIVE | ROTATED | REVOKED
    key_fingerprint VARCHAR(128) NOT NULL,                      -- SHA-256 fingerprint of public material
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    rotated_at      TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uk_tenant_key_alias UNIQUE (tenant_id, key_alias)
);

CREATE INDEX idx_tenant_key_status ON intelligence.tenant_key_registry(tenant_id, key_status);

COMMENT ON TABLE intelligence.tenant_key_registry IS
    'Cryptographic key registry for per-tenant envelope encryption. '
    'Key material is never stored here; only aliases and fingerprints.';

-- ---------------------------------------------------------------------
-- model_registry - tenant-scoped, embedding-dim-aware; drives connector
-- resolution and the three-tier routing. '__platform__' = Tier-1 defaults.
-- trained_on_dataset_* has NO foreign key, deliberately (a base model carries no dataset).
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.model_registry (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    tier            intelligence.model_tier NOT NULL DEFAULT 'tenant',
    model_type      intelligence.model_type NOT NULL,
    model_id        text NOT NULL,
    connector_class text NOT NULL,
    adapter_path    text,
    embedding_model text,
    embedding_dim   integer,
    is_local        boolean NOT NULL,
    is_default      boolean NOT NULL DEFAULT false,
    params          jsonb NOT NULL DEFAULT '{}'::jsonb,
    secrets_ref     text,                           -- Vault/KMS key reference ONLY - never a credential
    status          intelligence.lifecycle_status NOT NULL DEFAULT 'active',
    created_by      text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    trained_on_dataset_id      bigint,
    trained_on_dataset_version integer,
    CONSTRAINT model_registry_embedding_dim_chk
        CHECK (embedding_dim IS NULL OR embedding_dim > 0),
    CONSTRAINT model_registry_uq UNIQUE (client_id, model_type, model_id)
);
-- At most one default per (tenant, model_type)
CREATE UNIQUE INDEX model_registry_one_default_uq
    ON intelligence.model_registry (client_id, model_type)
    WHERE is_default;
CREATE INDEX model_registry_client_idx ON intelligence.model_registry (client_id, model_type);

COMMENT ON COLUMN intelligence.model_registry.is_local IS 'False blocks external model calls for MNPI/RESTRICTED data and on-prem deployments (OPA-enforced). True (local SLM) always permitted.';

-- ---------------------------------------------------------------------
-- prompt_template - versioned model-instruction templates
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.prompt_template (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     text NOT NULL,
    template_key  text NOT NULL,
    version       integer NOT NULL DEFAULT 1,
    task          text,
    report_type   text,
    body          text NOT NULL,
    variables     jsonb NOT NULL DEFAULT '[]'::jsonb,
    status        intelligence.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by    text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT prompt_template_uq UNIQUE (client_id, template_key, version)
);
CREATE INDEX prompt_template_task_idx ON intelligence.prompt_template (client_id, task, report_type);

-- ---------------------------------------------------------------------
-- governance_envelope - MRM-approved envelope a preset lives inside.
-- Only OPA binding REFERENCES are stored; the Rego lives in OPA.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.governance_envelope (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id            text NOT NULL,
    envelope_key         text NOT NULL,
    version              integer NOT NULL DEFAULT 1,
    status               intelligence.envelope_status NOT NULL DEFAULT 'draft',
    allowed_model_ids    bigint[] NOT NULL DEFAULT '{}',   -- references model_registry.id (array -> no FK by design)
    prohibited_model_ids bigint[] NOT NULL DEFAULT '{}',
    mnpi_rules           jsonb NOT NULL DEFAULT '{}'::jsonb,
    data_access          jsonb NOT NULL DEFAULT '{}'::jsonb,
    cost_guardrails      jsonb NOT NULL DEFAULT '{}'::jsonb,
    opa_policy_bindings  jsonb NOT NULL DEFAULT '[]'::jsonb,
    mrm_approved_by      text,
    mrm_approved_at      timestamptz,
    created_by           text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT governance_envelope_uq UNIQUE (client_id, envelope_key, version)
);
CREATE INDEX governance_envelope_status_idx ON intelligence.governance_envelope (client_id, status);

COMMENT ON COLUMN intelligence.governance_envelope.opa_policy_bindings IS 'Reference to OPA policy packages/ids only. Rego policy is externalized in OPA, never stored in the DB.';

-- ---------------------------------------------------------------------
-- preset - packaged expert knowledge for a task x report-type
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.preset (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id            text NOT NULL,
    preset_key           text NOT NULL,
    version              integer NOT NULL DEFAULT 1,
    task                 text NOT NULL,
    report_type          text,                      -- null = report-agnostic
    envelope_id          bigint NOT NULL REFERENCES intelligence.governance_envelope (id),
    prompt_template_id   bigint REFERENCES intelligence.prompt_template (id),
    model_instruction    text,
    complementary_context jsonb NOT NULL DEFAULT '{}'::jsonb,
    style                jsonb NOT NULL DEFAULT '{}'::jsonb,
    guided_questions     jsonb NOT NULL DEFAULT '[]'::jsonb,
    prompt_library       jsonb NOT NULL DEFAULT '[]'::jsonb,
    model_id_override    bigint REFERENCES intelligence.model_registry (id),  -- Tier-3 preset model override
    skill_pattern        text,
    is_agentic           boolean NOT NULL DEFAULT false,
    max_steps            smallint NOT NULL DEFAULT 6,
    kg_depth_default     smallint NOT NULL DEFAULT 3,
    kg_depth_max         smallint NOT NULL DEFAULT 5,
    output_type          intelligence.output_type,
    review_level         intelligence.review_level NOT NULL DEFAULT 'analyst',
    status               intelligence.preset_status NOT NULL DEFAULT 'draft',
    is_global            boolean NOT NULL DEFAULT false,
    forked_from          bigint REFERENCES intelligence.preset (id),
    created_by           text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT preset_uq UNIQUE (client_id, preset_key, version),
    CONSTRAINT preset_max_steps_chk CHECK (max_steps BETWEEN 1 AND 8),
    CONSTRAINT preset_kg_depth_chk  CHECK (kg_depth_default >= 1 AND kg_depth_max BETWEEN kg_depth_default AND 5),
    CONSTRAINT fk_preset_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT
);
CREATE INDEX preset_axis_idx     ON intelligence.preset (client_id, task, report_type);
CREATE INDEX preset_envelope_idx ON intelligence.preset (envelope_id);
CREATE INDEX preset_status_idx   ON intelligence.preset (client_id, status);

-- At most ONE operational preset per (client_id, task, report_type) axis
CREATE UNIQUE INDEX preset_operational_axis_uq
    ON intelligence.preset (client_id, task, report_type)
    NULLS NOT DISTINCT
    WHERE status = 'operational';

COMMENT ON INDEX intelligence.preset_operational_axis_uq IS
    'Enforces at most one operational preset per (client_id, task, report_type) axis with NULLS NOT DISTINCT for report-agnostic rows.';

-- ---------------------------------------------------------------------
-- registered_definition - skill / content schema / calibrator registry
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.registered_definition (
    id BIGSERIAL PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    kind intelligence.definition_kind NOT NULL DEFAULT 'skill',
    definition_key VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL DEFAULT '1.0.0',
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    status intelligence.definition_status NOT NULL DEFAULT 'draft',
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    is_orphaned BOOLEAN NOT NULL DEFAULT false,
    domain VARCHAR(64),
    capability VARCHAR(64),
    report_family VARCHAR(64),
    risk_tier VARCHAR(32) DEFAULT 'LOW',
    required_capabilities JSONB NOT NULL DEFAULT '[]'::jsonb,
    declared_ops JSONB NOT NULL DEFAULT '[]'::jsonb,
    tool_scope_package VARCHAR(128),
    labels JSONB NOT NULL DEFAULT '{}'::jsonb,
    custom_tags JSONB NOT NULL DEFAULT '{}'::jsonb,
    author VARCHAR(128),
    mrm_status intelligence.definition_mrm_status NOT NULL DEFAULT 'pending',
    mrm_approver VARCHAR(128),
    mrm_approval_notes TEXT,
    mrm_approved_at TIMESTAMPTZ,
    mrm_rejection_reason TEXT,
    mrm_decision_id VARCHAR(128),
    mrm_model_id VARCHAR(128),
    observed_at TIMESTAMPTZ,
    operational_at TIMESTAMPTZ,
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_reg_def_key_ver UNIQUE (client_id, kind, definition_key, version),
    CONSTRAINT chk_reg_def_sod CHECK (mrm_approver IS NULL OR author IS NULL OR mrm_approver IS DISTINCT FROM author),
    CONSTRAINT chk_reg_def_lifecycle CHECK (status != 'operational' OR mrm_status = 'approved' OR mrm_status = 'exempt'),
    CONSTRAINT fk_registered_def_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT
);

COMMENT ON TABLE intelligence.registered_definition IS 'Skill, content schema, and calibrator definition registry with MRM governance, lifecycle tracking, and capability-based enablement.';
COMMENT ON COLUMN intelligence.registered_definition.client_id IS 'Tenant identifier owning the registration';
COMMENT ON COLUMN intelligence.registered_definition.kind IS 'Kind discriminator: skill, content_schema, or calibrator';
COMMENT ON COLUMN intelligence.registered_definition.definition_key IS 'Unique key identifying the skill or schema';
COMMENT ON COLUMN intelligence.registered_definition.version IS 'Semantic version of the definition';
COMMENT ON COLUMN intelligence.registered_definition.status IS 'Lifecycle state: draft, observed, operational, deprecated, retired';
COMMENT ON COLUMN intelligence.registered_definition.mrm_status IS 'Model Risk Management review status';

CREATE INDEX idx_reg_def_client_kind ON intelligence.registered_definition (client_id, kind);
CREATE INDEX idx_reg_def_key ON intelligence.registered_definition (definition_key);
CREATE INDEX idx_reg_def_status ON intelligence.registered_definition (status);
CREATE INDEX idx_reg_def_mrm_status ON intelligence.registered_definition (mrm_status);
CREATE INDEX idx_reg_def_domain ON intelligence.registered_definition (domain);
CREATE INDEX idx_reg_def_capability ON intelligence.registered_definition (capability);
CREATE INDEX idx_reg_def_report_fam ON intelligence.registered_definition (report_family);

-- ---------------------------------------------------------------------
-- calibration_threshold - governed, immutable (superseded, never updated)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.calibration_threshold (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    threshold_key VARCHAR(64) NOT NULL,
    data_type VARCHAR(32) NOT NULL,
    threshold_value NUMERIC(10, 4) NOT NULL,
    bounds_min NUMERIC(10, 4) NOT NULL,
    bounds_max NUMERIC(10, 4) NOT NULL,
    consequence_class VARCHAR(64) NOT NULL,
    blast_radius TEXT NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    superseded_by_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',
    CONSTRAINT chk_cal_thresh_bounds CHECK (bounds_min <= threshold_value AND threshold_value <= bounds_max),
    CONSTRAINT chk_cal_thresh_type CHECK (data_type IS NOT NULL AND length(trim(data_type)) > 0),
    CONSTRAINT chk_cal_thresh_consequence CHECK (consequence_class IS NOT NULL AND length(trim(consequence_class)) > 0),
    CONSTRAINT chk_cal_thresh_blast CHECK (blast_radius IS NOT NULL AND length(trim(blast_radius)) > 0),
    CONSTRAINT chk_cal_thresh_key CHECK (threshold_key IN ('observation_floor', 'absolute_promotion_threshold', 'relative_promotion_threshold'))
);

CREATE INDEX idx_cal_thresh_lookup ON intelligence.calibration_threshold (
    client_id, threshold_key, effective_from, effective_to
);

-- At most one active threshold per client and key
CREATE UNIQUE INDEX uq_cal_thresh_active ON intelligence.calibration_threshold (
    client_id, threshold_key
) WHERE effective_to IS NULL;

CREATE OR REPLACE FUNCTION intelligence.fn_calibration_threshold_immutable()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'Calibration thresholds are immutable and cannot be updated in place. Supersede with a new effective row.';
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'Calibration thresholds are immutable and cannot be deleted.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cal_thresh_immutable
BEFORE UPDATE OR DELETE ON intelligence.calibration_threshold
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_calibration_threshold_immutable();
