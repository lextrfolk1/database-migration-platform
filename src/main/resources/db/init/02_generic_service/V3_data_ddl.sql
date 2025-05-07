-- Table: data.node_hierarchy

-- Drop table if exists
DROP TABLE IF EXISTS data.node_hierarchy;

-- Create node_hierarchy table
CREATE TABLE IF NOT EXISTS data.node_hierarchy (
    node_id VARCHAR NOT NULL,  -- Unique internal ID
    node_name VARCHAR NOT NULL,  -- Display name (can be changed)
    node_code VARCHAR UNIQUE NOT NULL,  -- Unique identifier (e.g., 'FRY9C_REPORT')
    as_of_date DATE NOT NULL,  -- Date the node is valid
    eff_status CHAR NOT NULL,  -- Status (e.g., Active, Inactive)
    parent_node_id VARCHAR,  -- Parent reference
    node_properties JSONB,  -- JSON for dynamic properties
    CONSTRAINT pk_node_hierarchy PRIMARY KEY (node_id)
);

-- Drop table if exists
DROP TABLE IF EXISTS data.virus_scan_request;

-- Create virus_scan_request table
CREATE TABLE data.virus_scan_request (
    id BIGSERIAL PRIMARY KEY,
    module_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    node_id VARCHAR(100) NOT NULL,
    file_name VARCHAR(100) NOT NULL,
    error_message TEXT,
    created_by VARCHAR(100) NOT NULL,
    updated_by VARCHAR(100) NOT NULL,
    created_on TIMESTAMP DEFAULT NOW(),
    updated_on TIMESTAMP DEFAULT NOW()
);
