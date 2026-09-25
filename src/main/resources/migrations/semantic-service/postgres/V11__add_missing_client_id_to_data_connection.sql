-- =============================================================================
-- V11 — Add missing client_id column to data_connection (corrective migration)
-- =============================================================================
-- V1 baseline was created without the client_id column on meta.data_connection.
-- This migration adds it to align with the schema contract (connection_registry.find_all/find_by_id)
-- and populates existing connections with 'GLOBAL'.

ALTER TABLE meta.data_connection
ADD COLUMN IF NOT EXISTS client_id varchar(40) NOT NULL DEFAULT 'GLOBAL';

-- Update existing rows to have client_id = 'GLOBAL'
UPDATE meta.data_connection SET client_id = 'GLOBAL' WHERE client_id IS NULL;

CREATE INDEX IF NOT EXISTS ix_dc_client ON meta.data_connection (client_id);
