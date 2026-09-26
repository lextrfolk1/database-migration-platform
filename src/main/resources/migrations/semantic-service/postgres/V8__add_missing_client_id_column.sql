-- =============================================================================
-- V8 — Add missing client_id column to schema_catalog (corrective migration)
-- =============================================================================
-- V1 baseline was created without the client_id column. This migration adds
-- it to align with the schema contract and allow future migrations to populate it.

ALTER TABLE meta.schema_catalog
ADD COLUMN IF NOT EXISTS client_id varchar(40) NOT NULL DEFAULT 'GLOBAL';

-- Update existing rows to have client_id = 'GLOBAL' (already defaulted via ADD COLUMN)
UPDATE meta.schema_catalog SET client_id = 'GLOBAL' WHERE client_id IS NULL;
