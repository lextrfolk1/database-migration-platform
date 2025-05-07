-- Drop index if exists (safe for re-runs)
DROP INDEX IF EXISTS idx_status_properties;

-- Drop table if it exists
DROP TABLE IF EXISTS meta.status_master;

-- Create table if it doesn't already exist
CREATE TABLE IF NOT EXISTS meta.status_master (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    label VARCHAR(100),
    description TEXT,
    properties JSONB,
    created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recreate the JSONB index (useful for property-based filtering)
CREATE INDEX IF NOT EXISTS idx_status_properties
    ON meta.status_master USING GIN (properties);


