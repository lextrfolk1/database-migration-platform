-- Database migration script for system service registry table
CREATE TABLE IF NOT EXISTS system_service_registry (
    service_id VARCHAR(100) PRIMARY KEY,
    secret_hash VARCHAR(255) NOT NULL,
    scopes VARCHAR(1000) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for active services lookup
CREATE INDEX IF NOT EXISTS idx_system_service_enabled ON system_service_registry(service_id, enabled);
