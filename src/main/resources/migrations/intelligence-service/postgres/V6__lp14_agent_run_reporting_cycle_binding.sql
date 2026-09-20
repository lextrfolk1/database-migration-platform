-- ============================================================================
-- Migration: V20260916_03__lp14_agent_run_reporting_cycle_binding.sql
-- Sub-task: LP-14.0 (SQL / Flyway)
-- Description: Add optional cycle_id foreign key on intelligence.agent_run.
-- A run row carrying no cycle reads as UNBOUND on every read path, never defaulted.
-- ============================================================================

ALTER TABLE intelligence.agent_run
ADD COLUMN IF NOT EXISTS cycle_id BIGINT REFERENCES intelligence.reporting_cycle(id);

CREATE INDEX IF NOT EXISTS agent_run_cycle_idx ON intelligence.agent_run (client_id, cycle_id);
