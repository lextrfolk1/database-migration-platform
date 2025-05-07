
INSERT INTO meta.rule_type (rule_type, rule_type_name, created_on, created_by, updated_on, updated_by)
VALUES (1, 'R1', now(), 'system', now(), 'system');


-- Workflow Metadata

INSERT INTO meta.module_master (id, module_name) VALUES (2, 'rules_service');
INSERT INTO meta.workflow_master (id, workflow_code, workflow_name, workflow_description, created_on, created_by, updated_on, updated_by)
VALUES (2, 'rules', 'two_stage_approval_workflow', 'Workflow for Rules', now(), 'SYSTEM', now(), 'SYSTEM');

INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
VALUES (2, 2);