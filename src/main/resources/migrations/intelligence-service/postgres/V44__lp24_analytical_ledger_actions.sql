-- LP-24 / LP-41.4: UC10 Analytical Assist records two governed actions on the estate ledger (agent_run_event):
--   RUN          - an analytical discovery run and the tool_scope_analytical decision behind it
--   ACCEPT_BATCH - the analyst's per-op accept / reject of an OperationBatch applied against Core's builder
-- The vocabulary is closed (V21), so both are added here; every existing action is kept unchanged.

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
        'RUN', 'ACCEPT_BATCH'
    ));
