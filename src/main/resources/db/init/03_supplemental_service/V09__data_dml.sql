DROP TABLE IF EXISTS data.supplementary_upload;

CREATE TABLE IF NOT EXISTS data.supplementary_upload (
    id SERIAL PRIMARY KEY,
    node_id VARCHAR NOT NULL,
    file_name VARCHAR NOT NULL,
    updated_file_name VARCHAR,
    file_path VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    validation_status VARCHAR,
    workflow_id INTEGER NOT NULL,
    error_file_name VARCHAR,
    error_file_path VARCHAR,
    comments TEXT,
    source VARCHAR NOT NULL,
    uploaded_by VARCHAR NOT NULL,
    uploaded_on TIMESTAMP DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL,
    updated_on TIMESTAMP NOT NULL,

    CONSTRAINT fk_supplementary_upload_workflow FOREIGN KEY (workflow_id)
        REFERENCES data.workflow_detail(id) ON DELETE RESTRICT,
    CONSTRAINT fk_supplementary_upload_node FOREIGN KEY (node_id)
        REFERENCES data.node_hierarchy(node_id) ON DELETE RESTRICT
);