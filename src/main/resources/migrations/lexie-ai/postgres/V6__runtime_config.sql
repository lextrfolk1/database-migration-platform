-- 006: governed runtime configuration (architecture §3, §26)
--
-- Provider choices are configuration, not code. That has always been true of
-- how they are READ; this makes them changeable without a deployment while
-- keeping the property that matters under SR 11-7: every change to the model
-- stack is attributable, justified, and effective-dated.
--
-- Same shape as variance.threshold_config, deliberately. A threshold change
-- and a model change are the same kind of event — a governed decision that
-- alters what the system produces — and they should be auditable the same way.
--
-- Rows are superseded, never updated in place: an explanation generated last
-- quarter must remain re-derivable against the stack that produced it. The
-- record's own audit_metadata.provider_stack is the authority for what ran;
-- this table is the authority for what was configured, and when.

CREATE TABLE IF NOT EXISTS variance.runtime_config (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    setting_key    TEXT NOT NULL,
    setting_value  TEXT NOT NULL,
    previous_value TEXT,
    reason         TEXT NOT NULL,
    changed_by     TEXT NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to   TIMESTAMPTZ,
    CONSTRAINT runtime_config_reason_present CHECK (length(btrim(reason)) > 0),
    CONSTRAINT runtime_config_actor_present  CHECK (length(btrim(changed_by)) > 0)
);

-- One live override per key. A partial unique index rather than a plain one:
-- superseded rows stay, and there may be many of them per key.
CREATE UNIQUE INDEX IF NOT EXISTS ux_runtime_config_active
    ON variance.runtime_config (setting_key)
    WHERE effective_to IS NULL;

CREATE INDEX IF NOT EXISTS ix_runtime_config_history
    ON variance.runtime_config (setting_key, effective_from DESC);
