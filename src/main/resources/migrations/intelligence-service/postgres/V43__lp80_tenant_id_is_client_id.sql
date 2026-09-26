-- =============================================================================
-- V43: one tenant identifier - client_id (owner decision 2026-09-25)
-- =============================================================================
-- V14 added tenant_id to agent_run, agent_run_step, preset and
-- registered_definition as a copy of client_id (backfilled SET tenant_id =
-- client_id; tenant_profile is keyed by the same ids, e.g. 'client_001'). No
-- statement reads or filters on it - every query scopes by client_id, V1's
-- tenancy key - so the second column could only ever drift.
--
-- agent_run, preset, registered_definition: tenant_id is DROPPED. Its useful
-- half, the foreign key into tenant_profile, moves onto client_id, so a row for
-- an unregistered tenant is still refused. V14's policies on these three tables
-- read tenant_id and were already inactive (V42), so they go with it.
--
-- agent_run_step: tenant_id is KEPT. Every evidence row's content_hash is
-- sha256(to_jsonb(row) - chain columns) (V36), so the column is inside the hash
-- of every chained row; dropping it would stop an auditor re-deriving those
-- hashes. It is locked to client_id instead, so it can never say anything else.
-- =============================================================================

-- ---------------------------------------------------------------- agent_run
DROP POLICY IF EXISTS rls_agent_run_select ON intelligence.agent_run;
DROP POLICY IF EXISTS rls_agent_run_insert ON intelligence.agent_run;
DROP POLICY IF EXISTS rls_agent_run_update ON intelligence.agent_run;
ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT fk_agent_run_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT;
ALTER TABLE intelligence.agent_run DROP COLUMN tenant_id;   -- takes fk_agent_run_tenant, idx_agent_run_tenant

-- ---------------------------------------------------------------- preset
DROP POLICY IF EXISTS rls_preset_select ON intelligence.preset;
DROP POLICY IF EXISTS rls_preset_insert ON intelligence.preset;
DROP POLICY IF EXISTS rls_preset_update ON intelligence.preset;
ALTER TABLE intelligence.preset
    ADD CONSTRAINT fk_preset_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT;
ALTER TABLE intelligence.preset DROP COLUMN tenant_id;      -- takes fk_preset_tenant, idx_preset_tenant

-- ---------------------------------------------------------------- registered_definition
DROP POLICY IF EXISTS rls_regdef_select ON intelligence.registered_definition;
DROP POLICY IF EXISTS rls_regdef_insert ON intelligence.registered_definition;
ALTER TABLE intelligence.registered_definition
    ADD CONSTRAINT fk_registered_def_client_tenant FOREIGN KEY (client_id)
        REFERENCES intelligence.tenant_profile (tenant_id) ON DELETE RESTRICT;
ALTER TABLE intelligence.registered_definition DROP COLUMN tenant_id;  -- takes fk_registered_def_tenant, idx_registered_def_tenant

-- ---------------------------------------------------------------- agent_run_step (kept, locked)
ALTER TABLE intelligence.agent_run_step
    ADD CONSTRAINT ck_agent_run_step_tenant_is_client CHECK (tenant_id = client_id);
