-- ============================================================================
-- Migration: V20260916_04__lp19_agent_run_rerun_audit.sql
-- Sub-task:  LP-19.2 (SQL / Flyway)
-- Description:
--   Adds the additive, nullable rerun_audit (jsonb) column to intelligence.agent_run.
--   This column records the CHANGE between the preset resolved for a re-run and the
--   preset used by the original run — it records a DIFFERENCE, not a preset snapshot.
--   Absence (null) is the legitimate state for every run that pre-dates a re-run.
--
-- DECISION: parent_run_id column ALREADY EXISTS on agent_run and has a declared
--   meaning: "senior-mgmt synthesis -> analyst run (1:1 drill-down)".
--   Re-run lineage is a SECOND meaning on the same column; overloading it
--   makes "the parent of this run" unanswerable (each meaning is individually correct).
--   This migration does NOT repurpose parent_run_id; that requires a schema-owner
--   proposal (B3 territory). Instead, rerun_lineage_run_id is introduced as a
--   SEPARATE, nullable FK column — the FK is named to make the relationship readable
--   in any query plan, and is NULLABLE so pre-existing rows carry no lineage debt.
--   This resolves the ambiguity before LP-19.3 writes the first re-run row.
--
-- INVARIANTS:
--   1. Additive only — no DROP, no backfill, no DEFAULT that would mutate existing rows.
--   2. rerun_audit is nullable: absence is a real state (not error) for original runs.
--   3. rerun_lineage_run_id FK references the re-run's ORIGINAL run (not the same table
--      as parent_run_id), so the graph is walked forward from origin to re-runs.
--   4. Migration is idempotent: IF NOT EXISTS guards protect repeated execution.
--   5. SEPARATE INDEX on rerun_lineage_run_id for the bounded lineage walk query.
-- ============================================================================

-- 1. Add rerun_audit jsonb (nullable — absence is the pre-rerun state, no backfill)
ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS rerun_audit jsonb;

-- 2. Add rerun_lineage_run_id — separate, unambiguous FK for re-run chain lineage.
--    DECISION: parent_run_id was NOT repurposed because it already has a committed
--    semantic (drill-down synthesis). Adding a second FK here is the minimum change
--    to make the lineage unambiguous; the alternative (discriminator on parent_run_id)
--    is a schema-owner proposal and was not applied here.
ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS rerun_lineage_run_id bigint
        REFERENCES intelligence.agent_run (id);

-- 3. Sparse index (WHERE NOT NULL) — lineage chain reads target only re-run rows.
--    A partial index avoids a full-table scan on the many NULL rows.
CREATE INDEX IF NOT EXISTS agent_run_rerun_lineage_idx
    ON intelligence.agent_run (rerun_lineage_run_id)
    WHERE rerun_lineage_run_id IS NOT NULL;

-- 4. Comments — declare decisions so a reader six months from now does not "fix" the shape.
COMMENT ON COLUMN intelligence.agent_run.rerun_audit IS
    'Jsonb recording the CHANGE between the preset resolved for this re-run and the '
    'original run preset. NULL for any run that is not itself a re-run (pre-existing rows, '
    'original runs). Schema: {"preset_changed": bool, "original_preset_id": bigint, '
    '"original_preset_version": int, "new_preset_id": bigint, "new_preset_version": int, '
    '"changed_keys": [string]}. A re-run under the same preset stores preset_changed=false '
    'so the two states are always distinguishable. Added LP-19.2.';

COMMENT ON COLUMN intelligence.agent_run.rerun_lineage_run_id IS
    'FK to the immediate parent agent_run.id in a re-run chain. NULL for original runs. '
    'parent_run_id carries a different semantic (senior-mgmt synthesis -> analyst drill-down) '
    'and is NOT used for re-run lineage to avoid overloading a committed meaning. '
    'Added LP-19.2.';
