-- =============================================================================
-- V33: model_registry dataset lineage (LP-39.1, migration _02)
-- =============================================================================
-- The ONLY change to an applied baseline table in LP-39, split out so this
-- CONTRACT change is separately approvable. Two additive NULLABLE columns: a
-- base model honestly carries no dataset. NO foreign key, deliberately: a
-- constraint on an applied, seeded baseline table is a new failure mode for
-- every existing writer, in exchange for integrity the service already asserts.
-- =============================================================================

ALTER TABLE intelligence.model_registry
    ADD COLUMN IF NOT EXISTS trained_on_dataset_id      bigint,
    ADD COLUMN IF NOT EXISTS trained_on_dataset_version integer;
