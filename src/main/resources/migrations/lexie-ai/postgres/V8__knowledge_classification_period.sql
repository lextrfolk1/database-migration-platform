-- Knowledge Hub: data classification + reporting period
-- (doc/knowledge-hub-ui-design.md addendum — ingest-form fields requested
-- after phases 1-3 shipped: Classification, Version/Period, Effective Date).
--
-- effective_from/effective_to (003_knowledge_schema.sql) already cover
-- "Effective Date" — when the document's *content* is valid. These two
-- columns are new, independent axes:
--   classification     data sensitivity (who may see it), not evidence
--                       quality (reliability) or corpus category (collection)
--   reporting_period    which reporting cycle the document was curated for
--                       (e.g. "2026-Q2"), distinct from doc_version
--                       (revisions of the same document)
--
-- classification also carries a 5th value, AI_PROHIBITED, which is not a
-- visibility label like the other four — it is enforced by
-- KnowledgeIngestor.ingest() (service/variance/knowledge/store.py): a
-- document classified AI_PROHIBITED is never masked, chunked, or embedded,
-- so it can never surface in retrieval regardless of who may view it.

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
