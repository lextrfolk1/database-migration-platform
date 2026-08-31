-- Drop table if exists
DROP TABLE IF EXISTS meta.node_hierarchy CASCADE;

-- Create node_hierarchy table
CREATE TABLE IF NOT EXISTS meta.node_hierarchy (
    client_id INTEGER DEFAULT 1,               -- Client identifier, default is 1
    node_id INTEGER NOT NULL,                  -- Unique internal ID
    node_name VARCHAR NOT NULL,                -- Display name (can be changed)
    node_code VARCHAR UNIQUE NOT NULL,         -- Unique identifier (e.g., 'FR Y-9C_REPORT')
    as_of_date DATE NOT NULL,                  -- Date the node is valid
    eff_status CHAR NOT NULL,                  -- Status (e.g., Active, Inactive)
    parent_node_id INTEGER,                    -- Parent reference
    node_properties JSONB,                     -- JSON for dynamic properties
    CONSTRAINT pk_node_hierarchy PRIMARY KEY (node_id)
);

-- Drop index if exists (safe for re-runs)
DROP INDEX IF EXISTS meta.idx_status_properties;


--Sequence for status_master ID
DROP SEQUENCE IF EXISTS meta.status_master_id_seq CASCADE;
CREATE SEQUENCE meta.status_master_id_seq
    START WITH 1;

-- Drop table if it exists
DROP TABLE IF EXISTS meta.status_master CASCADE;

-- Create table if it doesn't already exist
CREATE TABLE IF NOT EXISTS meta.status_master (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.status_master_id_seq'::regclass),
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

--Sequence for workflow_metadata ID
DROP SEQUENCE IF EXISTS meta.workflow_metadata_id_seq CASCADE;
CREATE SEQUENCE meta.workflow_metadata_id_seq
    START WITH 1;

-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_metadata CASCADE;

-- Create table if it does not exist
CREATE TABLE IF NOT EXISTS meta.workflow_metadata (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.workflow_metadata_id_seq'::regclass),
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

--Sequence for workflow_master ID
DROP SEQUENCE IF EXISTS meta.workflow_master_id_seq CASCADE;
CREATE SEQUENCE meta.workflow_master_id_seq
    START WITH 1;

-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_master CASCADE;

-- Create table for master workflow data
CREATE TABLE IF NOT EXISTS meta.workflow_master (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.workflow_master_id_seq'::regclass),
    workflow_code VARCHAR NOT NULL,
    workflow_name VARCHAR NOT NULL,
    workflow_description VARCHAR NOT NULL,
    created_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.workflow_master IS 'Master table for managing workflows.';

--Sequence for module_master ID
DROP SEQUENCE IF EXISTS meta.module_master_id_seq CASCADE;
CREATE SEQUENCE meta.module_master_id_seq
    START WITH 1;

-- Drop table if it exists
DROP TABLE IF EXISTS meta.module_master CASCADE;

-- Create table for module data
CREATE TABLE IF NOT EXISTS meta.module_master (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.module_master_id_seq'::regclass),
    module_name VARCHAR NOT NULL
);

-- Drop table if it exists
DROP TABLE IF EXISTS meta.workflow_module_map CASCADE;

-- Create table to map workflows to modules
CREATE TABLE IF NOT EXISTS meta.workflow_module_map (
    client_id INTEGER DEFAULT 1,
    workflow_master_id INTEGER NOT NULL,
    module_master_id INTEGER NOT NULL,
    CONSTRAINT fk_workflow_module_map_workflow_master
        FOREIGN KEY (workflow_master_id) REFERENCES meta.workflow_master(id),
    CONSTRAINT fk_workflow_module_map_module_master
        FOREIGN KEY (module_master_id) REFERENCES meta.module_master(id)
);

DROP TABLE IF EXISTS meta.report_template_metadata CASCADE;

CREATE TABLE IF NOT EXISTS meta.report_template_metadata(
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    form_name VARCHAR NOT NULL,
    form_group VARCHAR NOT NULL,
    schedule_name VARCHAR,
    sub_schedule_name VARCHAR,
    file_name VARCHAR NOT NULL,
    file_path VARCHAR NOT NULL,
    uploaded_by VARCHAR NOT NULL,
    uploaded_on TIMESTAMP DEFAULT now() NOT NULL,
    updated_by VARCHAR NOT NULL,
    updated_on TIMESTAMP NOT NULL,

    CONSTRAINT fk_report_template_metadata_node FOREIGN KEY (node_id)
        REFERENCES meta.node_hierarchy(node_id) ON DELETE RESTRICT
);


DROP TABLE IF EXISTS meta.inbound_control CASCADE;
CREATE TABLE IF NOT EXISTS meta.inbound_control
(
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    file_type text COLLATE pg_catalog."default" NOT NULL,
    target_table text COLLATE pg_catalog."default",
	row_identifiers text COLLATE pg_catalog."default",
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

DROP TABLE IF EXISTS meta.inbound_file_meta CASCADE;
CREATE TABLE IF NOT EXISTS meta.inbound_file_meta
(
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    file_type text COLLATE pg_catalog."default",
    seq INTEGER NOT NULL,
    col text COLLATE pg_catalog."default",
    data_type text COLLATE pg_catalog."default",
    nullable text COLLATE pg_catalog."default",
    completeness_percent INTEGER,
    warnings_percent INTEGER,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

--Sequence for datasets_lookup ID
DROP SEQUENCE IF EXISTS meta.dataset_lookup_id_seq CASCADE;
CREATE SEQUENCE meta.dataset_lookup_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.datasets_lookup CASCADE;

CREATE TABLE meta.datasets_lookup (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.dataset_lookup_id_seq'::regclass),
    dataset_name VARCHAR(255) NOT NULL,
    load_type VARCHAR(10) CHECK (load_type IN ('file', 'db')),
    file_location TEXT
);

--Sequence for datasets_lookup ID
DROP SEQUENCE IF EXISTS meta.rule_component_id_seq CASCADE;
CREATE SEQUENCE meta.rule_component_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.rule_component CASCADE;

CREATE TABLE meta.rule_component (
    client_id INTEGER DEFAULT 1,
    id           BIGINT PRIMARY KEY DEFAULT nextval('meta.rule_component_id_seq'::regclass),
    name         VARCHAR(255) NOT NULL,
    properties   JSONB,
    created_on   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   VARCHAR(100) NOT NULL
);

-- Drop foreign key constraints
ALTER TABLE IF EXISTS meta.rule_attribute DROP CONSTRAINT IF EXISTS fk_rule_attribute_rule_id;

ALTER TABLE IF EXISTS meta.rule_attribute DROP CONSTRAINT IF EXISTS fk_rule_attribute_rule_type;

ALTER TABLE IF EXISTS meta.rule_detail DROP CONSTRAINT IF EXISTS fk_rule_detail_rule_id;

ALTER TABLE IF EXISTS meta.rule_detail DROP CONSTRAINT IF EXISTS fk_rule_detail_workflow_id;

ALTER TABLE IF EXISTS meta.rule_document DROP CONSTRAINT IF EXISTS fk_rule_document_rule_id;

ALTER TABLE IF EXISTS meta.rule_period_mapping  DROP CONSTRAINT IF EXISTS fk_rule_period_mapping_rule_id;


--Sequence for rule_master ID
DROP SEQUENCE IF EXISTS meta.rule_master_id_seq CASCADE;
CREATE SEQUENCE meta.rule_master_id_seq
    START WITH 101;

-- Drop tables
DROP TABLE IF EXISTS meta.rule_master CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_master (
    client_id INTEGER DEFAULT 1,
    rule_id BIGINT PRIMARY KEY DEFAULT nextval('meta.rule_master_id_seq'::regclass),
    rule_name VARCHAR NOT NULL,
    node_id INTEGER NOT NULL,
    rule_display_name VARCHAR,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.rule_master IS 'Master table for rules';

DROP TABLE IF EXISTS meta.rule_attribute CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_attribute (
    client_id INTEGER DEFAULT 1,
    rule_id INTEGER NOT NULL,
    rule_name VARCHAR NOT NULL,
    rule_type INTEGER NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.rule_attribute IS 'Rule attribute table containing the attributes of a rule';

DROP TABLE IF EXISTS meta.rule_type CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_type (
    client_id INTEGER DEFAULT 1,
    rule_type INTEGER PRIMARY KEY,
    rule_type_name VARCHAR NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

ALTER TABLE meta.rule_type RENAME COLUMN rule_type TO rule_type_id;
COMMENT ON TABLE meta.rule_type IS 'Rule type references';

DROP TABLE IF EXISTS meta.rule_detail CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_detail (
    client_id INTEGER DEFAULT 1,
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

COMMENT ON TABLE meta.rule_detail IS 'Detail table containing the core details of the rule';

DROP TABLE IF EXISTS meta.rule_document CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_document (
    client_id INTEGER DEFAULT 1,
    rule_id INTEGER PRIMARY KEY,
    rule_name VARCHAR NOT NULL,
    rule_doc TEXT NOT NULL,
    created_on TIMESTAMPTZ NOT NULL,
    created_by VARCHAR NOT NULL,
    updated_on TIMESTAMPTZ NOT NULL,
    updated_by VARCHAR NOT NULL
);

COMMENT ON TABLE meta.rule_document IS 'Documentation table for rules (Contains the logical reasoning steps)';

DROP TABLE IF EXISTS meta.rule_period_mapping CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_period_mapping  (
    client_id INTEGER DEFAULT 1,
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

COMMENT ON TABLE meta.rule_period_mapping  IS 'Rule to period mapping table';

-- Add foreign key constraints
ALTER TABLE IF EXISTS meta.rule_attribute
    ADD CONSTRAINT fk_rule_attribute_rule_id FOREIGN KEY (rule_id)
    REFERENCES meta.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS meta.rule_attribute
    ADD CONSTRAINT fk_rule_attribute_rule_type FOREIGN KEY (rule_type)
    REFERENCES meta.rule_type (rule_type_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS meta.rule_detail
    ADD CONSTRAINT fk_rule_detail_rule_id FOREIGN KEY (rule_id)
    REFERENCES meta.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

--Sequence for workflow_detail ID
DROP SEQUENCE IF EXISTS meta.workflow_detail_id_seq CASCADE;
CREATE SEQUENCE meta.workflow_detail_id_seq
    START WITH 1;

-- Drop workflow_detail table if it exists
DROP TABLE IF EXISTS data.workflow_detail CASCADE;

-- Workflow Detail Table creating into meta because of referenced use in next object
CREATE TABLE IF NOT EXISTS data.workflow_detail (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.workflow_detail_id_seq'::regclass),
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


ALTER TABLE IF EXISTS meta.rule_detail
    ADD CONSTRAINT fk_rule_detail_workflow_id FOREIGN KEY (workflow_id)
    REFERENCES data.workflow_detail (id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS meta.rule_document
    ADD CONSTRAINT fk_rule_document_rule_id FOREIGN KEY (rule_id)
    REFERENCES meta.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;

ALTER TABLE IF EXISTS meta.rule_period_mapping
    ADD CONSTRAINT fk_rule_period_mapping_rule_id FOREIGN KEY (rule_id)
    REFERENCES meta.rule_master (rule_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION NOT VALID;


-- Table: meta.rule_on_rule_mapping

DROP TABLE IF EXISTS meta.rule_on_rule_mapping CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_on_rule_mapping
(
    client_id INTEGER DEFAULT 1,
    rule_nm character varying COLLATE pg_catalog."default" NOT NULL,
    rule_version INTEGER NOT NULL,
    successor_of_rule_nm character varying COLLATE pg_catalog."default",
    successor_of_rule_version INTEGER,
    period character varying COLLATE pg_catalog."default" NOT NULL,
    created_on timestamp with time zone NOT NULL,
    created_by character varying COLLATE pg_catalog."default" NOT NULL,
    updated_on timestamp with time zone NOT NULL,
    updated_by character varying COLLATE pg_catalog."default" NOT NULL,
    rule_status character varying COLLATE pg_catalog."default",
    successor_of_rule_status character varying COLLATE pg_catalog."default",
    rule_id INTEGER,
    successor_of_rule_id INTEGER,
    CONSTRAINT rule_on_rule_mapping_pkey PRIMARY KEY (period, rule_nm, rule_version)
);

ALTER TABLE meta.rule_attribute RENAME COLUMN rule_type TO rule_type_id;

ALTER TABLE meta.rule_period_mapping
ALTER COLUMN period TYPE DATE
USING TO_DATE(period::TEXT, 'YYYYMMDD');


ALTER TABLE meta.rule_period_mapping
ADD COLUMN restatement_version INTEGER;

DROP SEQUENCE IF EXISTS meta.dataset_details_seq CASCADE;

CREATE SEQUENCE IF NOT EXISTS meta.dataset_details_seq
    START 1;

ALTER SEQUENCE meta.dataset_details_seq
    OWNER TO lextr_user;


DROP TABLE IF EXISTS meta.dataset_details CASCADE;

CREATE TABLE IF NOT EXISTS meta.dataset_details
(
    client_id INTEGER DEFAULT 1,
    ds_id BIGINT NOT NULL DEFAULT nextval('meta.dataset_details_seq'::regclass),
    ds_nm character varying COLLATE pg_catalog."default" NOT NULL,
    ds_params character varying COLLATE pg_catalog."default",
    ds_conn_type character varying COLLATE pg_catalog."default",
    file_path character varying COLLATE pg_catalog."default",
    unload_query character varying COLLATE pg_catalog."default",
    created_by character varying COLLATE pg_catalog."default",
    updated_by character varying COLLATE pg_catalog."default",
    created_on timestamp with time zone,
    updated_on timestamp with time zone,
    CONSTRAINT dataset_map_pkey PRIMARY KEY (ds_id),
    CONSTRAINT unique_ds_nm UNIQUE (ds_nm)
);


ALTER TABLE IF EXISTS meta.dataset_details
    OWNER to lextr_user;

DROP TABLE IF EXISTS meta.rule_on_dataset_mapping CASCADE;

CREATE TABLE IF NOT EXISTS meta.rule_on_dataset_mapping
(
    client_id INTEGER DEFAULT 1,
    rule_id INTEGER NOT NULL,
    dataset_id INTEGER NOT NULL,
    created_by character varying COLLATE pg_catalog."default",
    updated_by character varying COLLATE pg_catalog."default",
    created_on timestamp with time zone,
    updated_on timestamp with time zone,
    CONSTRAINT rule_on_dataset_mapping_pkey PRIMARY KEY (rule_id, dataset_id)
);

ALTER TABLE IF EXISTS meta.rule_on_dataset_mapping
    OWNER to lextr_user;


--  Add debug flag column to rule_detail table
ALTER TABLE meta.rule_detail ADD COLUMN debug_enabled BOOLEAN DEFAULT FALSE;

--Sequence for rule_taxonomy_map ID
DROP SEQUENCE IF EXISTS meta.rule_taxonomy_map_id_seq CASCADE;
CREATE SEQUENCE meta.rule_taxonomy_map_id_seq
    START WITH 1;

-- This table maps regulatory rules to their respective types and mapped rules
DROP TABLE IF EXISTS meta.rule_taxonomy_map CASCADE;

CREATE TABLE meta.rule_taxonomy_map (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.rule_taxonomy_map_id_seq'::regclass),
    rule_type_id INTEGER NOT NULL,
	rule_type VARCHAR(256) NOT NULL,
    rule_stage VARCHAR(256) NOT NULL CHECK (rule_stage IN ('final', 'intermediate')),
	form_nm VARCHAR(256) NOT NULL,
	schedule_nm VARCHAR(128),
	sub_schedule_nm VARCHAR(128),
	taxonomy_nm VARCHAR(256),
    rule_id INTEGER NOT NULL,
    rule_nm VARCHAR(256) NOT NULL,
    eff_status CHAR NOT NULL CHECK (eff_status IN ('A', 'I')) default 'A',
	created_by character varying COLLATE pg_catalog."default",
    updated_by character varying COLLATE pg_catalog."default",
    created_on timestamp with time zone,
    updated_on timestamp with time zone
);

--Sequence for report_store_metadata ID
DROP SEQUENCE IF EXISTS meta.report_store_metadata_id_seq CASCADE;
CREATE SEQUENCE meta.report_store_metadata_id_seq
    START WITH 1;

-- REPORT GENERATION TABLES
DROP TABLE IF EXISTS meta.report_store_metadata CASCADE;

CREATE TABLE meta.report_store_metadata (
    client_id             INT NOT NULL DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.report_store_metadata_id_seq'::regclass),
    form_group            VARCHAR NOT NULL,
    form_name             VARCHAR NOT NULL,
    schedule_name         VARCHAR,
    sub_schedule_name     VARCHAR,
    actual_report_name    VARCHAR NOT NULL,
	report_type           VARCHAR NOT NULL,
    xsd_path              VARCHAR
);

-- updating primary constraint to handle 2 node dataset operations like union, minus
ALTER TABLE meta.rule_on_rule_mapping
DROP CONSTRAINT rule_on_rule_mapping_pkey;

ALTER TABLE meta.rule_on_rule_mapping
ADD CONSTRAINT rule_on_rule_mapping_pkey
PRIMARY KEY (period, rule_nm, successor_of_rule_nm, rule_version);

ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN rule_nm DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN client_id DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN rule_type_id DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN rule_type DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN rule_stage DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN form_nm DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN schedule_nm DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN sub_schedule_nm DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN taxonomy_nm DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN eff_status DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN created_by DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN updated_by DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN created_on DROP NOT NULL;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN updated_on DROP NOT NULL;

ALTER TABLE meta.rule_taxonomy_map
DROP CONSTRAINT rule_taxonomy_map_rule_stage_check;

ALTER TABLE meta.rule_taxonomy_map ADD COLUMN node_id integer;
UPDATE meta.rule_taxonomy_map SET node_id = 5;
ALTER TABLE meta.rule_taxonomy_map ALTER COLUMN node_id SET NOT NULL;

-------- Form Specs
DROP TABLE IF EXISTS meta.resource_specs CASCADE;

CREATE TABLE IF NOT EXISTS meta.resource_specs
(
    form_resource_name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    form_resource_version character varying(100) COLLATE pg_catalog."default" NOT NULL,
    taxonomy_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    reportable character varying(100) COLLATE pg_catalog."default" NOT NULL,
    confidential character varying(100) COLLATE pg_catalog."default" NOT NULL,
    adj_type character varying(100) COLLATE pg_catalog."default" NOT NULL,
    scaling numeric NOT NULL,
    rounding numeric NOT NULL,
    updated_by character varying(20) COLLATE pg_catalog."default",
    update_at timestamp without time zone,
    CONSTRAINT resource_specs_pkey PRIMARY KEY (form_resource_name, taxonomy_id)
);

ALTER TABLE IF EXISTS meta.resource_specs
ADD COLUMN created_bv character(20);

ALTER TABLE IF EXISTS meta.resource_specs
ADD COLUMN created_at timestamp without time zone;

-- Entitlement Scripts

DROP TABLE IF EXISTS meta.role_master CASCADE;
CREATE TABLE meta.role_master
(
    role_name character(100) NOT NULL,
    role_disp_name character(100),
    role_desc character(2000),
    updated_by character(20),
    updated_at timestamp without time zone,
    PRIMARY KEY (role_name)
);

DROP TABLE IF EXISTS meta.action_master CASCADE;
CREATE TABLE meta.action_master
(
    action_name character(100) NOT NULL,
    action_desc character(2000),
    updated_by character(20),
    updated_at timestamp without time zone,
    PRIMARY KEY (action_name)
);

DROP TABLE IF EXISTS meta.role_action_map CASCADE;
CREATE TABLE meta.role_action_map
(
    role_name character(100) NOT NULL,
    action_name character(100) NOT NULL,
    updated_by character(20),
    updated_at timestamp without time zone,
    PRIMARY KEY (role_name, action_name)
);

DROP TABLE IF EXISTS meta.role_module_map CASCADE;
CREATE TABLE meta.role_module_map
(
    role_name character(100) NOT NULL,
    module_name character(100) NOT NULL,
    updated_by character(20),
    updated_at timestamp without time zone,
    PRIMARY KEY (role_name, module_name)
);


ALTER TABLE meta.rule_document ADD COLUMN IF NOT EXISTS version INTEGER;
ALTER TABLE meta.rule_document ADD COLUMN IF NOT EXISTS restatement_version INTEGER;
ALTER TABLE meta.rule_document ADD COLUMN IF NOT EXISTS period DATE;
ALTER TABLE meta.rule_document ADD COLUMN IF NOT EXISTS language VARCHAR(5);
ALTER TABLE meta.rule_document ADD COLUMN IF NOT EXISTS node_id INTEGER;

ALTER TABLE meta.rule_document DROP CONSTRAINT rule_document_pkey;
ALTER TABLE meta.rule_document ADD PRIMARY KEY (rule_id, VERSION, restatement_version, period, LANGUAGE);




-- ===============================================
--  UI Elements Configuration Table
-- ===============================================

--Sequence for ui_elements_config ID
DROP SEQUENCE IF EXISTS meta.ui_elements_config_id_seq CASCADE;
CREATE SEQUENCE meta.ui_elements_config_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.ui_elements_config CASCADE;
CREATE TABLE meta.ui_elements_config (
    element_id        BIGINT PRIMARY KEY DEFAULT nextval('meta.ui_elements_config_id_seq'::regclass),            -- Unique identifier

    -- Scope control (always required)
    client_id         INTEGER NOT NULL,                     -- Client scope
    module_name       VARCHAR(100) NOT NULL,                -- Module-level scope
    node_code         VARCHAR(100) NOT NULL,                -- Node-level scope

    -- Element details
    group_key         VARCHAR(100) NOT NULL,                -- UI group/screen identifier
    parent_id         BIGINT,                               -- Parent element ID for hierarchical layout
    element_key       VARCHAR(100) NOT NULL,                -- Technical identifier
    translation_key   VARCHAR(100) NOT NULL,                -- Key for translation/labels
    element_type      VARCHAR(50) NOT NULL,                 -- TEXTBOX, DROPDOWN, etc.
    layout_type       VARCHAR(50) DEFAULT 'INLINE',         -- INLINE, GRID, TAB, etc.
    order_index       INT NOT NULL DEFAULT 0,               -- Display order in UI

    -- Configurations
    is_required       BOOLEAN NOT NULL DEFAULT FALSE,       -- Field validation flag
    config_json       JSONB,                                -- Static config (e.g., maxlength)
    dynamic_query     TEXT,                                 -- Optional SQL or API path
    query_params      JSONB,                                -- Optional parameters for dynamic query
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,        -- Active/inactive flag

    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by        VARCHAR(100) NOT NULL,
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_by        VARCHAR(100) NOT NULL,

    -- Referential integrity for parent-child hierarchy
    CONSTRAINT fk_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES meta.ui_elements_config (element_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ===============================================
--  Constraints
-- ===============================================

-- Unique constraint to avoid duplicates within scoped level
ALTER TABLE meta.ui_elements_config
ADD CONSTRAINT ui_elements_config_unique_constraint
UNIQUE (client_id, module_name, node_code, group_key, element_key);

-- Allowed element types
ALTER TABLE meta.ui_elements_config
ADD CONSTRAINT chk_element_type
CHECK (element_type IN (
    'TEXTBOX', 'TEXTAREA', 'NUMBER', 'PASSWORD',
    'DATE', 'TIME', 'DATETIME', 'HIDDEN', 'DROPDOWN', 'MULTISELECT',
    'RADIO', 'CHECKBOX', 'SECTION', 'TAB', 'GRID', 'PANEL',
    'FORM', 'ACCORDION', 'FILE_UPLOAD', 'BUTTON', 'LABEL'
));

-- Optional: Allowed layout types
ALTER TABLE meta.ui_elements_config
ADD CONSTRAINT chk_layout_type
CHECK (layout_type IN ('INLINE', 'GRID', 'TAB', 'PANEL', 'ACCORDION'));

-- ===============================================
--  Indexes
-- ===============================================

-- Optimize lookup for active configurations
CREATE INDEX idx_ui_elements_config_lookup
ON meta.ui_elements_config (client_id, module_name, node_code, group_key)
WHERE is_active = TRUE;

-- Index for fast parent-child lookup
CREATE INDEX idx_ui_elements_config_parent
ON meta.ui_elements_config (parent_id);

-- Alter resource_specs to add comments columns
ALTER TABLE meta.resource_specs ADD COLUMN IF NOT EXISTS comments_reportable TEXT;
ALTER TABLE meta.resource_specs ADD COLUMN IF NOT EXISTS comments_confidential TEXT;

-- Drop the constraint if it exists
ALTER TABLE meta.ui_elements_config
DROP CONSTRAINT IF EXISTS chk_element_type;

-- Recreate it with BOOLEAN added
ALTER TABLE meta.ui_elements_config
ADD CONSTRAINT chk_element_type
CHECK (element_type IN (
    'TEXTBOX', 'TEXTAREA', 'NUMBER', 'PASSWORD',
    'DATE', 'TIME', 'DATETIME', 'HIDDEN',
    'DROPDOWN', 'MULTISELECT', 'RADIO', 'CHECKBOX',
    'SECTION', 'TAB', 'GRID', 'PANEL',
    'FORM', 'ACCORDION', 'FILE_UPLOAD',
    'BUTTON', 'LABEL', 'BOOLEAN'
));

-- ================================================ --
--Sequence for menu_master ID
DROP SEQUENCE IF EXISTS meta.menu_master_id_seq CASCADE;
CREATE SEQUENCE meta.menu_master_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.menu_master CASCADE;
CREATE TABLE meta.menu_master (
    client_id INT NOT NULL,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.menu_master_id_seq'::regclass),
    menu_name VARCHAR(150) NOT NULL,
	display_name VARCHAR(150),
    display_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Sequence for menu_component ID
DROP SEQUENCE IF EXISTS meta.menu_component_id_seq CASCADE;
CREATE SEQUENCE meta.menu_component_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.menu_component CASCADE;
CREATE TABLE meta.menu_component (
    client_id INT NOT NULL,
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.menu_master_id_seq'::regclass),
    menu_id BIGINT NOT NULL,
    component_name VARCHAR(150) NOT NULL,
	display_name VARCHAR(150),
    display_order INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_menu
        FOREIGN KEY (menu_id)
        REFERENCES meta.menu_master(id)
        ON DELETE CASCADE
);
--- ================================================ --

--- Drilldown Metadata Table ---

DROP SEQUENCE IF EXISTS meta.seq_drilldown_stage_metadata_id CASCADE;
DROP SEQUENCE IF EXISTS meta.seq_drilldown_stage_query_registry_id CASCADE;
DROP SEQUENCE IF EXISTS meta.seq_drilldown_config_id CASCADE;

CREATE SEQUENCE meta.seq_drilldown_stage_metadata_id START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE meta.seq_drilldown_stage_query_registry_id START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE meta.seq_drilldown_config_id START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;


DROP TABLE IF EXISTS meta.drilldown_stage_query_registry CASCADE;
DROP TABLE IF EXISTS meta.drilldown_stage_metadata CASCADE;
DROP TABLE IF EXISTS meta.drilldown_config CASCADE;

CREATE TABLE IF NOT EXISTS meta.drilldown_stage_metadata (
  id              BIGINT PRIMARY KEY DEFAULT nextval('meta.seq_drilldown_stage_metadata_id'),
  client_id       TEXT NOT NULL,
  stage_key       TEXT NOT NULL,          -- e.g. RAW_DATA, CURATED_DATA
  stage_display_name TEXT NOT NULL,       -- e.g. "Raw Data"
  stage_order     INT NOT NULL,
  created_on      timestamptz NOT NULL DEFAULT now(),
  created_by      TEXT NOT NULL,
  updated_on      timestamptz NOT NULL DEFAULT now(),
  updated_by      TEXT NOT NULL,
  CONSTRAINT uq_stage_per_client UNIQUE (client_id, stage_key)
);

CREATE INDEX idx_stage_client ON meta.drilldown_stage_metadata(client_id);
CREATE INDEX idx_stage_order ON meta.drilldown_stage_metadata(client_id, stage_order);

CREATE TABLE IF NOT EXISTS meta.drilldown_stage_query_registry (
  id              BIGINT PRIMARY KEY DEFAULT nextval('meta.seq_drilldown_stage_query_registry_id'),
  client_id       VARCHAR(50) NOT NULL,
  stage_key       VARCHAR(100) NOT NULL,
  query_name      VARCHAR(100) NOT NULL DEFAULT 'default',
  dataset_query   TEXT NOT NULL,
  description     TEXT,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   UNIQUE (client_id, stage_key, query_name),
    FOREIGN KEY (client_id, stage_key) REFERENCES meta.drilldown_stage_metadata(client_id, stage_key) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_drilldown_stage_query_registry_client_stage_active ON meta.drilldown_stage_query_registry (client_id, stage_key, is_active);

CREATE TABLE IF NOT EXISTS meta.drilldown_config (
  id              BIGINT PRIMARY KEY DEFAULT nextval('meta.seq_drilldown_config_id'),
  client_id       TEXT NOT NULL,
  config_json     jsonb NOT NULL,
  created_on      timestamptz NOT NULL DEFAULT now(),
  created_by      TEXT NOT NULL,
  updated_on      timestamptz NOT NULL DEFAULT now(),
  updated_by      TEXT NOT NULL,
  CONSTRAINT uq_drilldown_config_client UNIQUE(client_id)
);

CREATE INDEX idx_drilldown_config_client ON meta.drilldown_config(client_id);


-- form spec Audit
DROP SEQUENCE IF EXISTS meta.resource_specs_audit_id_seq CASCADE;
CREATE SEQUENCE meta.resource_specs_audit_id_seq
    START WITH 1;

DROP TABLE IF EXISTS meta.resource_specs_audit CASCADE;

CREATE TABLE IF NOT EXISTS meta.resource_specs_audit
(
    id BIGINT PRIMARY KEY DEFAULT nextval('meta.resource_specs_audit_id_seq'::regclass),
    form_resource_name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    form_resource_version character varying(100) COLLATE pg_catalog."default" NOT NULL,
    taxonomy_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    reportable character varying(100) COLLATE pg_catalog."default" NOT NULL,
    confidential character varying(100) COLLATE pg_catalog."default" NOT NULL,
    adj_type character varying(100) COLLATE pg_catalog."default" NOT NULL,
    scaling numeric NOT NULL,
    rounding numeric NOT NULL,
    updated_by character varying(20) COLLATE pg_catalog."default",
    update_at timestamp without time zone,
	comments_reportable TEXT,
	comments_confidential TEXT
);

ALTER TABLE meta.dataset_details ADD COLUMN IF NOT EXISTS is_analytic BOOLEAN DEFAULT FALSE;

ALTER TABLE meta.resource_specs ADD COLUMN IF NOT EXISTS client_id INT NOT NULL DEFAULT 1;
ALTER TABLE meta.resource_specs_audit ADD COLUMN IF NOT EXISTS client_id INT NOT NULL DEFAULT 1;

-- Attestations Tables
DROP SEQUENCE IF EXISTS meta.attestation_master_seq CASCADE;
CREATE SEQUENCE meta.attestation_master_seq START WITH 1 INCREMENT BY 1;

DROP TABLE IF EXISTS meta.attestation_catalog CASCADE;

CREATE TABLE meta.attestation_catalog (
  id BIGINT PRIMARY KEY,
  client_id INTEGER NOT NULL DEFAULT 1,
  label TEXT NOT NULL,
  answer_type VARCHAR(32) NOT NULL,
  options_json JSONB,
  validation_json JSONB,
  ui_json JSONB,
  created_by VARCHAR(128) NOT NULL,
  created_on TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_by VARCHAR(128),
  updated_on TIMESTAMP WITH TIME ZONE
);

DROP TABLE IF EXISTS meta.attestation_master CASCADE;

CREATE TABLE meta.attestation_master (
  id BIGINT PRIMARY KEY DEFAULT nextval('meta.attestation_master_seq'),
  client_id INTEGER NOT NULL,
  module_id BIGINT NOT NULL REFERENCES meta.module_master(id),
  workflow VARCHAR(64) NOT NULL,
  stage VARCHAR(64) NOT NULL,
  node_id INTEGER,
  attestation_id BIGINT NOT NULL REFERENCES meta.attestation_catalog(id),
  display_order INT NOT NULL,
  required BOOLEAN NOT NULL DEFAULT false,
  active BOOLEAN NOT NULL DEFAULT true,
  created_by VARCHAR(128) NOT NULL,
  created_on TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_by VARCHAR(128),
  updated_on TIMESTAMP WITH TIME ZONE,

  CONSTRAINT uq_attestation_master UNIQUE ( client_id, module_id, node_id, workflow, stage, attestation_id, active )
);

ALTER TABLE meta.rule_period_mapping ADD COLUMN IF NOT EXISTS legal_entity VARCHAR;

-- updating dataset_details sequence in continuation from rule_master sequence,
-- suggestion : Re create dataset after executing following alters
ALTER TABLE meta.dataset_details ALTER COLUMN ds_id SET DEFAULT nextval('meta.rule_master_id_seq'::regclass);

-- Dropping existing dataset details sequence
DROP SEQUENCE IF EXISTS meta.dataset_details_seq;


ALTER TABLE meta.dataset_details ADD COLUMN param_query TEXT;