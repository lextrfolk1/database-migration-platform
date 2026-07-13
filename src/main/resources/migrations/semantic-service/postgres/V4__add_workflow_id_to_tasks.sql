ALTER TABLE wkfl.workflow_task
    ADD COLUMN IF NOT EXISTS workflow_id bigint;

COMMENT ON COLUMN wkfl.workflow_task.workflow_id IS
    'Identifier of the corresponding workflow instance in the external workflow-service. Nullable: tasks created before this migration, or tasks whose workflow-service registration failed, will have no value.';


-- Registration flows (Object, AttributePairing, Relationship, FilterLookup) now create a
-- wkfl.workflow_task row even for draft-only submissions, so a workflow instance and Audit
-- trail entry exist from the moment the draft is saved (matching the "two_stage_approval_workflow"
-- JSON's real initial stage, DRAFT - verified live 2026-07-12). The existing CHECK constraint
-- only allowed PENDING/APPROVED/REJECTED/CANCELLED; widen it to also allow DRAFT.
--
-- Draft-status tasks are not surfaced in the approval queue (WorkflowTaskController's
-- workflow_task.find_all is filtered client-side to PENDING by the queue UI) and cannot be
-- approved/rejected via the existing endpoints (WorkflowApprovalServiceImpl.isPendingTask only
-- treats PENDING/PENDING_APPROVAL as actionable) until a future "submit draft" transition is
-- added - that is a separate, not-yet-built feature.

ALTER TABLE wkfl.workflow_task DROP CONSTRAINT ck_wt_status;

ALTER TABLE wkfl.workflow_task
    ADD CONSTRAINT ck_wt_status CHECK (task_status_cd IN ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'));

-- Re-saving the same draft repeatedly used to insert a brand new wkfl.workflow_task row and mint
-- a brand new workflow-service workflow every time. The application layer now looks up any
-- existing non-terminal (DRAFT/PENDING) task for the same entity before deciding whether to
-- insert or update; this index makes that lookup efficient.

CREATE INDEX IF NOT EXISTS ix_wt_entity_lookup
    ON wkfl.workflow_task (client_id, entity_type_cd, entity_ref, task_status_cd);

-- Rejected objects must persist as a real, distinct record (not silently reverted back to DRAFT)
-- so the Workflow grid's audit trail is accurate, while being excluded from the Data Catalog and
-- every other object-picker screen (Relationship, Filter Lookup, Attribute Pairing, etc.) - those
-- all read through ObjectExposureReadServiceImpl.findObjects, which defaults to APPROVED-only.
-- REJECTED was never a legal value for lifecycle_status_cd, which is why the application
-- previously had to fake it by reverting to DRAFT; widen the constraint so it can be the real,
-- honest value.

ALTER TABLE meta.object_catalog DROP CONSTRAINT ck_ob_lifecycle;

ALTER TABLE meta.object_catalog
    ADD CONSTRAINT ck_ob_lifecycle CHECK (lifecycle_status_cd IN
        ('DRAFT','REVIEW','APPROVED','ACTIVE','DEPRECATED','RETIRED','REJECTED'));
