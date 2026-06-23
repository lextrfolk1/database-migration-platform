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
-- SEED — register database schemas in schema_catalog (required by object_catalog FK)
-- ============================================================================
INSERT INTO meta.schema_catalog (schema_cd, schema_nm, schema_purpose_txt, client_id, lifecycle_status_cd) VALUES
  ('meta',       'Meta',       'Internal metadata schema',              'GLOBAL', 'ACTIVE'),
  ('data',       'Data',       'Primary data tables',                   'GLOBAL', 'ACTIVE'),
  ('ref',        'Ref',        'Reference and lookup data',             'GLOBAL', 'ACTIVE'),
  ('governance', 'Governance', 'Governance policies and presets',       'GLOBAL', 'ACTIVE'),
  ('report',     'Report',     'Regulatory report definitions',         'GLOBAL', 'ACTIVE'),
  ('wkfl',       'Workflow',   'Approval workflow tables',              'GLOBAL', 'ACTIVE'),
  ('public',     'Public',     'Default PostgreSQL public schema',      'GLOBAL', 'ACTIVE')
ON CONFLICT (schema_cd) DO NOTHING;
