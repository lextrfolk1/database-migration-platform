-- Insert for two_stage_approval_workflow
INSERT INTO meta.workflow_metadata (workflow_name, workflow_json, created_by, status)
VALUES
(
  'two_stage_approval_workflow',
  '{
     "endStates": [
       "APPROVED",
       "REJECTED",
       "DISCARD"
     ],
     "transitions": {
       "DRAFT": {
         "actions": {
           "discard": "DISCARD",
           "submit": "PENDING_APPROVAL"
         }
       },
       "PENDING_APPROVAL": {
         "actions": {
           "reject": "REJECTED",
           "approve": "APPROVED"
         }
       }
     },
     "initialStage": "DRAFT"
   }'::jsonb,
  current_user,
  'active'
);

-- Insert for iterative_two_stage_approval_workflow
INSERT INTO meta.workflow_metadata (workflow_name, workflow_json, created_by, status)
VALUES
(
  'iterative_two_stage_approval_workflow',
  '{
     "endStates": [
       "APPROVED",
       "REJECTED",
       "DISCARD"
     ],
     "transitions": {
       "DRAFT": {
         "actions": {
           "discard": "DISCARD",
           "submit": "PENDING_APPROVAL"
         }
       },
       "PENDING_APPROVAL": {
         "actions": {
           "reject": "REJECTED",
           "approve": "APPROVED",
           "sendback": "DRAFT",
           "recall": "DRAFT"
         }
       }
     },
     "initialStage": "DRAFT"
   }'::jsonb,
  current_user,
  'active'
);

-- Insert into workflow_master
INSERT INTO meta.workflow_master (id, workflow_code, workflow_name, workflow_description, created_on, created_by, updated_on, updated_by)
VALUES (
  1,
  'supp',
  'supp_workflow',
  'Workflow for supplemental upload',
  now(),
  'system',
  now(),
  'system'
);

-- Insert into module_master
INSERT INTO meta.module_master (id, module_name)
VALUES (1, 'supplemental_upload');

-- Insert into workflow_module_map
INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
VALUES (1, 1);
