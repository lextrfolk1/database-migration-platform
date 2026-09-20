-- =====================================================================
-- Migration: V20260916_01__lp12_preset_operational_axis_partial_unique.sql
-- Sub-task: LP-12.1 — Preset Management (Operational Axis Partial Uniqueness)
-- 
-- Constraint:
-- Ensures at most ONE operational preset per (client_id, task, report_type) axis.
-- Uses PostgreSQL 16 `NULLS NOT DISTINCT` so that report-agnostic presets
-- (report_type IS NULL) are properly deduplicated and enforced per task.
-- =====================================================================

CREATE UNIQUE INDEX preset_operational_axis_uq 
    ON intelligence.preset (client_id, task, report_type) 
    NULLS NOT DISTINCT 
    WHERE status = 'operational';

COMMENT ON INDEX intelligence.preset_operational_axis_uq IS 
    'Enforces at most one operational preset per (client_id, task, report_type) axis with NULLS NOT DISTINCT for report-agnostic rows.';
