-- ============================================================================
-- V16: Attribute Promotion Provenance Schema & Workflow Task Types (LP-44.1)
-- ============================================================================
-- Adds provenance tracking columns to meta.attribute_catalog for promoted
-- report-local derived attributes (Lextr Intelligence UC10) and documents
-- the ATTRIBUTE_PROMOTION workflow task type in wkfl.workflow_task.
-- ============================================================================

ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS provenance_type_cd         varchar(40) DEFAULT 'GOVERNED_NATIVE',
    ADD COLUMN IF NOT EXISTS origin_report_id           varchar(120),
    ADD COLUMN IF NOT EXISTS origin_expression_txt       text,
    ADD COLUMN IF NOT EXISTS promoted_ts                timestamptz,
    ADD COLUMN IF NOT EXISTS promoted_by                varchar(100),
    ADD COLUMN IF NOT EXISTS promotion_workflow_task_id bigint
        REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL;

COMMENT ON COLUMN meta.attribute_catalog.provenance_type_cd IS
    'Provenance origin category: GOVERNED_NATIVE (catalog default) | REPORT_LOCAL_PROMOTED (derived analyst attribute promoted from report context) | SYSTEM_DERIVED.';

COMMENT ON COLUMN meta.attribute_catalog.origin_report_id IS
    'Reference identifier of the originating report (Lextr Intelligence UC10) from which this derived attribute was promoted.';

COMMENT ON COLUMN meta.attribute_catalog.origin_expression_txt IS
    'Formula / derivation expression text grounded on Semantic Layer attributes used in the analyst report before promotion.';

COMMENT ON COLUMN meta.attribute_catalog.promoted_ts IS
    'Timestamp when the promotion workflow was completed and attribute definition became governed catalog invariant.';

COMMENT ON COLUMN meta.attribute_catalog.promoted_by IS
    'User identity / actor who initiated or authorized the promotion of this attribute into the governed catalog.';

COMMENT ON COLUMN meta.attribute_catalog.promotion_workflow_task_id IS
    'Foreign key reference to the governance approval task (wkfl.workflow_task of type ATTRIBUTE_PROMOTION) managing promotion approval.';

CREATE INDEX IF NOT EXISTS ix_ac_provenance
    ON meta.attribute_catalog (provenance_type_cd);

CREATE INDEX IF NOT EXISTS ix_ac_promotion_workflow
    ON meta.attribute_catalog (promotion_workflow_task_id);

COMMENT ON COLUMN wkfl.workflow_task.task_type_cd IS
    'Task classification: OBJECT_REGISTRATION | ATTRIBUTE_OVERRIDE | ATTRIBUTE_PAIRING | RELATIONSHIP_REGISTRATION | FILTER_LOOKUP | CONSUMPTION_PROMOTION | ATTRIBUTE_PROMOTION.';
