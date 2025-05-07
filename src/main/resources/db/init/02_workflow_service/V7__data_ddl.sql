-- Drop workflow_detail table if it exists
DROP TABLE IF EXISTS data.workflow_detail;

-- Workflow Detail Table
CREATE TABLE IF NOT EXISTS data.workflow_detail (
    id SERIAL PRIMARY KEY,
    workflow_master_id INTEGER NOT NULL,
    module_name VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    comments VARCHAR NOT NULL,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL,
    CONSTRAINT fk_workflow_detail_workflow_master
        FOREIGN KEY (workflow_master_id) REFERENCES meta.workflow_master(id)
);

COMMENT ON TABLE data.workflow_detail IS 'Detail table for managing workflows.';

-- Drop workflow_audit table if it exists
DROP TABLE IF EXISTS data.workflow_audit;

-- Workflow Audit Table
CREATE TABLE IF NOT EXISTS data.workflow_audit (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER NOT NULL,
    status VARCHAR NOT NULL,
    sequence INTEGER NOT NULL,
    comments VARCHAR,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL,
    CONSTRAINT fk_workflow_audit_workflow
        FOREIGN KEY (workflow_id) REFERENCES data.workflow_detail(id)
);

COMMENT ON TABLE data.workflow_audit IS 'Audit table for workflows.';