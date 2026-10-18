-- Reconcile variance.schema_migration for 008_knowledge_classification_period.sql
-- (see run_variance_migrations.py's content_hash check).
--
-- 008 was edited in place — AI_PROHIBITED was added as a 5th classification
-- value in the same file — after some environments had already applied an
-- earlier version of it (4 values, no AI_PROHIBITED). The migration runner
-- hard-fails rather than silently reapplying an edited migration (edited
-- history = undefined schema state), so environments that migrated before
-- the edit need this reconciliation before 009_knowledge_graph.sql and
-- anything after it can apply.
--
-- This file is a superset of two things: (1) 008's current SQL, restated
-- here so running this file directly against an affected database is
-- sufficient on its own — every statement is idempotent, so this is a
-- no-op except widening the classification CHECK constraint to include
-- AI_PROHIBITED; and (2) the tracking-table row fix that makes 008's
-- recorded hash match its current on-disk content again, so the tracked
-- runner stops rejecting it.
--
-- One-time use, not a template: don't follow this pattern for future
-- schema changes — those get a new migration, not an edit to an already-
-- applied one.

ALTER TABLE variance.knowledge_document
    ADD COLUMN IF NOT EXISTS classification    TEXT NOT NULL DEFAULT 'INTERNAL',
    ADD COLUMN IF NOT EXISTS reporting_period  TEXT;

ALTER TABLE variance.knowledge_document
    DROP CONSTRAINT IF EXISTS knowledge_document_classification_check;
ALTER TABLE variance.knowledge_document
    ADD CONSTRAINT knowledge_document_classification_check
    CHECK (classification IN ('PUBLIC','INTERNAL','CONFIDENTIAL','RESTRICTED','AI_PROHIBITED'));

CREATE INDEX IF NOT EXISTS ix_kdoc_classification
    ON variance.knowledge_document (classification);
CREATE INDEX IF NOT EXISTS ix_kdoc_reporting_period
    ON variance.knowledge_document (reporting_period);

-- Make variance.schema_migration agree with 008's current on-disk content.
-- Safe to run even if 008 was never applied at all (UPDATE affects 0 rows;
-- the tracked runner will then apply 008 normally on its own).
-- Guarded: variance.schema_migration exists only where the lexie-ai Python
-- runner was used; a database built by this platform alone does not have it.
DO $$ BEGIN
  IF to_regclass('variance.schema_migration') IS NOT NULL THEN
    UPDATE variance.schema_migration
    SET content_hash = 'sha256:8f5c1a395d6124260f5d4aab7f1595e9f182b6dcd3b7b6e909c121ff0dce8cee',
        applied_at = now(),
        applied_by = 'manual-reconcile-008-ai-prohibited'
    WHERE filename = '008_knowledge_classification_period.sql';
  END IF;
END $$;
