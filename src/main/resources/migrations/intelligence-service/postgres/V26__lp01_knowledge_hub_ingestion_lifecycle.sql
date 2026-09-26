-- =============================================================================
-- V26: Knowledge Hub ingestion lifecycle on regulatory_document (LP-01.1, defect B1)
-- =============================================================================
-- V1 attached regulatory_document.ingestion_status to V1's form_version enum
-- ('pending','ingesting','completed','failed'). The embedded Knowledge Hub
-- migration specifies its own 7-state lifecycle, and the two lifecycles are
-- unrelated: sharing one enum lets form_version be set to 'QUARANTINED' and a
-- regulatory document to 'ingesting'.
--
-- Fix (additive, V1 untouched): the Knowledge Hub lifecycle gets its OWN type,
-- kh_ingestion_status, and only regulatory_document moves to it. form_version
-- keeps intelligence.ingestion_status. Existing rows map onto the nearest state.
-- Rejected: ALTER TYPE ... ADD VALUE on V1's type (merges the two lifecycles).
-- =============================================================================

SET search_path TO intelligence, public;

CREATE TYPE intelligence.kh_ingestion_status AS ENUM (
    'RECEIVED', 'CLASSIFIED', 'CHUNKED', 'EMBEDDED', 'AVAILABLE',
    'FAILED', 'QUARANTINED'
);

ALTER TABLE intelligence.regulatory_document
    ALTER COLUMN ingestion_status DROP DEFAULT;

ALTER TABLE intelligence.regulatory_document
    ALTER COLUMN ingestion_status TYPE intelligence.kh_ingestion_status
    USING (CASE ingestion_status::text
               WHEN 'pending'   THEN 'RECEIVED'
               WHEN 'ingesting' THEN 'CHUNKED'
               WHEN 'completed' THEN 'AVAILABLE'
               WHEN 'failed'    THEN 'FAILED'
           END)::intelligence.kh_ingestion_status;

ALTER TABLE intelligence.regulatory_document
    ALTER COLUMN ingestion_status SET DEFAULT 'RECEIVED';

COMMENT ON COLUMN intelligence.regulatory_document.ingestion_status IS
    'Knowledge Hub lifecycle (kh_ingestion_status). Distinct from form_version.ingestion_status.';
