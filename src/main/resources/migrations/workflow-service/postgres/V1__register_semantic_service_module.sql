-- Registers semantic-service as a consumer of workflow-service's existing
-- meta.module_master / meta.workflow_master / meta.workflow_module_map reference tables,
-- mirroring how SUPPLEMENTAL_UPLOAD (module 1, workflow_code SUPP) and rules_service
-- (module 2, workflow_code RULES) are already registered.
--
-- These tables belong to workflow-service (not semantic-service) but live in the same
-- shared postgres-main-dev database. This migration only INSERTs reference rows - it does
-- not alter workflow-service's schema or code. All statements are idempotent so re-running
-- this migration (or applying it to an environment where it was manually seeded) is safe.

-- The existing SUPP/RULES seed rows were inserted with explicit ids, leaving these sequences
-- behind the actual max(id) - resync them first so subsequent nextval()-driven inserts here
-- (and by any other future consumer of these tables) don't collide with existing rows.
SELECT setval('meta.module_master_id_seq', GREATEST((SELECT MAX(id) FROM meta.module_master), 1), true);
SELECT setval('meta.workflow_master_id_seq', GREATEST((SELECT MAX(id) FROM meta.workflow_master), 1), true);

INSERT INTO meta.module_master (id, module_name)
SELECT 3, 'semantic_governance'
WHERE NOT EXISTS (SELECT 1 FROM meta.module_master WHERE id = 3);

-- One workflow_master row per semantic-service workflow-code (see
-- config-service semantic-service-*.yml workflow.semantic.tasks.*.workflow-code), all backed
-- by the existing "two_stage_approval_workflow" JSON definition already served by
-- workflow-service's GET /workflow-metadata (verified live 2026-07-12; no single-stage
-- workflow is registered there, so every semantic-service task type uses the two-stage flow).
INSERT INTO meta.workflow_master (workflow_code, workflow_name, workflow_description, created_by, updated_by)
SELECT v.workflow_code, v.workflow_name, v.workflow_description, 'semantic-service-migration', 'semantic-service-migration'
FROM (VALUES
    ('sem_lookup', 'two_stage_approval_workflow', 'Semantic filter lookup registration approval'),
    ('sem_override', 'two_stage_approval_workflow', 'Semantic attribute logical name override approval'),
    ('sem_value', 'two_stage_approval_workflow', 'Semantic filter lookup value approval'),
    ('sem_obj', 'two_stage_approval_workflow', 'Semantic object registration approval'),
    ('sem_pair', 'two_stage_approval_workflow', 'Semantic attribute pairing registration approval'),
    ('sem_rel', 'two_stage_approval_workflow', 'Semantic relationship registration approval'),
    ('sem_dq_rule', 'two_stage_approval_workflow', 'Semantic DQ rule request approval'),
    ('sem_consumption', 'two_stage_approval_workflow', 'Semantic consumption promotion approval')
) AS v(workflow_code, workflow_name, workflow_description)
WHERE NOT EXISTS (SELECT 1 FROM meta.workflow_master wm WHERE wm.workflow_code = v.workflow_code);

INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
SELECT wm.id, 3
FROM meta.workflow_master wm
WHERE wm.workflow_code IN ('sem_lookup', 'sem_override', 'sem_value', 'sem_obj', 'sem_pair', 'sem_rel', 'sem_dq_rule', 'sem_consumption')
  AND NOT EXISTS (
      SELECT 1 FROM meta.workflow_module_map wmm
      WHERE wmm.workflow_master_id = wm.id AND wmm.module_master_id = 3
  );
