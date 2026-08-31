--Form Setup
--Common DB objects for all the forms
DROP TABLE IF EXISTS meta.resource_version;
CREATE TABLE IF NOT EXISTS meta.resource_version
(
    client_id INTEGER DEFAULT 1,
    uid character varying(100) COLLATE pg_catalog."default" NOT NULL,
    form_resource_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    resource_version character varying(100) COLLATE pg_catalog."default" NOT NULL,
    restatement_version numeric NOT NULL,
    template_location character varying(400) COLLATE pg_catalog."default" NOT NULL,
    total_pages numeric NOT NULL,
    active_status character(1) COLLATE pg_catalog."default",
    approval_status character(1) COLLATE pg_catalog."default",
    eff_from_date date,
    eff_to_date date,
    cob_date date,
    artifact_cr_id character varying(100) COLLATE pg_catalog."default",
    approval_id character varying(100) COLLATE pg_catalog."default",
    parent_resource_version_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    workflow_id character varying(30) COLLATE pg_catalog."default",
    status character varying(30) COLLATE pg_catalog."default" NOT NULL,
    lock_version character(1) COLLATE pg_catalog."default" NOT NULL,
    discard_flow character(1) COLLATE pg_catalog."default" NOT NULL,
    created_by character varying(20) COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by character varying(20) COLLATE pg_catalog."default",
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS meta.resource_page_detail;
CREATE TABLE IF NOT EXISTS meta.resource_page_detail (
    client_id INTEGER DEFAULT 1,
    uid character varying(100) COLLATE pg_catalog."default" NOT NULL,
    form_resource_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    form_resource_version character varying(100) COLLATE pg_catalog."default" NOT NULL,
	page_header_name character varying(100) COLLATE pg_catalog."default" NOT NULL,
	page_number numeric NOT NULL,
	schedule_name character varying(200)
);

DROP TABLE IF EXISTS meta.resource_page_taxonomy;
CREATE TABLE IF NOT EXISTS meta.resource_page_taxonomy (
    client_id INTEGER DEFAULT 1,
    uid character varying(100) COLLATE pg_catalog."default" NOT NULL,
    page_dtl_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
    taxonomy_id character varying(100) COLLATE pg_catalog."default" NOT NULL,
	taxonomy_mnemoic character varying(100)

);

DROP TABLE IF EXISTS meta.mdrm_dictionary;
CREATE TABLE IF NOT EXISTS meta.mdrm_dictionary
(
    client_id INTEGER DEFAULT 1,
    uid character varying(100) COLLATE pg_catalog."default" NOT NULL,
    mnemonic character varying(20) COLLATE pg_catalog."default" NOT NULL,
    item_code character varying(20) COLLATE pg_catalog."default" NOT NULL,
    start_date timestamp without time zone NOT NULL,
    end_Date timestamp without time zone NOT NULL,
    item_name character varying(400) COLLATE pg_catalog."default" NOT NULL,
    item_type character varying(400) COLLATE pg_catalog."default" NOT NULL,
    confidentiality character varying(1) COLLATE pg_catalog."default" NOT NULL,
    form_name character varying(20) COLLATE pg_catalog."default" NOT NULL,
    description text COLLATE pg_catalog."default",
    version character varying(20) COLLATE pg_catalog."default",
    series_glossary character varying(4000) COLLATE pg_catalog."default",
    created_by character varying(20) COLLATE pg_catalog."default" NOT NULL DEFAULT 'SYSTEM'::text,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_by character varying(20) COLLATE pg_catalog."default",
    update_at timestamp without time zone
);

DROP TABLE IF EXISTS meta.form_approach_configuration;
CREATE TABLE IF NOT EXISTS meta.form_approach_configuration
(
    client_id INTEGER DEFAULT 1,
    id INTEGER NOT NULL,
    form_name VARCHAR(255) NOT NULL,
    approach VARCHAR(50) NOT NULL,
    mnemonic VARCHAR(200),
    coordinates_required CHAR(1) DEFAULT 'N' CHECK (coordinates_required IN ('Y', 'N')),
    def_x_coordinate NUMERIC,
    def_y_coordinate NUMERIC,
    is_multi_taxonomy_form BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT form_configuration_pkey PRIMARY KEY (id),
    CONSTRAINT form_configuration_form_name_key UNIQUE (form_name)
);


DROP TABLE IF EXISTS meta.resource_page_taxonomy_metadata;
CREATE TABLE IF NOT EXISTS meta.resource_page_taxonomy_metadata (
   client_id INTEGER DEFAULT 1,
   uid numeric  NOT NULL,
   page_num numeric  NOT NULL,
   form_resource_NAME character varying(100)  NOT NULL,
   taxonomy_id character varying(100)  NOT NULL,
   orientation character varying(100) NOT NULL,
   occurrence bigint,
   pixel bigint,
   x_coordinate DOUBLE PRECISION,
   y_coordinate DOUBLE PRECISION
);

ALTER TABLE meta.resource_page_taxonomy ADD COLUMN PAGE_NUMBER INT;
ALTER TABLE meta.resource_page_taxonomy ADD COLUMN FORM_NAME VARCHAR(255);
