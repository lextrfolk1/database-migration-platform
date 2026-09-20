-- Lextr Intelligence Platform — Row-Level Security & Tenant Boundary Enforcement (LP-80.1)
-- Adds RLS policies to all tenant-scoped tables so that every query is automatically
-- filtered by the current_setting('app.current_tenant_id') session parameter.
-- Invariant: No cross-tenant row is ever visible regardless of application-layer predicates.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add tenant_id column to core execution tables (if not already present)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE agent_run
    ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NOT NULL DEFAULT 'DEFAULT_TENANT'
        REFERENCES tenant_profile(tenant_id) ON DELETE RESTRICT;

ALTER TABLE evidence_step
    ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NOT NULL DEFAULT 'DEFAULT_TENANT'
        REFERENCES tenant_profile(tenant_id) ON DELETE RESTRICT;

ALTER TABLE preset_definition
    ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NOT NULL DEFAULT 'DEFAULT_TENANT'
        REFERENCES tenant_profile(tenant_id) ON DELETE RESTRICT;

ALTER TABLE registered_definition
    ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NOT NULL DEFAULT 'DEFAULT_TENANT'
        REFERENCES tenant_profile(tenant_id) ON DELETE RESTRICT;

ALTER TABLE review_queue_item
    ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NOT NULL DEFAULT 'DEFAULT_TENANT'
        REFERENCES tenant_profile(tenant_id) ON DELETE RESTRICT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Composite indexes — tenant-first for optimal RLS predicate push-down
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_agent_run_tenant         ON agent_run(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_evidence_step_tenant     ON evidence_step(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_preset_definition_tenant ON preset_definition(tenant_id);
CREATE INDEX IF NOT EXISTS idx_registered_def_tenant    ON registered_definition(tenant_id);
CREATE INDEX IF NOT EXISTS idx_review_queue_tenant      ON review_queue_item(tenant_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Enable Row-Level Security on all tenant-scoped tables
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE agent_run            ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_run            FORCE ROW LEVEL SECURITY;

ALTER TABLE evidence_step        ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence_step        FORCE ROW LEVEL SECURITY;

ALTER TABLE preset_definition    ENABLE ROW LEVEL SECURITY;
ALTER TABLE preset_definition    FORCE ROW LEVEL SECURITY;

ALTER TABLE registered_definition ENABLE ROW LEVEL SECURITY;
ALTER TABLE registered_definition FORCE ROW LEVEL SECURITY;

ALTER TABLE review_queue_item    ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_queue_item    FORCE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RLS SELECT policies — enforce tenant_id = session parameter
-- ─────────────────────────────────────────────────────────────────────────────

CREATE POLICY rls_agent_run_select ON agent_run
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_agent_run_insert ON agent_run
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_agent_run_update ON agent_run
    FOR UPDATE
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ──────────────────────────────────

CREATE POLICY rls_evidence_step_select ON evidence_step
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_evidence_step_insert ON evidence_step
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ──────────────────────────────────

CREATE POLICY rls_preset_select ON preset_definition
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_preset_insert ON preset_definition
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_preset_update ON preset_definition
    FOR UPDATE
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ──────────────────────────────────

CREATE POLICY rls_regdef_select ON registered_definition
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_regdef_insert ON registered_definition
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ──────────────────────────────────

CREATE POLICY rls_review_select ON review_queue_item
    FOR SELECT
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_review_insert ON review_queue_item
    FOR INSERT
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', TRUE));

CREATE POLICY rls_review_update ON review_queue_item
    FOR UPDATE
    USING (tenant_id = current_setting('app.current_tenant_id', TRUE));

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. ABAC attribute store — per-user per-tenant role/attribute binding
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS abac_attribute_binding (
    binding_id      VARCHAR(64) PRIMARY KEY,
    tenant_id       VARCHAR(64) NOT NULL REFERENCES tenant_profile(tenant_id) ON DELETE CASCADE,
    user_id         VARCHAR(64) NOT NULL,
    attribute_key   VARCHAR(128) NOT NULL,   -- e.g. "role", "data_classification", "region"
    attribute_value VARCHAR(255) NOT NULL,
    granted_by      VARCHAR(64) NOT NULL,
    granted_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uk_abac_user_attr UNIQUE (tenant_id, user_id, attribute_key)
);

CREATE INDEX IF NOT EXISTS idx_abac_tenant_user ON abac_attribute_binding(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_abac_expires     ON abac_attribute_binding(expires_at) WHERE expires_at IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Tenant cryptographic key registry — per-tenant encryption key references
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS tenant_key_registry (
    key_id          VARCHAR(64) PRIMARY KEY,
    tenant_id       VARCHAR(64) NOT NULL REFERENCES tenant_profile(tenant_id) ON DELETE CASCADE,
    key_alias       VARCHAR(128) NOT NULL,
    key_type        VARCHAR(32) NOT NULL DEFAULT 'AES_256_GCM', -- AES_256_GCM | RSA_4096 | EC_P384
    key_status      VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',      -- ACTIVE | ROTATED | REVOKED
    key_fingerprint VARCHAR(128) NOT NULL,                      -- SHA-256 fingerprint of public material
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    rotated_at      TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uk_tenant_key_alias UNIQUE (tenant_id, key_alias)
);

CREATE INDEX IF NOT EXISTS idx_tenant_key_status ON tenant_key_registry(tenant_id, key_status);

COMMENT ON TABLE tenant_key_registry IS
    'Cryptographic key registry for per-tenant envelope encryption. '
    'Key material is never stored here; only aliases and fingerprints.';
