-- 005: persist the review outcome (architecture §14, §23)
--
-- Approving an analysis mutated it in memory and wrote an audit event, but
-- never wrote the outcome back to variance.analysis. Two consequences:
--   * a restart reverted every approval to PENDING_REVIEW, because rehydration
--     reads result->human_review->status from the row
--   * nothing downstream could consume approved narratives, so "Accept & send
--     to Core" sent nothing anywhere
--
-- The approved text lives in its own column rather than only inside the
-- result jsonb: it is the artifact a consuming system posts, it may differ
-- from the generated narrative when the reviewer edited it, and a consumer
-- should not have to understand variance_explanation.v1 to read it.
--
-- analysis_status stays the generation lifecycle (RUNNING/GENERATED/FAILED/
-- SUPERSEDED). Review state is a separate axis and gets its own column;
-- collapsing them would make "superseded but approved" unrepresentable.

ALTER TABLE variance.analysis
    ADD COLUMN IF NOT EXISTS review_status      TEXT,
    ADD COLUMN IF NOT EXISTS reviewer           TEXT,
    ADD COLUMN IF NOT EXISTS second_reviewer    TEXT,
    ADD COLUMN IF NOT EXISTS reviewed_at        TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS approved_narrative TEXT,
    ADD COLUMN IF NOT EXISTS edited_by_reviewer BOOLEAN NOT NULL DEFAULT FALSE;

-- An approved row must name who approved it and what was approved. Four-eyes
-- is enforced in the workflow; this is the storage-level backstop.
ALTER TABLE variance.analysis
    DROP CONSTRAINT IF EXISTS analysis_review_consistency;
ALTER TABLE variance.analysis
    ADD CONSTRAINT analysis_review_consistency CHECK (
        review_status IS NULL
        OR review_status NOT IN ('APPROVED', 'APPROVED_WITH_EDITS')
        OR (reviewer IS NOT NULL AND reviewed_at IS NOT NULL
            AND approved_narrative IS NOT NULL));

-- The downstream read path: approved explanations for a cycle.
CREATE INDEX IF NOT EXISTS ix_analysis_review_status
    ON variance.analysis (review_status)
    WHERE review_status IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_analysis_variance_current
    ON variance.analysis (variance_id, version DESC);
