-- =====================================================================
-- LP-22.1 Flyway Migration: Skill Registry & Governance (registered_definition)
-- Additive migration creating intelligence.registered_definition table,
-- 3 enums, 4 constraints, and 7 indexes. Part-M-clean (names <= 32 chars).
-- =====================================================================

-- 1. Create Enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'intelligence' AND t.typname = 'definition_kind') THEN
        CREATE TYPE intelligence.definition_kind AS ENUM ('skill', 'content_schema', 'calibrator');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'intelligence' AND t.typname = 'definition_status') THEN
        CREATE TYPE intelligence.definition_status AS ENUM ('draft', 'observed', 'operational', 'deprecated', 'retired');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'intelligence' AND t.typname = 'definition_mrm_status') THEN
        CREATE TYPE intelligence.definition_mrm_status AS ENUM ('pending', 'approved', 'rejected', 'exempt');
    END IF;
END $$;

-- 2. Create Table: intelligence.registered_definition (32 columns)
CREATE TABLE IF NOT EXISTS intelligence.registered_definition (
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

    -- Constraints
    CONSTRAINT uk_reg_def_key_ver UNIQUE (client_id, kind, definition_key, version),
    CONSTRAINT chk_reg_def_sod CHECK (mrm_approver IS NULL OR author IS NULL OR mrm_approver IS DISTINCT FROM author),
    CONSTRAINT chk_reg_def_lifecycle CHECK (status != 'operational' OR mrm_status = 'approved' OR mrm_status = 'exempt')
);

-- 3. Comments (Part-M Clean Requirement)
COMMENT ON TABLE intelligence.registered_definition IS 'Skill, content schema, and calibrator definition registry with MRM governance, lifecycle tracking, and capability-based enablement.';
COMMENT ON COLUMN intelligence.registered_definition.client_id IS 'Tenant identifier owning the registration';
COMMENT ON COLUMN intelligence.registered_definition.kind IS 'Kind discriminator: skill, content_schema, or calibrator';
COMMENT ON COLUMN intelligence.registered_definition.definition_key IS 'Unique key identifying the skill or schema';
COMMENT ON COLUMN intelligence.registered_definition.version IS 'Semantic version of the definition';
COMMENT ON COLUMN intelligence.registered_definition.status IS 'Lifecycle state: draft, observed, operational, deprecated, retired';
COMMENT ON COLUMN intelligence.registered_definition.mrm_status IS 'Model Risk Management review status';

-- 4. Create Indexes (7 Indexes, all <= 32 chars)
CREATE INDEX IF NOT EXISTS idx_reg_def_client_kind ON intelligence.registered_definition (client_id, kind);
CREATE INDEX IF NOT EXISTS idx_reg_def_key ON intelligence.registered_definition (definition_key);
CREATE INDEX IF NOT EXISTS idx_reg_def_status ON intelligence.registered_definition (status);
CREATE INDEX IF NOT EXISTS idx_reg_def_mrm_status ON intelligence.registered_definition (mrm_status);
CREATE INDEX IF NOT EXISTS idx_reg_def_domain ON intelligence.registered_definition (domain);
CREATE INDEX IF NOT EXISTS idx_reg_def_capability ON intelligence.registered_definition (capability);
CREATE INDEX IF NOT EXISTS idx_reg_def_report_fam ON intelligence.registered_definition (report_family);
