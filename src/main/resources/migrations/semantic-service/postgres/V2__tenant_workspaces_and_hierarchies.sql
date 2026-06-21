-- =============================================================================
-- V2 — Tenant Workspaces & Logical Hierarchies
-- =============================================================================
-- Adds tables to store workspace and hierarchy definitions that were previously
-- hardcoded in frontend catalogConfig.ts (TENANT_WORKSPACES, HIERARCHIES).
-- =============================================================================

-- ============================================================================
-- meta.tenant_workspace — tenant workspace descriptors
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.tenant_workspace (
    id                   bigserial    PRIMARY KEY,
    workspace_cd         varchar(60)  NOT NULL UNIQUE,
    tenant_cd            varchar(40)  NOT NULL,            -- e.g. 'GLOBAL', 'BHC_A001'
    workspace_nm         varchar(200) NOT NULL,
    workspace_desc       text,
    workspace_status_cd  varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    created_by           varchar(100) NOT NULL DEFAULT current_user,
    created_ts           timestamptz  NOT NULL DEFAULT now(),
    updated_by           varchar(100),
    updated_ts           timestamptz,
    CONSTRAINT ck_tw_status CHECK (workspace_status_cd IN
        ('ACTIVE','REVIEW','INACTIVE','ARCHIVED'))
);
CREATE INDEX IF NOT EXISTS ix_tw_tenant ON meta.tenant_workspace (tenant_cd);
CREATE INDEX IF NOT EXISTS ix_tw_status ON meta.tenant_workspace (workspace_status_cd);

-- ============================================================================
-- meta.workspace_object — maps registered objects to workspace directories
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.workspace_object (
    id                   bigserial    PRIMARY KEY,
    workspace_cd         varchar(60)  NOT NULL
        REFERENCES meta.tenant_workspace (workspace_cd) ON DELETE CASCADE,
    schema_cd            varchar(30)  NOT NULL,
    object_cd            varchar(50)  NOT NULL,
    added_by             varchar(100) NOT NULL DEFAULT current_user,
    added_ts             timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_wo UNIQUE (workspace_cd, schema_cd, object_cd)
);
CREATE INDEX IF NOT EXISTS ix_wo_workspace ON meta.workspace_object (workspace_cd);

-- ============================================================================
-- meta.logical_hierarchy — hierarchy descriptors
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.logical_hierarchy (
    id                   bigserial    PRIMARY KEY,
    hierarchy_cd         varchar(60)  NOT NULL UNIQUE,
    hierarchy_nm         varchar(200) NOT NULL,
    tenant_cd            varchar(40)  NOT NULL DEFAULT 'GLOBAL',
    hierarchy_status_cd  varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    created_by           varchar(100) NOT NULL DEFAULT current_user,
    created_ts           timestamptz  NOT NULL DEFAULT now(),
    updated_by           varchar(100),
    updated_ts           timestamptz,
    CONSTRAINT ck_lh_status CHECK (hierarchy_status_cd IN
        ('ACTIVE','REVIEW','INACTIVE','ARCHIVED'))
);
CREATE INDEX IF NOT EXISTS ix_lh_tenant ON meta.logical_hierarchy (tenant_cd);

-- ============================================================================
-- meta.logical_hierarchy_level — multilevel attribute steps per hierarchy
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.logical_hierarchy_level (
    id                   bigserial    PRIMARY KEY,
    hierarchy_cd         varchar(60)  NOT NULL
        REFERENCES meta.logical_hierarchy (hierarchy_cd) ON DELETE CASCADE,
    level_nbr            integer      NOT NULL,
    level_label          varchar(100) NOT NULL,
    attribute_cd         varchar(32)  NOT NULL,
    code_cd              varchar(32)  NOT NULL,
    object_ref           varchar(120) NOT NULL,            -- schema.object
    CONSTRAINT uq_lhl UNIQUE (hierarchy_cd, level_nbr)
);
CREATE INDEX IF NOT EXISTS ix_lhl_hierarchy ON meta.logical_hierarchy_level (hierarchy_cd);

-- ============================================================================
-- SEED — workspaces (matching previous catalogConfig.ts TENANT_WORKSPACES)
-- ============================================================================
INSERT INTO meta.tenant_workspace (workspace_cd, tenant_cd, workspace_nm, workspace_desc, workspace_status_cd, created_by)
VALUES
    ('WS-ALL',   'GLOBAL',   'ALL (Global)',                      'Default global workspace — all tenants see these objects',                                     'ACTIVE', 'system'),
    ('WS-BHC-A', 'BHC_A001', 'BHC_A001 — Bank Holding Co Alpha', 'Tenant-specific workspace for BHC Alpha. Includes full GL scope plus customer master.',        'ACTIVE', 's.patel'),
    ('WS-BHC-B', 'BHC_B002', 'BHC_B002 — Bank Holding Co Beta',  'Beta tenant workspace. Restricted to organisation and period reference data pending onboarding.','REVIEW', 'j.chen')
ON CONFLICT (workspace_cd) DO NOTHING;

-- SEED — workspace objects
INSERT INTO meta.workspace_object (workspace_cd, schema_cd, object_cd, added_by) VALUES
    ('WS-ALL',   'core', 'gl_balance',              'system'),
    ('WS-ALL',   'ref',  'organization_hierarchy',  'system'),
    ('WS-ALL',   'ref',  'fiscal_period',           'system'),
    ('WS-BHC-A', 'core', 'gl_balance',              's.patel'),
    ('WS-BHC-A', 'core', 'customer_master',         's.patel'),
    ('WS-BHC-A', 'ref',  'organization_hierarchy',  's.patel'),
    ('WS-BHC-A', 'ref',  'fiscal_period',           's.patel'),
    ('WS-BHC-B', 'ref',  'organization_hierarchy',  'j.chen'),
    ('WS-BHC-B', 'ref',  'fiscal_period',           'j.chen')
ON CONFLICT (workspace_cd, schema_cd, object_cd) DO NOTHING;

-- SEED — hierarchies (matching previous catalogConfig.ts HIERARCHIES)
INSERT INTO meta.logical_hierarchy (hierarchy_cd, hierarchy_nm, tenant_cd, hierarchy_status_cd, created_by) VALUES
    ('ENTITY_HIERARCHY', 'Legal Entity Hierarchy',  'GLOBAL', 'ACTIVE', 'system'),
    ('PERIOD_HIERARCHY', 'Fiscal Period Hierarchy',  'GLOBAL', 'ACTIVE', 'system')
ON CONFLICT (hierarchy_cd) DO NOTHING;

-- SEED — hierarchy levels
INSERT INTO meta.logical_hierarchy_level (hierarchy_cd, level_nbr, level_label, attribute_cd, code_cd, object_ref) VALUES
    ('ENTITY_HIERARCHY', 1, 'Bank Holding Company', 'org_node_nm', 'org_node_cd', 'ref.organization_hierarchy'),
    ('ENTITY_HIERARCHY', 2, 'Bank / Subsidiary',    'org_node_nm', 'org_node_cd', 'ref.organization_hierarchy'),
    ('ENTITY_HIERARCHY', 3, 'Division / Region',    'org_node_nm', 'org_node_cd', 'ref.organization_hierarchy'),
    ('PERIOD_HIERARCHY', 1, 'Fiscal Year',          'fiscal_year_nbr', 'fiscal_year_nbr', 'ref.fiscal_period'),
    ('PERIOD_HIERARCHY', 2, 'Fiscal Period',        'period_cd',       'period_cd',       'ref.fiscal_period')
ON CONFLICT (hierarchy_cd, level_nbr) DO NOTHING;
