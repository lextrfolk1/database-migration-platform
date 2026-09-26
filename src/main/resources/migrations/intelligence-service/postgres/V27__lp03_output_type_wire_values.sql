-- =============================================================================
-- V27: /run wire output types on intelligence.output_type (LP-03.2 / LP-03.3)
-- =============================================================================
-- The /run contract's additive vocabulary (narrative, narrative+dataset,
-- needs_input, route_out, driver_breakdown) is persisted into agent_run.output_type
-- and preset.output_type via CAST(:output_type AS intelligence.output_type).
-- Four of those values were missing from the enum, so persisting such a run
-- failed with "invalid input value for enum". Additive, same pattern as V9.
-- =============================================================================

ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'narrative_dataset';
ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'needs_input';
ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'route_out';
ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'driver_breakdown';
