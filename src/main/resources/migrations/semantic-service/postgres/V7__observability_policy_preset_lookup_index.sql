-- =============================================================================
-- V7 — Observability policy preset lookup index
-- =============================================================================
-- Supports DB-driven observability auto-trigger gating by making policy preset
-- lookups on scope, code, and effective date efficient.
-- =============================================================================

CREATE INDEX IF NOT EXISTS ix_pp_scope_code_effective
    ON governance.policy_preset (policy_scope_cd, policy_cd, effective_from_dt DESC, effective_to_dt);
