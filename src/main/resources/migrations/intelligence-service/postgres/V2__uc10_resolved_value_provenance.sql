-- ============================================================================
-- Migration: V20260821_01__uc10_resolved_value_provenance.sql
-- Sub-task: LP-46.0 (SQL / Flyway)
-- Description: Child table intelligence.agent_run_resolved_value with 5 check
-- constraints encoding domain-value resolution semantics and ungoverned partial index.
-- ============================================================================

CREATE TABLE IF NOT EXISTS intelligence.agent_run_resolved_value (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    step_number INT NOT NULL,
    domain_key VARCHAR(64) NOT NULL,
    phrase TEXT NOT NULL,
    resolution_status VARCHAR(32) NOT NULL,
    resolved_value VARCHAR(128),
    resolution_basis VARCHAR(32) NOT NULL,
    domain_version VARCHAR(64),
    as_of_date DATE NOT NULL,
    effective_from DATE,
    effective_to DATE,
    candidates TEXT[],
    assumed_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',

    CONSTRAINT chk_res_status CHECK (
        resolution_status IN ('EXACT', 'AMBIGUOUS', 'UNRESOLVED')
    ),

    CONSTRAINT chk_res_basis CHECK (
        resolution_basis IN ('GOVERNED', 'HEURISTIC', 'ASSUMED', 'NONE')
    ),

    CONSTRAINT chk_governed_ver_date CHECK (
        resolution_basis != 'GOVERNED' OR (domain_version IS NOT NULL AND effective_from IS NOT NULL)
    ),

    CONSTRAINT chk_assumed_no_ver CHECK (
        resolution_basis != 'ASSUMED' OR domain_version IS NULL
    ),

    CONSTRAINT chk_ambiguous_spec CHECK (
        resolution_status != 'AMBIGUOUS' OR (resolved_value IS NULL AND array_length(candidates, 1) >= 2)
    ),

    CONSTRAINT chk_effective_window CHECK (
        effective_from IS NULL OR (as_of_date >= effective_from AND (effective_to IS NULL OR as_of_date <= effective_to))
    ),

    CONSTRAINT chk_unresolved_no_val CHECK (
        resolution_status != 'UNRESOLVED' OR resolved_value IS NULL
    )
);

CREATE INDEX IF NOT EXISTS idx_resolved_val_step
    ON intelligence.agent_run_resolved_value (client_id, run_id, step_number);

CREATE INDEX IF NOT EXISTS idx_resolved_val_ungoverned
    ON intelligence.agent_run_resolved_value (client_id, domain_key)
    WHERE resolution_basis != 'GOVERNED';
