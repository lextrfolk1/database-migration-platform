-- =============================================================================
-- V42: tenant isolation is enforced in OPA, not RLS (owner decision 2026-09-25)
-- =============================================================================
-- V1's ring-fenced contract: "Tenancy: client_id on scoped rows; isolation
-- enforced in OPA, not RLS." V14 turned on FORCE ROW LEVEL SECURITY for
-- agent_run, agent_run_step, preset and registered_definition with policies of
-- the form tenant_id = current_setting('app.current_tenant_id'). Nothing in
-- the service ever sets that parameter, so for any non-superuser database role
-- every read of those tables returned zero rows and every insert failed its
-- WITH CHECK - the service could not persist or read a run.
--
-- This migration switches RLS OFF on the four tables. It is additive over
-- history and removes nothing: V14's policies stay defined (dormant), so a
-- future decision to adopt RLS is ENABLE + FORCE plus setting the session
-- parameter, not a rewrite. tenant_id stays NOT NULL with its tenant_profile
-- foreign key; the inserts now write tenant_id = client_id, the same mapping
-- V14 used to backfill.
-- =============================================================================

ALTER TABLE intelligence.agent_run             NO FORCE ROW LEVEL SECURITY;
ALTER TABLE intelligence.agent_run             DISABLE ROW LEVEL SECURITY;

ALTER TABLE intelligence.agent_run_step        NO FORCE ROW LEVEL SECURITY;
ALTER TABLE intelligence.agent_run_step        DISABLE ROW LEVEL SECURITY;

ALTER TABLE intelligence.preset                NO FORCE ROW LEVEL SECURITY;
ALTER TABLE intelligence.preset                DISABLE ROW LEVEL SECURITY;

ALTER TABLE intelligence.registered_definition NO FORCE ROW LEVEL SECURITY;
ALTER TABLE intelligence.registered_definition DISABLE ROW LEVEL SECURITY;
