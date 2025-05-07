BEGIN;

-- Drop foreign key constraints
ALTER TABLE IF EXISTS data.rule_attribute DROP CONSTRAINT IF EXISTS fk_rule_attribute_rule_id;

ALTER TABLE IF EXISTS data.rule_attribute DROP CONSTRAINT IF EXISTS fk_rule_attribute_rule_type;

ALTER TABLE IF EXISTS data.rule_detail DROP CONSTRAINT IF EXISTS fk_rule_detail_rule_id;

ALTER TABLE IF EXISTS data.rule_detail DROP CONSTRAINT IF EXISTS fk_rule_detail_workflow_id;

ALTER TABLE IF EXISTS data.rule_document DROP CONSTRAINT IF EXISTS fk_rule_document_rule_id;

ALTER TABLE IF EXISTS data.rule_period_mapping DROP CONSTRAINT IF EXISTS fk_rule_period_mapping_rule_id;

-- Drop tables
DROP TABLE IF EXISTS data.rule_master;

CREATE TABLE IF NOT EXISTS data.rule_master (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR NOT NULL,
    node_id INTEGER NOT NULL,
    rule_display_name VARCHAR,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE data.rule_master IS 'Master table for rules';

DROP TABLE IF EXISTS data.rule_attribute;

CREATE TABLE IF NOT EXISTS data.rule_attribute (
    rule_id INTEGER NOT NULL,
    rule_name VARCHAR NOT NULL,
    rule_type INTEGER NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE data.rule_attribute IS 'Rule attribute table containing the attributes of a rule';

DROP TABLE IF EXISTS meta.rule_type;

CREATE TABLE IF NOT EXISTS meta.rule_type (
    rule_type INTEGER PRIMARY KEY,
    rule_type_name VARCHAR NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.rule_type IS 'Rule type references';

DROP TABLE IF EXISTS data.rule_detail;

CREATE TABLE IF NOT EXISTS data.rule_detail (
    rule_id INTEGER NOT NULL,
    rule_name VARCHAR NOT NULL,
    version INTEGER NOT NULL,
    status VARCHAR NOT NULL,
    rule_json JSON NOT NULL,
    workflow_id INTEGER NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL,
    comments VARCHAR,
    PRIMARY KEY (rule_id, version)
);

COMMENT ON TABLE data.rule_detail IS 'Detail table containing the core details of the rule';

DROP TABLE IF EXISTS data.rule_document;

CREATE TABLE IF NOT EXISTS data.rule_document (
    rule_id INTEGER PRIMARY KEY,
    rule_name VARCHAR NOT NULL,
    rule_doc TEXT NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE data.rule_document IS 'Documentation table for rules (Contains the logical reasoning steps)';

DROP TABLE IF EXISTS data.rule_period_mapping;

CREATE TABLE IF NOT EXISTS data.rule_period_mapping (
    rule_id INTEGER NOT NULL,
    rule_name VARCHAR NOT NULL,
    node_id INTEGER NOT NULL,
    version INTEGER NOT NULL,
    period INTEGER NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL,
    PRIMARY KEY (rule_id, version, period)
);

COMMENT ON TABLE data.rule_period_mapping IS 'Rule to period mapping table';

-- Add foreign key constraints
ALTER TABLE IF EXISTS data.rule_attribute
    ADD CONSTRAINT fk_rule_attribute_rule_id FOREIGN KEY (rule_id)
    REFERENCES data.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS data.rule_attribute
    ADD CONSTRAINT fk_rule_attribute_rule_type FOREIGN KEY (rule_type)
    REFERENCES meta.rule_type (rule_type)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS data.rule_detail
    ADD CONSTRAINT fk_rule_detail_rule_id FOREIGN KEY (rule_id)
    REFERENCES data.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS data.rule_detail
    ADD CONSTRAINT fk_rule_detail_workflow_id FOREIGN KEY (workflow_id)
    REFERENCES data.workflow_detail (id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS data.rule_document
    ADD CONSTRAINT fk_rule_document_rule_id FOREIGN KEY (rule_id)
    REFERENCES data.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS data.rule_period_mapping
    ADD CONSTRAINT fk_rule_period_mapping_rule_id FOREIGN KEY (rule_id)
    REFERENCES data.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

END;