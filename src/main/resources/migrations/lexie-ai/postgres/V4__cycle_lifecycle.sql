-- Cycle lifecycle persistence (architecture §5, §23).
--
-- 001 created variance.reporting_cycle for opening a cycle. Closing is an
-- attestation that its work is finished, and reopening undoes that — both
-- need to survive a restart, and both need to say who and why.
--
-- Also stores comparison_period and the resolved provider stack, so a cycle
-- carries everything needed to re-derive its analyses (§6.2).

ALTER TABLE variance.reporting_cycle
    ADD COLUMN IF NOT EXISTS comparison_period DATE,
    ADD COLUMN IF NOT EXISTS provider_stack    JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS closed_by         TEXT,
    ADD COLUMN IF NOT EXISTS closed_at         TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS close_note        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS close_forced      BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS reopen_count      INT NOT NULL DEFAULT 0;

-- A closed cycle must name its closer; an open one must not claim to be closed.
ALTER TABLE variance.reporting_cycle
    DROP CONSTRAINT IF EXISTS reporting_cycle_close_consistency;
ALTER TABLE variance.reporting_cycle
    ADD CONSTRAINT reporting_cycle_close_consistency CHECK (
        (status = 'CLOSED' AND closed_by IS NOT NULL AND closed_at IS NOT NULL)
        OR (status <> 'CLOSED' AND closed_by IS NULL AND closed_at IS NULL));

CREATE INDEX IF NOT EXISTS ix_cycle_status ON variance.reporting_cycle (status, period DESC);
CREATE INDEX IF NOT EXISTS ix_cycle_report ON variance.reporting_cycle (report, period DESC);
