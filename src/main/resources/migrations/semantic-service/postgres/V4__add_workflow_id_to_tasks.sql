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
