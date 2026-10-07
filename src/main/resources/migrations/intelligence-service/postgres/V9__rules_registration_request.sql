-- =====================================================================
-- UC11 Rules & Logic Assist: operand registration requests
--
-- A rule operand the Semantic Layer does not register (OPERAND_UNREGISTERED) cannot be accepted into a draft.
-- The author's only action is to REQUEST its registration from the Semantic Layer steward; this records that
-- request against the UC11 run whose finding raised it. The finding stays open either way - nothing is resolved
-- by asking. One open request per (tenant, rule, attribute): asking again returns the existing request.
-- Idempotent: the table and its indexes are created only when absent.
-- =====================================================================

CREATE TABLE IF NOT EXISTS intelligence.rules_registration_request (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    run_id          text NOT NULL,           -- the UC11 run whose finding raised it (intelligence.agent_run.run_id)
    rule_ref        text NOT NULL,           -- Core's rule id
    attribute       text NOT NULL,           -- the unregistered operand, as the rule names it
    status          text NOT NULL DEFAULT 'REQUESTED' CHECK (status IN ('REQUESTED', 'REGISTERED', 'DECLINED')),
    requested_by    text NOT NULL,
    requested_at    timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rules_registration_open
    ON intelligence.rules_registration_request (client_id, rule_ref, lower(attribute))
    WHERE status = 'REQUESTED';

CREATE INDEX IF NOT EXISTS idx_rules_registration_rule
    ON intelligence.rules_registration_request (client_id, rule_ref);
