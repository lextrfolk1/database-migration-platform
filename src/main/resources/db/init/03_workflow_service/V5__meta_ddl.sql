-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_metadata;

-- Create table if it does not exist
CREATE TABLE IF NOT EXISTS meta.workflow_metadata (
    id SERIAL PRIMARY KEY,
    workflow_name TEXT NOT NULL,
    workflow_json JSONB NOT NULL,
    created_by TEXT NOT NULL DEFAULT current_user,
    created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active'
);

-- Create a unique index to ensure only one active entry per workflow_name
CREATE UNIQUE INDEX uniq_workflow_metadata_workflow_name
ON meta.workflow_metadata (workflow_name)
WHERE meta.workflow_metadata.status = 'active';

-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_master;

-- Create table for master workflow data
CREATE TABLE IF NOT EXISTS meta.workflow_master (
    id SERIAL PRIMARY KEY,
    workflow_code VARCHAR NOT NULL,
    workflow_name VARCHAR NOT NULL,
    workflow_description VARCHAR NOT NULL,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.workflow_master IS 'Master table for managing workflows.';

-- Drop table if it exists
DROP TABLE IF EXISTS meta.module_master;

-- Create table for module data
CREATE TABLE IF NOT EXISTS meta.module_master (
    id SERIAL PRIMARY KEY,
    module_name VARCHAR NOT NULL
);

-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_module_map;

-- Create table to map workflows to modules
CREATE TABLE IF NOT EXISTS meta.workflow_module_map (
    workflow_master_id INTEGER NOT NULL,
    module_master_id INTEGER NOT NULL,
    CONSTRAINT fk_workflow_module_map_workflow_master
        FOREIGN KEY (workflow_master_id) REFERENCES meta.workflow_master(id),
    CONSTRAINT fk_workflow_module_map_module_master
        FOREIGN KEY (module_master_id) REFERENCES meta.module_master(id)
);
