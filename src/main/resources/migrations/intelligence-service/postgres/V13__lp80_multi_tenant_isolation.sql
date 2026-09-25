-- Lextr Intelligence Platform — Multi-Tenant Schema Isolation (LP-80.1)

CREATE TABLE IF NOT EXISTS intelligence.tenant_profile (
    tenant_id VARCHAR(64) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    tier VARCHAR(32) NOT NULL DEFAULT 'ENTERPRISE',
    isolation_level VARCHAR(32) NOT NULL DEFAULT 'ROW_LEVEL_SECURITY',
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    config_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS intelligence.tenant_membership (
    membership_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL REFERENCES intelligence.tenant_profile(tenant_id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL,
    assigned_role VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_tenant_user UNIQUE (tenant_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_tenant_profile_status ON intelligence.tenant_profile(status);
CREATE INDEX IF NOT EXISTS idx_tenant_membership_user ON intelligence.tenant_membership(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_membership_tenant ON intelligence.tenant_membership(tenant_id);

-- Seed platform and initial client tenant profiles for foreign-key integrity in dependent tables
INSERT INTO intelligence.tenant_profile (tenant_id, org_name, tier, isolation_level, status)
VALUES 
    ('__platform__', 'Lextr Platform System', 'SYSTEM', 'ROW_LEVEL_SECURITY', 'ACTIVE'),
    ('client_001', 'Lextr Enterprise Client 001', 'ENTERPRISE', 'ROW_LEVEL_SECURITY', 'ACTIVE')
ON CONFLICT (tenant_id) DO NOTHING;
