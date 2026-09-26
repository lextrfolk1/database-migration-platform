-- =============================================================================
-- V30: persist the producer's variance explanation on agent_run (LP-06.2 / LP-50.2)
-- =============================================================================
-- persistRunWithTrace wrote only RunOutput to agent_run.output; the rich
-- variance_explanation.v1 lexie-ai produced (subject, drivers, evidence,
-- explainability, audit_metadata) was discarded at persist, so the evidence of
-- the answer never reached the database. It is stored here verbatim, and it is
-- also where LP-50's DETECTED / ANALYSED / REVIEWED populations read each run's
-- line identity (subject.mdrm_id) from, instead of trusting caller-supplied sets.
-- Additive, nullable (absent for runs that are not variance explanations).
-- =============================================================================

ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS variance_explanation jsonb;

CREATE INDEX IF NOT EXISTS agent_run_cycle_line_idx
    ON intelligence.agent_run (client_id, cycle_id, ((variance_explanation -> 'subject' ->> 'mdrm_id')))
    WHERE cycle_id IS NOT NULL;
