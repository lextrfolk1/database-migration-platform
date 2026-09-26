-- =============================================================================
-- V41: a Description on an ingestion (LP-48.1, N1) - dated 2026-09-25
-- =============================================================================
-- Additive and re-runnable. NULLABLE because every existing row pre-dates it, and
-- there is NO backfill: "no description was given" is a real state, and the read
-- model renders it as absent rather than inventing one.
-- =============================================================================

SET search_path TO intelligence, public;

ALTER TABLE intelligence.regulatory_document
    ADD COLUMN IF NOT EXISTS description text;

COMMENT ON COLUMN intelligence.regulatory_document.description IS
    'LP-48 N1: the ingestion description the uploader gave. NULL = none given (rows before 2026-09-25 included); never backfilled.';
