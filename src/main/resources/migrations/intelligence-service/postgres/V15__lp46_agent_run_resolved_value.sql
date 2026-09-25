-- ============================================================================
-- Migration: V15__lp46_agent_run_resolved_value.sql
-- Sub-task: LP-46.0 (SQL / Flyway)
-- Description: Table intelligence.agent_run_resolved_value was instantiated in
-- V2__uc10_resolved_value_provenance.sql. This migration confirms table presence
-- and ensures Part-M compliant indexes are in place without repeating table DDL.
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'intelligence' AND table_name = 'agent_run_resolved_value'
    ) THEN
        RAISE EXCEPTION 'Expected intelligence.agent_run_resolved_value to exist from V2';
    END IF;
END $$;

-- Verify/ensure primary step lookup index
CREATE INDEX IF NOT EXISTS idx_resolved_val_step
    ON intelligence.agent_run_resolved_value (client_id, run_id, step_number);

-- Verify/ensure partial index over ungoverned rows for audit and review sweeps
CREATE INDEX IF NOT EXISTS idx_resolved_val_ungoverned
    ON intelligence.agent_run_resolved_value (client_id, domain_key)
    WHERE resolution_basis != 'GOVERNED';
