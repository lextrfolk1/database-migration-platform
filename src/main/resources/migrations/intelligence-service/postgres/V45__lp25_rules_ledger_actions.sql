-- LP-25 / LP-59: UC11 Rules Copilot records two governed actions on the estate ledger (agent_run_event):
--   SUGGEST - a copilot run (or its refusal) and the tool_scope_rules decision behind it
--   ACCEPT  - Core's acceptance receipt linking a suggestion to the accepted rule version
-- The vocabulary is closed (V21, V44), so both are added here; every existing action is kept unchanged.
-- accepted_by records WHO accepted (the X-User-Id on Core's receipt); additive and nullable.

ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS accepted_by text;

ALTER TABLE intelligence.agent_run_event
    DROP CONSTRAINT IF EXISTS chk_event_governed_action;

ALTER TABLE intelligence.agent_run_event
    ADD CONSTRAINT chk_event_governed_action
    CHECK (action IS NULL OR action IN (
        'PIPELINE', 'ASSR_STARTED', 'ASSR_MEASURED', 'ASSR_JUDGED',
        'ATTEST', 'SUBMIT', 'APPROVE', 'REJECT',
        'RETIRE', 'SUPERSEDE', 'ROLLBACK', 'ESCALATE',
        'PRE_SUBMIT', 'PRE_APPROVE', 'PRE_REJECT',
        'TDM_SUBMIT', 'TDM_ATTEST', 'TDM_APPROVE', 'TDM_REJECT',
        'SKL_PROMOTE', 'SKL_ACTIVATE', 'SKL_REJECT', 'SKL_RETIRE',
        'FREEZE', 'TDM_LIFECYCLE', 'KH_LIFECYCLE', 'EXPORT',
        'SANDBOX_RUN', 'PARSE', 'PARSE_REFUSED', 'DROP_DECLARED',
        'INGESTED',
        'RUN', 'ACCEPT_BATCH',
        'SUGGEST', 'ACCEPT'
    ));
