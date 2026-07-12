ALTER TABLE wkfl.workflow_task
    ADD COLUMN IF NOT EXISTS workflow_id bigint;

COMMENT ON COLUMN wkfl.workflow_task.workflow_id IS
    'Identifier of the corresponding workflow instance in the external workflow-service. Nullable: tasks created before this migration, or tasks whose workflow-service registration failed, will have no value.';
