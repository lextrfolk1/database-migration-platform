-- ============================================================================
-- V12: Link Attribute Catalog to Promotion Workflow Task (LP-44.1)
-- ============================================================================
-- Adds foreign key promotion_workflow_task_id to meta.attribute_catalog
-- linking promoted report-local derived attributes to the governance approval task
-- in wkfl.workflow_task (of type ATTRIBUTE_PROMOTION).
-- ============================================================================

ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS promotion_workflow_task_id bigint
        REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL;

COMMENT ON COLUMN meta.attribute_catalog.promotion_workflow_task_id IS
    'Foreign key reference to the governance approval task (wkfl.workflow_task of type ATTRIBUTE_PROMOTION) managing promotion approval.';

CREATE INDEX IF NOT EXISTS ix_ac_promotion_workflow
    ON meta.attribute_catalog (promotion_workflow_task_id);

COMMENT ON COLUMN wkfl.workflow_task.task_type_cd IS
    'Task classification: OBJECT_REGISTRATION | ATTRIBUTE_OVERRIDE | ATTRIBUTE_PAIRING | RELATIONSHIP_REGISTRATION | FILTER_LOOKUP | CONSUMPTION_PROMOTION | ATTRIBUTE_PROMOTION.';
