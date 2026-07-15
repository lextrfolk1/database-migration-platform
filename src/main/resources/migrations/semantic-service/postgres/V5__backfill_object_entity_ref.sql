-- Backfills wkfl.workflow_task.entity_ref and meta.metadata_change_history.entity_ref for
-- entity_type_cd = 'OBJECT' rows written before the object-id wire-format change (fake
-- md5-hash-cast-to-uuid -> real meta.object_catalog.id bigint). Only OBJECT-type rows are
-- affected: RELATIONSHIP uses its own separate, unaffected deterministic UUID
-- (uuid_generate_v3-style hash of relationship_cd), and PAIRING/FILTER_LOOKUP/DQ_RULE_REQUEST/
-- CONSUMPTION_PROMOTE/LOGICAL_NAME_OVERRIDE already store a plain business code as entity_ref.
--
-- Without this backfill, any OBJECT-type workflow_task/metadata_change_history row written
-- before the cutover keeps the old md5-hash-string entity_ref, while the application starts
-- writing/looking up the new bigint-string form immediately after deploy - breaking "resume my
-- existing draft" lookups (object_registration.find_active_workflow_task) and audit-trail joins
-- (governance_history.find_by_entity) for any object registered before this migration runs.

UPDATE wkfl.workflow_task wt
SET entity_ref = oc.id::text
FROM meta.object_catalog oc
WHERE wt.entity_type_cd = 'OBJECT'
  AND wt.entity_ref = CAST(md5(oc.schema_cd || '/' || oc.object_cd) AS uuid)::text;

UPDATE meta.metadata_change_history mch
SET entity_ref = oc.id::text
FROM meta.object_catalog oc
WHERE mch.entity_type_cd = 'OBJECT'
  AND mch.entity_ref = CAST(md5(oc.schema_cd || '/' || oc.object_cd) AS uuid)::text;
