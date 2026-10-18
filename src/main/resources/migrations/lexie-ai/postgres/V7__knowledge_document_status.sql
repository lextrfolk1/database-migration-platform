-- Knowledge Hub: real status lifecycle + upload bookkeeping
-- (doc/knowledge-hub-ui-design.md §4-5).
--
-- object_key and status already exist (003_knowledge_schema.sql) but nothing
-- ever populated object_key and status was always written as the literal
-- 'ACTIVE'. This migration widens status into a real lifecycle
-- (UPLOADED -> PARSING -> MASKING -> INDEXED -> {FAILED, SUPERSEDED,
-- ARCHIVED}) and adds the columns a Corpus/upload screen needs: what was
-- uploaded, how big it was, and why it failed if it did.

-- Existing rows all predate the lifecycle and were written as 'ACTIVE' —
-- reclassify them as INDEXED (the state 'ACTIVE' always meant in practice)
-- before the CHECK constraint below stops allowing 'ACTIVE' at all.
UPDATE variance.knowledge_document SET status = 'INDEXED' WHERE status = 'ACTIVE';

ALTER TABLE variance.knowledge_document
    DROP CONSTRAINT IF EXISTS knowledge_document_status_check;
ALTER TABLE variance.knowledge_document
    ADD CONSTRAINT knowledge_document_status_check
    CHECK (status IN ('UPLOADED','PARSING','MASKING','INDEXED','FAILED',
                       'SUPERSEDED','ARCHIVED'));
ALTER TABLE variance.knowledge_document ALTER COLUMN status SET DEFAULT 'UPLOADED';

ALTER TABLE variance.knowledge_document
    ADD COLUMN IF NOT EXISTS original_filename TEXT,
    ADD COLUMN IF NOT EXISTS content_type       TEXT,
    ADD COLUMN IF NOT EXISTS file_size_bytes    BIGINT,
    ADD COLUMN IF NOT EXISTS error_detail       TEXT,
    ADD COLUMN IF NOT EXISTS indexed_at         TIMESTAMPTZ;
-- created_at (003_knowledge_schema.sql) already serves as "uploaded_at".

CREATE INDEX IF NOT EXISTS ix_kdoc_status ON variance.knowledge_document (status);
