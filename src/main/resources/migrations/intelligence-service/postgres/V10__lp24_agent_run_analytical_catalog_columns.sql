-- LP-24.2 Split 2: Add catalog_state, route_out_uc, catalog_profile to intelligence.agent_run
-- Enforces 2 scoped CHECK constraints and 1 partial index. All names <= 32 chars.

ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS catalog_state VARCHAR(32),
    ADD COLUMN IF NOT EXISTS route_out_uc VARCHAR(32),
    ADD COLUMN IF NOT EXISTS catalog_profile VARCHAR(32);

-- Scoped CHECK constraints
ALTER TABLE intelligence.agent_run
    DROP CONSTRAINT IF EXISTS chk_agent_run_catalog_state,
    ADD CONSTRAINT chk_agent_run_catalog_state
        CHECK (catalog_state IS NULL OR catalog_state IN ('MATCHED', 'NO_MATCH_IN_INVENTORY', 'CATALOG_NOT_READY'));

ALTER TABLE intelligence.agent_run
    DROP CONSTRAINT IF EXISTS chk_agent_run_catalog_profile,
    ADD CONSTRAINT chk_agent_run_catalog_profile
        CHECK (catalog_profile IS NULL OR catalog_profile IN ('RICH', 'STRUCTURE_ONLY', 'DEFAULT'));

-- Partial index for analytical assist catalog discovery runs
CREATE INDEX IF NOT EXISTS idx_agent_run_analytical_cat
    ON intelligence.agent_run (client_id, use_case, catalog_state)
    WHERE use_case = 'UC10';

-- Comments
COMMENT ON COLUMN intelligence.agent_run.catalog_state IS 'UC10 discovery state: MATCHED, NO_MATCH_IN_INVENTORY, CATALOG_NOT_READY';
COMMENT ON COLUMN intelligence.agent_run.route_out_uc IS 'UC10 route out destination use case (e.g. UC1, UC3, UC12)';
COMMENT ON COLUMN intelligence.agent_run.catalog_profile IS 'UC10 catalog profile: RICH, STRUCTURE_ONLY, DEFAULT';
