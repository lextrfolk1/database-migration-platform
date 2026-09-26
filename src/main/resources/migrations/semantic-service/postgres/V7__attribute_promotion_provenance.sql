-- =============================================================================
-- V7 — Attribute Promotion Provenance & Governance (LP-44.1)
-- =============================================================================
-- Additive provenance columns on meta.attribute_catalog for report-local
-- derived attributes promoted into the governed semantic layer catalog.
-- Four-eyes approval task support for wkfl.workflow_task ATTRIBUTE_PROMOTION.
-- =============================================================================

-- 1. Additive provenance columns on meta.attribute_catalog
ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS source_expression_txt  text,
    ADD COLUMN IF NOT EXISTS derivation_formula_txt text,
    ADD COLUMN IF NOT EXISTS derivation_type_cd     varchar(30) DEFAULT 'DIRECT',
    ADD COLUMN IF NOT EXISTS provenance_type_cd     varchar(30) DEFAULT 'SYSTEM',
    ADD COLUMN IF NOT EXISTS promoted_from_ref      varchar(100),
    ADD COLUMN IF NOT EXISTS promoted_ts           timestamptz,
    ADD COLUMN IF NOT EXISTS promoted_by           varchar(100);

ALTER TABLE meta.attribute_catalog
    DROP CONSTRAINT IF EXISTS ck_ac_derivation_type,
    ADD CONSTRAINT ck_ac_derivation_type CHECK (derivation_type_cd IS NULL OR derivation_type_cd IN ('DIRECT','DERIVED','CALCULATED','AGGREGATED'));

ALTER TABLE meta.attribute_catalog
    DROP CONSTRAINT IF EXISTS ck_ac_provenance_type,
    ADD CONSTRAINT ck_ac_provenance_type CHECK (provenance_type_cd IS NULL OR provenance_type_cd IN ('SYSTEM','USER_PROMOTED','AI_INFERRED'));

CREATE INDEX IF NOT EXISTS ix_ac_provenance_type ON meta.attribute_catalog (provenance_type_cd);
CREATE INDEX IF NOT EXISTS ix_ac_promoted_from_ref ON meta.attribute_catalog (promoted_from_ref);

-- 2. Governance policy presets for attribute promotion
INSERT INTO governance.policy_preset (
    policy_cd, policy_nm, policy_scope_cd, default_value_txt, data_type_cd, is_overrideable_flg, override_requires_approval_flg
) VALUES
    ('ATTRIBUTE_PROMOTION_REQUIRES_APPROVAL', 'Attribute Promotion Requires Four-Eyes Approval', 'GLOBAL', 'true', 'BOOLEAN', true, true),
    ('ATTRIBUTE_PROMOTION_AUTO_GOVERN', 'Attribute Promotion Auto Govern On Approval', 'GLOBAL', 'true', 'BOOLEAN', true, false)
ON CONFLICT (policy_cd) DO NOTHING;
