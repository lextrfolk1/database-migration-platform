-- =============================================================================
-- V9 — Attribute Catalog Extended Authoring & Governance (LP-03 / LP-31)
-- =============================================================================
-- Adds missing multi-tenancy (client_id), semantic role, element class (CDE/DE),
-- domain authoring, operational lifecycle modes, and effective dating columns
-- to meta.attribute_catalog.
-- =============================================================================

-- 1. Multi-tenancy, Element Class, Domain & Operational Metadata
ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS client_id                  varchar(40) DEFAULT 'GLOBAL',
    ADD COLUMN IF NOT EXISTS semantic_role_cd           varchar(30),
    ADD COLUMN IF NOT EXISTS semantic_enabled_flg       boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ai_exposed_flg             boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS element_class_cd           varchar(30),
    ADD COLUMN IF NOT EXISTS element_class_source_cd    varchar(30),
    ADD COLUMN IF NOT EXISTS domain_mode_cd             varchar(30) NOT NULL DEFAULT 'NONE',
    ADD COLUMN IF NOT EXISTS domain_values_jsonb        jsonb,
    ADD COLUMN IF NOT EXISTS domain_ref_table_nm        varchar(100),
    ADD COLUMN IF NOT EXISTS domain_ref_code_col        varchar(100),
    ADD COLUMN IF NOT EXISTS domain_ref_desc_col        varchar(100),
    ADD COLUMN IF NOT EXISTS insert_mode_cd             varchar(30),
    ADD COLUMN IF NOT EXISTS update_mode_cd             varchar(30),
    ADD COLUMN IF NOT EXISTS delete_mode_cd             varchar(30),
    ADD COLUMN IF NOT EXISTS immutable_flg              boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS null_on_insert_flg         boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS attr_source_system_cd      varchar(50),
    ADD COLUMN IF NOT EXISTS effective_start_dt         date,
    ADD COLUMN IF NOT EXISTS effective_end_dt           date;

-- 2. Backfill client_id from parent object_catalog for existing attributes
UPDATE meta.attribute_catalog a
SET client_id = COALESCE(o.client_id, 'GLOBAL')
FROM meta.object_catalog o
WHERE a.schema_cd = o.schema_cd AND a.object_cd = o.object_cd
  AND a.client_id IS NULL;

-- 3. Constraints
ALTER TABLE meta.attribute_catalog
    DROP CONSTRAINT IF EXISTS ck_ac_element_class,
    ADD CONSTRAINT ck_ac_element_class CHECK (element_class_cd IS NULL OR element_class_cd IN ('CDE', 'DE'));

ALTER TABLE meta.attribute_catalog
    DROP CONSTRAINT IF EXISTS ck_ac_domain_mode,
    ADD CONSTRAINT ck_ac_domain_mode CHECK (domain_mode_cd IS NULL OR domain_mode_cd IN ('NONE', 'YN_FLAG', 'ENUM_LIST', 'REF_DOMAIN'));

-- 4. Indexes
CREATE INDEX IF NOT EXISTS ix_ac_client ON meta.attribute_catalog (client_id);
CREATE INDEX IF NOT EXISTS ix_ac_element_class ON meta.attribute_catalog (element_class_cd);
CREATE INDEX IF NOT EXISTS ix_ac_domain_mode ON meta.attribute_catalog (domain_mode_cd);
CREATE INDEX IF NOT EXISTS ix_ac_semantic_role ON meta.attribute_catalog (semantic_role_cd);
