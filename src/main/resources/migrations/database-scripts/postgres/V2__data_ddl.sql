--Sequence for virus_scan_request ID
DROP SEQUENCE IF EXISTS data.virus_scan_request_id_seq CASCADE;
CREATE SEQUENCE data.virus_scan_request_id_seq
    START WITH 1;

-- Drop table if exists
DROP TABLE IF EXISTS data.virus_scan_request CASCADE;

-- Create virus_scan_request table
CREATE TABLE data.virus_scan_request (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.virus_scan_request_id_seq'::regclass),
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


COMMENT ON TABLE data.workflow_detail IS 'Detail table for managing workflows.';

--Sequence for workflow_audit ID
DROP SEQUENCE IF EXISTS data.workflow_audit_id_seq CASCADE;
CREATE SEQUENCE data.workflow_audit_id_seq
    START WITH 1;

-- Drop workflow_audit table if it exists
DROP TABLE IF EXISTS data.workflow_audit CASCADE;

-- Workflow Audit Table
CREATE TABLE IF NOT EXISTS data.workflow_audit (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.workflow_audit_id_seq'::regclass),
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

--Sequence for su_upload_control ID
DROP SEQUENCE IF EXISTS data.su_upload_control_id_seq CASCADE;
CREATE SEQUENCE data.su_upload_control_id_seq
    START WITH 1;

DROP TABLE IF EXISTS data.su_upload_control CASCADE;

CREATE TABLE IF NOT EXISTS data.su_upload_control (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.su_upload_control_id_seq'::regclass),
    node_id INTEGER NOT NULL,
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
        REFERENCES meta.node_hierarchy(node_id) ON DELETE RESTRICT
);

DROP SEQUENCE IF EXISTS data.inbound_exec_seq CASCADE;
CREATE SEQUENCE data.inbound_exec_seq START 1;

DROP TABLE IF EXISTS data.inbound_run_control CASCADE;

CREATE TABLE IF NOT EXISTS data.inbound_run_control
(
   client_id INTEGER DEFAULT 1,
   node_id INTEGER NOT NULL,
   file_id INTEGER NOT NULL,
   workflow_id INTEGER NOT NULL,
   file_type text COLLATE pg_catalog."default" NOT NULL,
   exec_id INTEGER DEFAULT nextval('data.inbound_exec_seq'::regclass),
   period Date NOT NULL,
   restatement_version integer NOT NULL DEFAULT 0,
   file_name text COLLATE pg_catalog."default",
   exec_status text COLLATE pg_catalog."default",
   exec_msg text COLLATE pg_catalog."default",
   created_at timestamp with time zone DEFAULT now(),
   updated_at timestamp with time zone DEFAULT now()
);

DROP TABLE IF EXISTS data.financial_ledger_ds CASCADE;

CREATE TABLE IF NOT EXISTS data.financial_ledger_ds
(
    client_id INTEGER DEFAULT 1,
    affiliate text COLLATE pg_catalog."default",
    business_unit double precision,
    account text COLLATE pg_catalog."default",
    balance double precision,
    rowid INTEGER NOT NULL,
    exec_id INTEGER
);

DROP TABLE IF EXISTS data.deposit_ds CASCADE;

CREATE TABLE IF NOT EXISTS data.deposit_ds
(
    client_id INTEGER DEFAULT 1,
    rowid double precision NOT NULL,
    fdl_account text COLLATE pg_catalog."default",
    balance_type double precision,
    product_code double precision,
    business_unit double precision,
    deposit_product_type text COLLATE pg_catalog."default",
    affiliate_code text COLLATE pg_catalog."default",
    legal_code double precision,
    domicile_country text COLLATE pg_catalog."default",
    base_amount double precision,
    exec_id INTEGER
);

DROP TABLE IF EXISTS data.inbound_run_control_detail CASCADE;
CREATE TABLE IF NOT EXISTS data.inbound_run_control_detail
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER DEFAULT nextval('data.inbound_exec_seq'::regclass),
    exec_status text COLLATE pg_catalog."default",
    exec_msg text COLLATE pg_catalog."default",
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

DROP TABLE IF EXISTS data.regulatory_ledger_ds CASCADE;
CREATE TABLE IF NOT EXISTS data.regulatory_ledger_ds (
	client_id INTEGER DEFAULT 1,
	exec_id					INTEGER NOT NULL,
    organization_id         text COLLATE pg_catalog."default" NOT NULL,
    reportingperiod         text COLLATE pg_catalog."default" NOT NULL,
    region_name             text COLLATE pg_catalog."default" NOT NULL,
    country_name            text COLLATE pg_catalog."default" NOT NULL,
    frequency               text COLLATE pg_catalog."default" NOT NULL,
    disclosure_point        text COLLATE pg_catalog."default" NOT NULL,
    internal_reg_coa        text COLLATE pg_catalog."default" NOT NULL,
    balance_type            double precision NOT NULL,
    product_id              text COLLATE pg_catalog."default" NOT NULL,
    transaction_currency    text COLLATE pg_catalog."default" NOT NULL,
    transaction_amount      double precision NOT NULL,
    functional_amount       double precision NOT NULL,
    gl_account_1            double precision NOT NULL,
    gl_account_2            double precision NOT NULL,
    cost_centre             text COLLATE pg_catalog."default" NOT NULL,
    base_currency_amount    double precision NOT NULL,
    counter_party_customer  text COLLATE pg_catalog."default" NOT NULL,
    extension_id            text COLLATE pg_catalog."default" NOT NULL,
    issuer_customer_id      text COLLATE pg_catalog."default" NOT NULL,
    issuer_identifier       text COLLATE pg_catalog."default" NOT NULL,
    isin                    text COLLATE pg_catalog."default" NOT NULL
);

--Sequence for rule_dataset_params ID
DROP SEQUENCE IF EXISTS data.rule_dataset_params_id_seq CASCADE;
CREATE SEQUENCE data.rule_dataset_params_id_seq
    START WITH 1;

-- Drop table if exists
DROP TABLE IF EXISTS data.rule_dataset_params CASCADE;

  -- Create table
CREATE TABLE data.rule_dataset_params (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.rule_dataset_params_id_seq'::regclass),
    rule_id INT NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    dataset_nm VARCHAR(255) NOT NULL,
    param_name VARCHAR(255) NOT NULL,
    param_value TEXT NOT NULL,
    CONSTRAINT uq_rule_dataset_params_rule_ds_param UNIQUE (rule_id, user_id, dataset_nm, param_name)
);

DROP SEQUENCE IF EXISTS data.rule_exec_seq CASCADE;
CREATE SEQUENCE data.rule_exec_seq START 1;

DROP TABLE IF EXISTS data.rule_execution_run_control CASCADE;

CREATE TABLE IF NOT EXISTS data.rule_execution_run_control
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL DEFAULT nextval('data.rule_exec_seq'::regclass),
    period date NOT NULL,
    rule_name text COLLATE pg_catalog."default" NOT NULL,
    rule_version integer NOT NULL,
    exec_status text COLLATE pg_catalog."default",
    exec_msg text COLLATE pg_catalog."default",
    status_latest character(1) COLLATE pg_catalog."default",
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT rule_execution_run_control_pkey PRIMARY KEY (exec_id)
);

DROP TABLE IF EXISTS data.rpt_tax_fact CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_tax_fact
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL,
    report_version numeric NOT NULL,
    taxonomy_id text COLLATE pg_catalog."default" NOT NULL,
    value_num double precision,
    value_str text COLLATE pg_catalog."default",
    value_rpt double precision,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);

DROP TABLE IF EXISTS data.rpt_run_control CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_run_control
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL DEFAULT nextval('data.rule_exec_seq'::regclass),
    report_version numeric NOT NULL,
    node_id numeric NOT NULL,
    report_nm text COLLATE pg_catalog."default" NOT NULL,
    process text COLLATE pg_catalog."default",
    mode text COLLATE pg_catalog."default",
    status text COLLATE pg_catalog."default",
    error_msg text COLLATE pg_catalog."default",
    status_latest character(1) COLLATE pg_catalog."default",
    purged_flag character(1) COLLATE pg_catalog."default" DEFAULT 'N',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT rpt_run_control_pkey PRIMARY KEY (exec_id)
);

ALTER TABLE data.rpt_run_control
DROP COLUMN report_version,
ADD COLUMN period Date NOT NULL,
ADD COLUMN restatement_version integer NOT NULL DEFAULT 0;

DROP TABLE IF EXISTS data.rpt_run_control_audit CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_run_control_audit
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL,
    rule_name TEXT NOT NULL,
    rule_version NUMERIC NOT NULL,
    status TEXT,
    error_msg TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT rpt_run_control_audit_pkey PRIMARY KEY (client_id, exec_id, rule_name, rule_version),
    CONSTRAINT fk_rpt_run_control_client_exec FOREIGN KEY (exec_id)
        REFERENCES data.rpt_run_control (exec_id)
        ON DELETE CASCADE
);

-- ALTER SU TABLE
ALTER TABLE data.su_upload_control ADD COLUMN IF NOT EXISTS period VARCHAR;
ALTER TABLE data.su_upload_control ADD COLUMN IF NOT EXISTS upload_type VARCHAR;

UPDATE data.su_upload_control
SET period = '20250630',
    upload_type = 'SU';

ALTER TABLE data.su_upload_control ALTER COLUMN period SET NOT NULL;
ALTER TABLE data.su_upload_control ALTER COLUMN upload_type SET NOT NULL;

---
--Sequence for report_store_control ID
DROP SEQUENCE IF EXISTS data.report_store_control_id_seq CASCADE;
CREATE SEQUENCE data.report_store_control_id_seq
    START WITH 1;

--REPORT GENERATION CONTROL TABLE
DROP TABLE IF EXISTS data.report_store_control CASCADE;

CREATE TABLE data.report_store_control (
    client_id             INTEGER NOT NULL DEFAULT 1,
    id                    BIGINT PRIMARY KEY DEFAULT nextval('data.report_store_control_id_seq'::regclass),
    form_group            VARCHAR NOT NULL,
    form_name             VARCHAR NOT NULL,
    schedule_name         VARCHAR,
    sub_schedule_name     VARCHAR,
    report_version        INTEGER NOT NULL,
    report_generated_name VARCHAR,
    report_generated_path VARCHAR,
    status                VARCHAR NOT NULL,
	period                VARCHAR NOT NULL,
    restatement_version   INTEGER NOT NULL,
    created_by            VARCHAR NOT NULL,
    updated_by            VARCHAR NOT NULL,
    created_on            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE  data.rpt_run_control_audit ADD COLUMN pg_sync_msg VARCHAR DEFAULT NULL;

DROP TABLE IF EXISTS data.rpt_tax_fact_sbx CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_tax_fact_sbx
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL,
    report_version numeric NOT NULL,
    taxonomy_id text COLLATE pg_catalog."default" NOT NULL,
    value_num double precision,
    value_str text COLLATE pg_catalog."default",
    value_rpt double precision,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);

DROP TABLE IF EXISTS data.rpt_edit_check_fact CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_edit_check_fact
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL,
    report_version numeric NOT NULL,
    rule_name text COLLATE pg_catalog."default" NOT NULL,
    result VARCHAR,
    eval text COLLATE pg_catalog."default",
    fail_subset text COLLATE pg_catalog."default",
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);

DROP TABLE IF EXISTS data.rpt_edit_check_fact_sbx CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_edit_check_fact_sbx
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL,
    report_version numeric NOT NULL,
    rule_name text COLLATE pg_catalog."default" NOT NULL,
    result VARCHAR,
    eval text COLLATE pg_catalog."default",
    fail_subset text COLLATE pg_catalog."default",
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE data.rpt_edit_check_fact_sbx DROP COLUMN IF EXISTS report_version;
ALTER TABLE data.rpt_edit_check_fact_sbx ADD COLUMN IF NOT EXISTS period DATE NOT NULL;
ALTER TABLE data.rpt_edit_check_fact_sbx ADD COLUMN IF NOT EXISTS restatement_version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_edit_check_fact DROP COLUMN IF EXISTS report_version;
ALTER TABLE data.rpt_edit_check_fact ADD COLUMN IF NOT EXISTS period DATE NOT NULL;
ALTER TABLE data.rpt_edit_check_fact ADD COLUMN IF NOT EXISTS restatement_version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_tax_fact_sbx DROP COLUMN IF EXISTS report_version;
ALTER TABLE data.rpt_tax_fact_sbx ADD COLUMN IF NOT EXISTS period DATE NOT NULL;
ALTER TABLE data.rpt_tax_fact_sbx ADD COLUMN IF NOT EXISTS restatement_version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_tax_fact DROP COLUMN IF EXISTS report_version;
ALTER TABLE data.rpt_tax_fact ADD COLUMN IF NOT EXISTS period DATE NOT NULL;
ALTER TABLE data.rpt_tax_fact ADD COLUMN IF NOT EXISTS restatement_version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_tax_fact_sbx
ADD COLUMN rule_name VARCHAR DEFAULT NULL;

ALTER TABLE data.rpt_tax_fact
ADD COLUMN rule_name VARCHAR DEFAULT NULL;

ALTER TABLE data.rpt_edit_check_fact
ADD COLUMN edit_check_name VARCHAR DEFAULT NULL;

ALTER TABLE data.rpt_edit_check_fact_sbx
ADD COLUMN edit_check_name VARCHAR DEFAULT NULL;


DROP TABLE IF EXISTS data.dataset_refresh_audit CASCADE;

CREATE TABLE IF NOT EXISTS data.dataset_refresh_audit
(
    client_id INTEGER DEFAULT 1,
    dataset_key VARCHAR NOT NULL,
    period DATE NOT NULL,
    restatement_version INTEGER NOT NULL DEFAULT 0,
    exec_id INTEGER NOT NULL,
    is_active CHAR(1) DEFAULT 'Y',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT dataset_refresh_audit_pkey PRIMARY KEY (client_id, dataset_key, period, restatement_version, exec_id)
);

---
-- ADD restatement_version to su_upload_control
ALTER TABLE data.su_upload_control
ADD COLUMN restatement_version integer NOT NULL DEFAULT 0;

-- add version column for dataset params
ALTER TABLE data.rule_dataset_params
    ADD COLUMN version INTEGER;

-- backfill for existing rows
UPDATE data.rule_dataset_params SET version = 1;

-- enforce not null
ALTER TABLE data.rule_dataset_params
    ALTER COLUMN version SET NOT NULL;

-- add new constraint
ALTER TABLE data.rule_dataset_params
DROP CONSTRAINT IF EXISTS uq_rule_dataset_params_rule_ds_param;

ALTER TABLE data.rule_dataset_params
ADD CONSTRAINT uq_rule_dataset_params_rule_ds_param
UNIQUE (rule_id, version, user_id, dataset_nm, param_name);

------
DROP TYPE IF EXISTS data.adjustment_status CASCADE;

CREATE TYPE data.adjustment_status AS ENUM ('DRAFT','PENDING_APPROVAL','APPROVED','REJECTED','ARCHIVED');

DROP TABLE IF EXISTS data.rpt_topside_adjustments CASCADE;

CREATE TABLE IF NOT EXISTS data.rpt_topside_adjustments
(
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    taxonomy_id VARCHAR NOT NULL,
    period DATE NOT NULL,
    restatement_version INTEGER NOT NULL DEFAULT 0,
    tsa_val_num NUMERIC NOT NULL,
    tsa_val_str VARCHAR DEFAULT NULL,
    status data.adjustment_status NOT NULL DEFAULT 'DRAFT',
    description TEXT,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    PRIMARY KEY (client_id, node_id, period, restatement_version, taxonomy_id)
);

------------------
ALTER TABLE data.rpt_tax_fact
ADD COLUMN value_tsa double precision NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_tax_fact_sbx
ADD COLUMN value_tsa double precision NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS reason VARCHAR;
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS comments VARCHAR;
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS workflow_id INTEGER NOT NULL;
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS created_by VARCHAR(100) NOT NULL;
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS updated_by VARCHAR(100);


ALTER TABLE data.rpt_topside_adjustments
ADD COLUMN id BIGINT GENERATED ALWAYS AS IDENTITY;

-- Drop old primary key constraint
ALTER TABLE data.rpt_topside_adjustments
DROP CONSTRAINT rpt_topside_adjustments_pkey;

-- Add new primary key including id
ALTER TABLE data.rpt_topside_adjustments
ADD CONSTRAINT pk_rpt_topside_adjustments PRIMARY KEY (id, client_id, node_id, period, restatement_version, taxonomy_id);

ALTER TYPE data.adjustment_status ADD VALUE 'DISCARD';

DROP TABLE IF EXISTS data.tsa_impacted_elements CASCADE;
CREATE TABLE data.tsa_impacted_elements (
    tsa_id BIGINT NOT NULL,
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    taxonomy_id VARCHAR NOT NULL,
    period DATE NOT NULL,
    restatement_version INTEGER NOT NULL DEFAULT 0,
    impacted_lines JSONB NOT NULL,
    edit_check_break JSONB NOT NULL
);

DROP TABLE IF EXISTS data.rule_editcheck_mapping CASCADE;
CREATE TABLE IF NOT EXISTS data.rule_editcheck_mapping (
    client_id INTEGER DEFAULT 1,
    node_id INTEGER NOT NULL,
    rule_id INTEGER NOT NULL,
    rule_name VARCHAR NOT NULL,
    version INTEGER NOT NULL,
    period DATE NOT NULL,
    restatement_version INTEGER NOT NULL DEFAULT 0,
    edit_check_name VARCHAR NOT NULL,
    is_hard BOOLEAN DEFAULT TRUE
);

DROP SEQUENCE IF EXISTS data.adhoc_report_exec_seq CASCADE;
CREATE SEQUENCE data.adhoc_report_exec_seq START 1;

DROP TABLE IF EXISTS data.adhoc_rpt_run_control CASCADE;
CREATE TABLE IF NOT EXISTS data.adhoc_rpt_run_control
(
    client_id INTEGER DEFAULT 1,
    exec_id INTEGER NOT NULL DEFAULT nextval('data.adhoc_report_exec_seq'::regclass),
    table_name VARCHAR(100),
    column_count INTEGER,
    query TEXT,
    record_count INTEGER,
    time_taken INTERVAL,
    status text COLLATE pg_catalog."default",
    error_msg text COLLATE pg_catalog."default",
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by VARCHAR(100) NOT NULL,
    updated_by VARCHAR(100) NOT NULL
);

------------------ Tracking all kind of async apis ------------------

-- Drop async_request_tracker_seq if exists (schema-qualified)
DROP SEQUENCE IF EXISTS data.async_request_tracker_seq CASCADE;
-- Create sequence for exec_id in data schema
CREATE SEQUENCE IF NOT EXISTS data.async_request_tracker_seq
    START WITH 1;

-- Drop async_request_tracker if already exist (schema-qualified)
DROP TABLE IF EXISTS data.async_request_tracker CASCADE;

-- Create table in data schema
CREATE TABLE IF NOT EXISTS data.async_request_tracker (
    exec_id BIGINT NOT NULL DEFAULT nextval('data.async_request_tracker_seq'),
    end_point text NOT NULL,
    status text NOT NULL, -- e.g. Pending/Started/Failed/Completed
    status_msg text,
    result jsonb,         -- full resource/result (can be large)
    total_time_taken double precision,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT async_request_tracker_pkey PRIMARY KEY (exec_id)
);

-- Optional: index on status to help queries (schema-qualified)
CREATE INDEX IF NOT EXISTS idx_async_request_tracker_status ON data.async_request_tracker (status);

-- Optional: update trigger to refresh updated_at automatically (recommended)
CREATE OR REPLACE FUNCTION data.trg_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE data.adhoc_rpt_run_control
ADD COLUMN payload text COLLATE pg_catalog."default";

ALTER TABLE IF EXISTS data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS edit_check_break_exec_id bigint;

ALTER TABLE IF EXISTS data.su_upload_control ADD COLUMN upload_config JSONB DEFAULT '{}'::jsonb;

ALTER TABLE data.su_upload_control
ADD COLUMN IF NOT EXISTS file_metadata JSONB;

ALTER TABLE IF EXISTS data.regulatory_ledger_ds ADD COLUMN IF NOT EXISTS src_rec_seq bigint;
ALTER TABLE IF EXISTS data.financial_ledger_ds ADD COLUMN IF NOT EXISTS src_rec_seq bigint;
ALTER TABLE IF EXISTS data.deposit_ds ADD COLUMN IF NOT EXISTS src_rec_seq bigint;

ALTER TABLE data.adhoc_rpt_run_control ADD COLUMN IF NOT EXISTS period DATE ;

ALTER TABLE data.rpt_tax_fact
ADD COLUMN IF NOT EXISTS prov_id text;

ALTER TABLE data.rpt_run_control
ADD COLUMN is_prov_execution character(1) COLLATE pg_catalog."default" DEFAULT 'N';


--============================================================
-- Semantic Service
--============================================================

-- Drop existing objects so this script is fully re-runnable
DROP TABLE IF EXISTS meta.attribute CASCADE;
DROP TABLE IF EXISTS meta.logical_name CASCADE;
DROP TYPE IF EXISTS meta.attr_category CASCADE;

-- Create enum type in meta schema (idempotent DO block)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE t.typname = 'attr_category' AND n.nspname = 'meta'
    ) THEN
        EXECUTE 'CREATE TYPE meta.attr_category AS ENUM (''entity'', ''component'', ''rule'', ''measure'', ''other'')';
    END IF;
END$$;

-- Create a minimal table to hold logical names (only the text + timestamps)
CREATE TABLE IF NOT EXISTS meta.logical_name (
  id           BIGSERIAL PRIMARY KEY,
  logical_name TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ensure unique logical name (global)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'uq_logical_name'
    ) THEN
        EXECUTE format('CREATE UNIQUE INDEX %I ON %I.%I (%s)', 'uq_logical_name', 'meta', 'logical_name', 'logical_name');
    END IF;
END$$;

-- Create main attribute table (no textual logical_name column; it references logical_id)
CREATE TABLE IF NOT EXISTS meta.attribute (
  id               BIGSERIAL PRIMARY KEY,
  namespace        TEXT NOT NULL DEFAULT 'default',
  entity           TEXT NOT NULL,
  category         meta.attr_category NOT NULL DEFAULT 'entity',
  physical_name    TEXT NOT NULL,
  data_type        TEXT NOT NULL,
  description      TEXT NULL,
  source_system    TEXT NULL,
  created_by       TEXT NOT NULL DEFAULT 'System',
  updated_by       TEXT NOT NULL DEFAULT 'System',
  synonyms         TEXT[] DEFAULT '{}',
  tags             JSONB DEFAULT '[]'::jsonb,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  version          INTEGER NOT NULL DEFAULT 1,
  metadata         JSONB DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  logical_id       BIGINT REFERENCES meta.logical_name(id)
);

-- Create unique index: unique physical per namespace+entity
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'uq_attr_namespace_entity_physical'
    ) THEN
        EXECUTE format('CREATE UNIQUE INDEX %I ON %I.%I (%s)', 'uq_attr_namespace_entity_physical', 'meta', 'attribute', 'namespace, entity, physical_name');
    END IF;
END$$;

-- Create unique index on logical reference per namespace+entity
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'uq_attr_namespace_entity_logical'
    ) THEN
        EXECUTE format('CREATE UNIQUE INDEX %I ON %I.%I (%s)', 'uq_attr_namespace_entity_logical', 'meta', 'attribute', 'namespace, entity, logical_id');
    END IF;
END$$;

-- Full text search index (attributes only). If you want unified search across logical_name too, consider a materialized view.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'ix_attr_search_tsv'
    ) THEN
        EXECUTE format('CREATE INDEX %I ON %I.%I USING GIN (to_tsvector(''simple'', coalesce(namespace,'''') || '' '' || coalesce(entity,'''') || '' '' || coalesce(physical_name,'''') || '' '' || coalesce(description,'''') ))', 'ix_attr_search_tsv', 'meta', 'attribute');
    END IF;
END$$;

-- GIN index on tags
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'ix_attr_tags_gin'
    ) THEN
        EXECUTE format('CREATE INDEX %I ON %I.%I USING GIN (tags)', 'ix_attr_tags_gin', 'meta', 'attribute');
    END IF;
END$$;

-- GIN index on synonyms
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'ix_attr_synonyms_gin'
    ) THEN
        EXECUTE format('CREATE INDEX %I ON %I.%I USING GIN (synonyms)', 'ix_attr_synonyms_gin', 'meta', 'attribute');
    END IF;
END$$;

-- OPTIONAL: ensure a standard search index on logical names table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = 'meta' AND indexname = 'ix_logical_name_tsv'
    ) THEN
        EXECUTE format('CREATE INDEX %I ON %I.%I USING GIN (to_tsvector(''simple'', coalesce(logical_name,'''')))', 'ix_logical_name_tsv', 'meta', 'logical_name');
    END IF;
END$$;

-- End of script

--============================================================
-- Action Flow Tables
--============================================================
--  Drop table if it already exists (safe re-run)
DROP TABLE IF EXISTS data.rpt_aft_fact CASCADE;

--  Create table with required columns
CREATE TABLE data.rpt_aft_fact (
    aft_id TEXT,
    client_id INT,
    period DATE,
    node_id INT,
    group_id INT,
    rule_nm TEXT,
    edit_check_nm TEXT,
    edit_check_status TEXT,
    priority TEXT,
    action_status TEXT,
    recurrence_cnt INT,
    created_by TEXT,
    updated_by TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
PARTITION BY LIST (group_id);

ALTER TABLE data.rpt_aft_fact
ALTER COLUMN CREATED_AT SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE data.rpt_aft_fact
ALTER COLUMN UPDATED_AT SET DEFAULT CURRENT_TIMESTAMP;

--  Drop the sequence if it already exists
DROP SEQUENCE IF EXISTS data.rpt_aft_id_seq CASCADE;

--  Create the sequence
CREATE SEQUENCE data.rpt_aft_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    NO MAXVALUE
    CACHE 20;

--  Create the sequence
DROP SEQUENCE IF EXISTS data.rpt_aft_group_id_seq CASCADE;
CREATE SEQUENCE data.rpt_aft_group_id_seq
    INCREMENT BY 1
    START WITH 1000
    MINVALUE 1000
    NO MAXVALUE
    CACHE 20;
-- ============================================================
-- Table Name: rpt_aft_history
-- ============================================================

--  Drop the table if it already exists (safe for re-run)
DROP TABLE IF EXISTS data.rpt_aft_history CASCADE;

-- Create table
CREATE TABLE data.rpt_aft_history (
    exec_id INT,
    client_id INT,
    node_id INT,
    aft_id TEXT,
    group_id INT,
    rule_nm TEXT,
    edit_check_nm TEXT,
    edit_check_status TEXT,
    priority TEXT,
    action_status TEXT,
    created_by TEXT,
    updated_by TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
PARTITION BY LIST (group_id);


ALTER TABLE data.rpt_aft_history
ALTER COLUMN CREATED_AT SET DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX idx_rpt_aft_history_aftid ON data.rpt_aft_history (AFT_ID);
CREATE INDEX idx_rpt_aft_history_rule_nm ON data.rpt_aft_history (RULE_NM);
CREATE INDEX idx_rpt_aft_history_edit_check_status ON data.rpt_aft_history (EDIT_CHECK_STATUS);

DROP TABLE IF EXISTS data.rpt_aft_comments CASCADE;

CREATE TABLE data.rpt_aft_comments (
    aft_id TEXT,
    workflow_id INTEGER,
    workflow_status TEXT,
    comments TEXT,
    reason TEXT,
    created_by TEXT,
    updated_by TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_rpt_aft_comments
        FOREIGN KEY (workflow_id)
        REFERENCES data.workflow_detail(id)
        ON DELETE RESTRICT
);

------------------ AFT Tables - end --------

ALTER TABLE data.rpt_run_control
ADD COLUMN group_id integer NOT NULL DEFAULT 0;

ALTER TABLE data.rpt_aft_comments
    ALTER COLUMN workflow_id DROP NOT NULL;

ALTER TABLE data.rpt_aft_comments
    ADD COLUMN group_id integer NOT NULL DEFAULT 0;


ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS tsa_type VARCHAR(100);
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS remediation_plan DATE;
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS tsa_code VARCHAR(100);
ALTER TABLE data.rpt_topside_adjustments ADD COLUMN IF NOT EXISTS adjustment_computation VARCHAR(100);


DROP SEQUENCE IF EXISTS data.seq_rpt_aft_attachments;
CREATE SEQUENCE IF NOT EXISTS data.seq_rpt_aft_attachments START 1;

DROP TABLE IF EXISTS data.rpt_aft_attachments;
CREATE TABLE data.rpt_aft_attachments (
  id BIGINT NOT NULL DEFAULT nextval('data.seq_rpt_aft_attachments'::regclass),
  aft_id TEXT NOT NULL,
  group_id INTEGER NOT NULL,
  workflow_id INTEGER NULL,
  original_file_name TEXT NOT NULL,
  stored_file_name TEXT NOT NULL,
  file_extension TEXT,
  mime_type TEXT,
  file_size_bytes BIGINT,
  file_path TEXT NOT NULL,
  file_status TEXT NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, DELETED
  uploaded_by TEXT NOT NULL,
  uploaded_at TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT pk_rpt_aft_attachments PRIMARY KEY (id)
);

ALTER TABLE data.rpt_aft_comments ADD COLUMN IF NOT EXISTS action_status TEXT ;

ALTER TABLE data.rpt_aft_comments
    ADD COLUMN client_id INTEGER NOT NULL DEFAULT 1;

ALTER TABLE data.rpt_aft_attachments
    ADD COLUMN client_id INTEGER NOT NULL DEFAULT 1;

ALTER TABLE data.rpt_aft_attachments
    ADD COLUMN created_by TEXT NOT NULL;

ALTER TABLE data.rpt_aft_attachments
    ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT now();

ALTER TABLE data.rpt_aft_attachments
    RENAME COLUMN uploaded_by TO updated_by;

ALTER TABLE data.rpt_aft_attachments
    RENAME COLUMN uploaded_at TO updated_at;

ALTER TABLE data.report_store_control
    ADD COLUMN IF NOT EXISTS workflow_id INTEGER;

ALTER TABLE data.report_store_control
    ADD COLUMN IF NOT EXISTS workflow_status TEXT;

ALTER TABLE data.report_store_control
    ADD COLUMN IF NOT EXISTS comments TEXT;

-- Attestation - question answer

DROP SEQUENCE IF EXISTS data.attestation_records_seq CASCADE;
CREATE SEQUENCE data.attestation_records_seq START WITH 1 INCREMENT BY 1;

DROP TABLE IF EXISTS data.attestation_records CASCADE;

CREATE TABLE data.attestation_records (
  id BIGINT PRIMARY KEY DEFAULT nextval('data.attestation_records_seq'),
  client_id INTEGER NOT NULL,
  module_id BIGINT NOT NULL REFERENCES meta.module_master(id),
  workflow VARCHAR(64) NOT NULL,
  stage VARCHAR(64) NOT NULL,
  node_id INTEGER,
  entity_id VARCHAR(128) NOT NULL,
  question_answer_json JSONB NOT NULL,
  created_by VARCHAR(128) NOT NULL,
  created_on TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_by VARCHAR(128),
  updated_on TIMESTAMP WITH TIME ZONE,

  CONSTRAINT uq_attestation_records UNIQUE ( client_id, module_id, node_id, workflow, stage, entity_id)
);

DROP SEQUENCE IF EXISTS data.rpt_attachments_seq CASCADE;
CREATE SEQUENCE data.rpt_attachments_seq START WITH 1 INCREMENT BY 1;

DROP TABLE IF EXISTS data.rpt_attachments CASCADE;
CREATE TABLE data.rpt_attachments (
    id BIGINT PRIMARY KEY DEFAULT nextval('data.rpt_attachments_seq'),
    client_id INTEGER NOT NULL,

    file_name VARCHAR(512) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    storage_path TEXT NOT NULL,

    uploaded_by VARCHAR(255) NOT NULL,
    uploaded_on TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE data.attestation_records
    ADD COLUMN rpt_attachment_id BIGINT NULL,
  ADD CONSTRAINT fk_attestation_records_rpt_attachment
    FOREIGN KEY (rpt_attachment_id)
    REFERENCES data.rpt_attachments(id);

ALTER TABLE data.rpt_topside_adjustments
    ADD COLUMN IF NOT EXISTS pre_adjustment_value NUMERIC,
    ADD COLUMN IF NOT EXISTS post_adjustment_value NUMERIC,
    ADD COLUMN IF NOT EXISTS total_adjustment NUMERIC;

-- ============================================================
-- START | Report Generation and Recon | 25th March
-- ============================================================

-- Reuse the existing parent table for V2 and store the requested file types on the parent row.
ALTER TABLE data.report_store_control
    ADD COLUMN IF NOT EXISTS requested_file_types JSONB;

ALTER TABLE data.report_store_control
DROP COLUMN IF EXISTS report_generated_name,
DROP COLUMN IF EXISTS report_generated_path;

-- Child table for individual generated files under a shared parent report_store_control id.
DROP SEQUENCE IF EXISTS data.report_store_control_child_id_seq CASCADE;
CREATE SEQUENCE IF NOT EXISTS data.report_store_control_child_id_seq START WITH 1;

DROP TABLE IF EXISTS data.report_store_control_child CASCADE;
CREATE TABLE IF NOT EXISTS data.report_store_control_child (
    client_id             INTEGER NOT NULL DEFAULT 1,
    id                    BIGINT PRIMARY KEY DEFAULT nextval('data.report_store_control_child_id_seq'::regclass),
    report_store_control_id BIGINT NOT NULL REFERENCES data.report_store_control(id) ON DELETE CASCADE,
    file_type             VARCHAR NOT NULL,
    report_generated_name VARCHAR,
    report_generated_path VARCHAR,
    status                VARCHAR NOT NULL,
    reason                VARCHAR,
    created_by            VARCHAR NOT NULL,
    updated_by            VARCHAR NOT NULL,
    created_on            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_report_store_control_child UNIQUE (report_store_control_id, file_type)
);

DROP INDEX IF EXISTS idx_report_store_control_child_parent_id;
CREATE INDEX IF NOT EXISTS idx_report_store_control_child_parent_id
    ON data.report_store_control_child(report_store_control_id);

DROP INDEX IF EXISTS idx_report_store_control_child_status;
CREATE INDEX IF NOT EXISTS idx_report_store_control_child_status
    ON data.report_store_control_child(status);

-- RECON

-- Sequence for rpt_recon_control ID
DROP SEQUENCE IF EXISTS data.rpt_recon_control_id_seq CASCADE;
CREATE SEQUENCE data.rpt_recon_control_id_seq START WITH 1;

DROP TABLE IF EXISTS data.rpt_recon_control CASCADE;
CREATE TABLE IF NOT EXISTS data.rpt_recon_control (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.rpt_recon_control_id_seq'::regclass),
    report_id BIGINT NOT NULL,
    form_name TEXT NOT NULL,
    period TEXT NOT NULL,
    restatement_version INTEGER NOT NULL,
    status TEXT CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED')) DEFAULT 'IN_PROGRESS',
    reason TEXT,
    created_by TEXT NOT NULL DEFAULT current_user,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT current_user,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP INDEX IF EXISTS idx_rpt_recon_control_report_id;
CREATE INDEX IF NOT EXISTS idx_rpt_recon_control_report_id
    ON data.rpt_recon_control (report_id);

DROP INDEX IF EXISTS idx_rpt_recon_control_form_period;
CREATE INDEX IF NOT EXISTS idx_rpt_recon_control_form_period
    ON data.rpt_recon_control (form_name, period, restatement_version);

DROP SEQUENCE IF EXISTS data.rpt_recon_control_child_id_seq CASCADE;
CREATE SEQUENCE data.rpt_recon_control_child_id_seq START WITH 1;

DROP TABLE IF EXISTS data.rpt_recon_control_child CASCADE;
CREATE TABLE IF NOT EXISTS data.rpt_recon_control_child (
    client_id INTEGER DEFAULT 1,
    id BIGINT PRIMARY KEY DEFAULT nextval('data.rpt_recon_control_child_id_seq'::regclass),
    recon_report_id BIGINT NOT NULL REFERENCES data.rpt_recon_control(id) ON DELETE CASCADE,
    report_store_control_child_id BIGINT NOT NULL REFERENCES data.report_store_control_child(id) ON DELETE CASCADE,
    file_type TEXT NOT NULL,
    status TEXT CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED')) DEFAULT 'IN_PROGRESS',
    reason TEXT,
    recon_file_path TEXT,
    created_by TEXT NOT NULL DEFAULT current_user,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT current_user,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_rpt_recon_control_child UNIQUE (recon_report_id, report_store_control_child_id)
);

DROP INDEX IF EXISTS idx_rpt_recon_control_child_recon_report_id;
CREATE INDEX IF NOT EXISTS idx_rpt_recon_control_child_recon_report_id
    ON data.rpt_recon_control_child (recon_report_id);

DROP INDEX IF EXISTS idx_rpt_recon_control_child_report_store_child_id;
CREATE INDEX IF NOT EXISTS idx_rpt_recon_control_child_report_store_child_id
    ON data.rpt_recon_control_child (report_store_control_child_id);

ALTER TABLE data.rpt_recon_control
DROP CONSTRAINT IF EXISTS rpt_recon_control_status_check;

ALTER TABLE data.rpt_recon_control_child
DROP CONSTRAINT IF EXISTS rpt_recon_control_child_status_check;

-- ============================================================
-- END | Report Generation and Recon | 25th March
-- ============================================================



DROP TABLE IF EXISTS data.ledger_summary;

CREATE TABLE data.ledger_summary
(
    client_id             INTEGER DEFAULT 1,
    exec_id               INTEGER,
    ledger_id             TEXT,

    outstanding_balance   DOUBLE PRECISION,
    interest_income_ytd   DOUBLE PRECISION,
    charge_off_amount     DOUBLE PRECISION,

    created_at            TIMESTAMP(3) WITH TIME ZONE,
    updated_at            TIMESTAMP(3) WITH TIME ZONE,

    period                DATE,

    restatement_version   INTEGER DEFAULT 0,

    prov_id               TEXT,

    src_rec_seq           TEXT DEFAULT ''
);


ALTER TABLE data.rpt_aft_history
    ADD COLUMN IF NOT EXISTS workflow_status VARCHAR(255);

ALTER TABLE data.rpt_aft_history
    ADD COLUMN IF NOT EXISTS comments VARCHAR(255);