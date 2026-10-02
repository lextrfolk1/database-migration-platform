-- =============================================================================
-- V3: Knowledge Hub - documents, chunks, vectors, cross references, walks,
--     footnotes, drop profiles and document assurance
-- =============================================================================
-- Folds in old V1 (knowledge layer + KH ingestion columns), V22, V23, V24, V26, V41.
--
-- Two-table split: document_chunk holds parser ELEMENTS; embedding_chunk holds one
-- row per VECTOR (joined back through embedding_chunk_source); embedding_store
-- vectors reference embedding_chunk. Default physical dim = vector(384), CHECK-pinned.
-- =============================================================================

-- ---------------------------------------------------------------------
-- regulatory_document - parser output, one per section/table, plus the
-- Knowledge Hub ingestion header (hash, lifecycle, confirmed tier, version, description)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.regulatory_document (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    form_code       text NOT NULL,                  -- FRY9C, FFIEC031, ...
    source_type     intelligence.source_type NOT NULL,
    effective_date  date NOT NULL,
    schedule        text,
    section         text,
    line_item       text,
    mdrm_code       text,
    content         text NOT NULL,                  -- raw parsed text (pre-chunking)
    raw_source_path text,
    page_number     integer,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    content_sha256  CHAR(64),                       -- content integrity hash
    ingestion_status intelligence.kh_ingestion_status NOT NULL DEFAULT 'RECEIVED',
    classification  intelligence.data_classification,  -- human-confirmed document tier; NULL until confirmed
    version         VARCHAR(64),                    -- version/period label, distinct from effective_date
    description     text                            -- NULL = none given; never backfilled
);
CREATE INDEX reg_doc_form_idx ON intelligence.regulatory_document (client_id, form_code, effective_date);
CREATE INDEX reg_doc_mdrm_idx ON intelligence.regulatory_document (client_id, mdrm_code);
CREATE INDEX ix_regdoc_tenant_sha
    ON intelligence.regulatory_document (client_id, content_sha256);
CREATE INDEX ix_regdoc_tenant_status
    ON intelligence.regulatory_document (client_id, ingestion_status);

COMMENT ON COLUMN intelligence.regulatory_document.ingestion_status IS
    'Knowledge Hub lifecycle (kh_ingestion_status). Distinct from form_version.ingestion_status.';
COMMENT ON COLUMN intelligence.regulatory_document.description IS
    'LP-48 N1: the ingestion description the uploader gave. NULL = none given (rows before 2026-09-25 included); never backfilled.';

-- ---------------------------------------------------------------------
-- document_chunk - parser elements (parent/child). document_id is nullable:
-- WALK_PROCEDURE / client docs are not parsed regulatory_document rows.
-- Ids are DB-generated: insert parents first, read back ids, then children.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.document_chunk (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,
    document_id     bigint REFERENCES intelligence.regulatory_document (id),
    parent_chunk_id bigint REFERENCES intelligence.document_chunk (id),  -- NULL => this IS a parent
    doc_type        intelligence.doc_type NOT NULL,
    form_code       text,
    effective_date  date,
    schedule        text,
    section         text,
    line_item       text,
    mdrm_code       text,
    content         text NOT NULL,
    token_count     integer,
    chunk_index     integer,
    classification  intelligence.data_classification NOT NULL DEFAULT 'INTERNAL',
    metadata        jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_parent       boolean GENERATED ALWAYS AS (parent_chunk_id IS NULL) STORED,
    created_at      timestamptz NOT NULL DEFAULT now(),
    page_number     integer,
    element_type    text NOT NULL DEFAULT 'paragraph',
    table_ref       text,
    table_row       integer,
    table_col       integer,
    parent_path     text,
    text_source     text NOT NULL DEFAULT 'extracted',
    CONSTRAINT chk_doc_chunk_page_number
        CHECK (page_number IS NULL OR page_number > 0),
    CONSTRAINT chk_doc_chunk_table_ref
        CHECK (table_row IS NULL OR table_ref IS NOT NULL),
    CONSTRAINT chk_doc_chunk_row_col
        CHECK ((table_row IS NULL AND table_col IS NULL) OR (table_row IS NOT NULL AND table_col IS NOT NULL)),
    CONSTRAINT chk_doc_chunk_text_source
        CHECK (text_source IN ('extracted', 'ocr'))
);
CREATE INDEX doc_chunk_doc_idx    ON intelligence.document_chunk (document_id);
CREATE INDEX doc_chunk_parent_idx ON intelligence.document_chunk (parent_chunk_id);
CREATE INDEX doc_chunk_form_idx   ON intelligence.document_chunk (client_id, form_code, doc_type);
CREATE INDEX doc_chunk_mdrm_idx   ON intelligence.document_chunk (client_id, mdrm_code);

COMMENT ON COLUMN intelligence.document_chunk.classification IS 'Masking/governance tier. CONFIDENTIAL/RESTRICTED/MNPI/SENSITIVE are masked by the masking layer before any skill use; MNPI additionally forces local SLM via OPA. AI_PROHIBITED chunks must never be embedded, retrieved, or routed to a model — adapter/OPA hard-deny.';

-- ---------------------------------------------------------------------
-- embedding_chunk - one row per vector; embedding_chunk_source joins back to elements
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.embedding_chunk (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id            text NOT NULL,
    document_id          bigint REFERENCES intelligence.regulatory_document (id) ON DELETE CASCADE,
    content              text NOT NULL,
    token_count          integer NOT NULL,
    chunk_index          integer,
    page_number          integer,
    parent_path          text,
    table_ref            text,
    text_source          text NOT NULL DEFAULT 'extracted',
    oversize             boolean NOT NULL DEFAULT FALSE,
    content_sha256       text NOT NULL,
    drop_profile_id      text,
    drop_profile_version text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_emb_chunk_page_number CHECK (page_number IS NULL OR page_number > 0),
    CONSTRAINT chk_emb_chunk_text_source CHECK (text_source IN ('extracted', 'ocr', 'mixed'))
);

CREATE INDEX emb_chunk_doc_idx ON intelligence.embedding_chunk (document_id);
CREATE INDEX emb_chunk_client_idx ON intelligence.embedding_chunk (client_id);
CREATE INDEX emb_chunk_created_idx ON intelligence.embedding_chunk (created_at);

CREATE TABLE intelligence.embedding_chunk_source (
    embedding_chunk_id bigint NOT NULL REFERENCES intelligence.embedding_chunk (id) ON DELETE CASCADE,
    document_chunk_id  bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE RESTRICT,
    sequence_index     integer NOT NULL DEFAULT 0,
    PRIMARY KEY (embedding_chunk_id, document_chunk_id)
);

CREATE INDEX emb_chunk_src_doc_chunk_idx ON intelligence.embedding_chunk_source (document_chunk_id);

-- ---------------------------------------------------------------------
-- embedding_store - vectors. A non-384 model gets a sibling table embedding_store_<dim>.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.embedding_store (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     text NOT NULL,
    chunk_id      bigint NOT NULL,
    model_id      bigint NOT NULL REFERENCES intelligence.model_registry (id),  -- which embedder produced this
    embedding_dim integer NOT NULL DEFAULT 384,
    embedding     vector(384) NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT embedding_store_dim_chk CHECK (embedding_dim = 384),
    CONSTRAINT embedding_store_chunk_model_uq UNIQUE (chunk_id, model_id),
    CONSTRAINT fk_embedding_store_embedding_chunk
        FOREIGN KEY (chunk_id) REFERENCES intelligence.embedding_chunk (id) ON DELETE CASCADE
);
-- Cosine ANN. For high tenant counts consider per-tenant partial indexes or partitioning.
CREATE INDEX embedding_store_hnsw_idx
    ON intelligence.embedding_store USING hnsw (embedding vector_cosine_ops);
CREATE INDEX embedding_store_client_idx ON intelligence.embedding_store (client_id);

COMMENT ON TABLE intelligence.embedding_store IS 'Default physical dim = vector(384). Tenants on a non-384 model use a sibling table embedding_store_<dim>; embedding_dim/model_id pin provenance per row.';
COMMENT ON COLUMN intelligence.embedding_store.chunk_id IS 'References intelligence.embedding_chunk (id), one row per vector chunk.';

-- ---------------------------------------------------------------------
-- cross_reference - persisted MDRM lookup (form_code-scoped)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.cross_reference (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     text NOT NULL,
    form_code     text NOT NULL,
    mdrm_code     text NOT NULL,                    -- canonical, uppercase
    mnemonic      text,
    item_code     text,                             -- short code e.g. '4340'
    item_name     text,
    schedule      text,
    line_item     text,
    description   text,
    source_type   intelligence.source_type,
    authoritative boolean NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT cross_reference_uq UNIQUE (client_id, form_code, mdrm_code)
);
CREATE INDEX cross_ref_mdrm_idx     ON intelligence.cross_reference (client_id, mdrm_code);     -- _by_mdrm
CREATE INDEX cross_ref_line_idx     ON intelligence.cross_reference (client_id, line_item);     -- _by_line_item
CREATE INDEX cross_ref_schedule_idx ON intelligence.cross_reference (client_id, schedule);      -- _by_schedule
CREATE INDEX cross_ref_name_trgm_idx                                                            -- _by_name_words
    ON intelligence.cross_reference USING gin (item_name gin_trgm_ops);

-- ---------------------------------------------------------------------
-- form_version - ingestion lifecycle per (form, effective_date, artifact)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.form_version (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id        text NOT NULL,
    form_code        text NOT NULL,
    effective_date   date NOT NULL,
    artifact_type    intelligence.source_type NOT NULL,
    ingestion_status intelligence.ingestion_status NOT NULL DEFAULT 'pending',
    chunk_count      integer NOT NULL DEFAULT 0,
    ingested_at      timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT form_version_uq UNIQUE (client_id, form_code, effective_date, artifact_type)
);
CREATE INDEX form_version_status_idx ON intelligence.form_version (client_id, ingestion_status);

-- ---------------------------------------------------------------------
-- walk_mapping - curated across-report WALK reconciliation (UC5b).
-- Components reference MDRM codes logically (cross-store), not via FK.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.walk_mapping (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id           text NOT NULL,
    walk_key            text NOT NULL,
    version             integer NOT NULL DEFAULT 1,
    target_form_code    text NOT NULL,
    target_mdrm_code    text NOT NULL,
    target_schedule     text,
    components          jsonb NOT NULL,             -- [{form_code, mdrm_code, schedule, operator, basis, ref_id}]
    source_basis        text,
    procedure_chunk_ids bigint[] NOT NULL DEFAULT '{}',  -- document_chunk ids (doc_type='walk_procedure')
    status              intelligence.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by          text,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT walk_mapping_uq UNIQUE (client_id, walk_key, version)
);
CREATE INDEX walk_mapping_target_idx ON intelligence.walk_mapping (client_id, target_form_code, target_mdrm_code);

COMMENT ON TABLE intelligence.walk_mapping   IS 'Postgres-side curated across-report WALK reconciliation. Structural walk_component edges are owned by the Neo4j Knowledge Graph; components here reference MDRM codes logically (cross-store).';

-- ---------------------------------------------------------------------
-- Footnote association (chunk reference edges)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.chunk_reference (
    from_chunk_id  bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE CASCADE,
    to_chunk_id    bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE CASCADE,
    marker         varchar(64) NOT NULL,
    scope          varchar(64) NOT NULL,
    method         varchar(32) NOT NULL,
    client_id      varchar(64) NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_chunk_reference PRIMARY KEY (from_chunk_id, to_chunk_id, marker, client_id),
    CONSTRAINT chk_chunk_ref_no_self CHECK (from_chunk_id <> to_chunk_id),
    CONSTRAINT chk_chunk_ref_method CHECK (method IN ('superscript', 'inline'))
);

CREATE INDEX idx_chunk_ref_from ON intelligence.chunk_reference (client_id, from_chunk_id);
CREATE INDEX idx_chunk_ref_to ON intelligence.chunk_reference (client_id, to_chunk_id);

CREATE TABLE intelligence.chunk_reference_unresolved (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id       bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE CASCADE,
    marker         varchar(64) NOT NULL,
    scope          varchar(64) NOT NULL,
    reason         varchar(128) NOT NULL,
    client_id      varchar(64) NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chunk_ref_unres ON intelligence.chunk_reference_unresolved (client_id, chunk_id);

-- ---------------------------------------------------------------------
-- Drop profiles and per-document drop declarations
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.drop_profile (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id       varchar(64) NOT NULL,
    name            varchar(128) NOT NULL,
    doc_family      varchar(128) NOT NULL,
    status          varchar(32) NOT NULL DEFAULT 'ACTIVE',
    current_version integer NOT NULL DEFAULT 1,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_drop_profile_family UNIQUE (client_id, doc_family)
);

CREATE INDEX idx_drop_profile_client ON intelligence.drop_profile (client_id, doc_family);

CREATE TABLE intelligence.drop_profile_version (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      uuid NOT NULL REFERENCES intelligence.drop_profile (id) ON DELETE CASCADE,
    version         integer NOT NULL,
    client_id       varchar(64) NOT NULL,
    config_json     text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      varchar(64) NOT NULL,
    CONSTRAINT uq_drop_prof_ver UNIQUE (profile_id, version, client_id)
);

CREATE INDEX idx_drop_prof_ver ON intelligence.drop_profile_version (client_id, profile_id, version);

CREATE TABLE intelligence.drop_profile_ruling (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_version_id  uuid NOT NULL REFERENCES intelligence.drop_profile_version (id) ON DELETE CASCADE,
    client_id           varchar(64) NOT NULL,
    question_id         varchar(64) NOT NULL,
    ruling              varchar(32) NOT NULL,
    reason              text NOT NULL,
    author              varchar(64) NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_drop_ruling_ver ON intelligence.drop_profile_ruling (client_id, profile_version_id);

CREATE TABLE intelligence.document_drop_declaration (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id           varchar(64) NOT NULL,
    document_id         bigint NOT NULL,
    document_version_id text NOT NULL,
    scope               varchar(64) NOT NULL,
    reason              text NOT NULL,
    submitter           varchar(64) NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_doc_drop_decl ON intelligence.document_drop_declaration (client_id, document_id, document_version_id);

-- ---------------------------------------------------------------------
-- Document assurance - per-document runs and six-facet items, append-only
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.document_assurance_run (
    run_id VARCHAR(64) PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    document_id VARCHAR(64) NOT NULL,
    document_version_id VARCHAR(64) NOT NULL,
    drop_profile_version VARCHAR(64) NOT NULL,
    retrieval_mode VARCHAR(64) NOT NULL,
    as_of_date DATE NOT NULL,
    service_identity VARCHAR(64) NOT NULL DEFAULT 'svc.assurance',
    total_questions INT NOT NULL,
    verifiable_count INT NOT NULL,
    passed_count INT NOT NULL,
    pass_rate NUMERIC(5,4) NOT NULL,
    ablated_run BOOLEAN NOT NULL DEFAULT false,
    judgement_status VARCHAR(64) NOT NULL DEFAULT 'PENDING_REVIEW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(64) NOT NULL DEFAULT 'svc.assurance',
    CONSTRAINT chk_doc_assr_ver CHECK (length(trim(document_version_id)) > 0),
    CONSTRAINT chk_doc_assr_profile CHECK (length(trim(drop_profile_version)) > 0),
    CONSTRAINT chk_doc_assr_rate CHECK (pass_rate >= 0.0 AND pass_rate <= 1.0)
);

CREATE TABLE intelligence.document_assurance_item (
    item_id VARCHAR(64) PRIMARY KEY,
    run_id VARCHAR(64) NOT NULL REFERENCES intelligence.document_assurance_run(run_id),
    client_id VARCHAR(64) NOT NULL,
    question_id VARCHAR(64) NOT NULL,
    prompt TEXT NOT NULL,
    expected_anchor_id VARCHAR(64) NOT NULL,
    retrieved_anchor_id VARCHAR(64),
    anchor_matched BOOLEAN NOT NULL,
    rank INT,
    verifiable BOOLEAN NOT NULL,
    answered BOOLEAN NOT NULL,
    grounded BOOLEAN NOT NULL,
    value_present BOOLEAN NOT NULL,
    complete BOOLEAN NOT NULL,
    citation_ok BOOLEAN NOT NULL,
    confidence NUMERIC(5,4) NOT NULL,
    citation_doc_id VARCHAR(64),
    citation_page INT,
    citation_section VARCHAR(256),
    citation_content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_doc_assr_run_client_doc_ver
    ON intelligence.document_assurance_run (client_id, document_id, document_version_id);

CREATE INDEX idx_doc_assr_item_run
    ON intelligence.document_assurance_item (run_id, client_id);

CREATE OR REPLACE FUNCTION intelligence.fn_prevent_assurance_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Assurance records are append-only. Modification or deletion prohibited.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_assurance_run_mutation
    BEFORE UPDATE OR DELETE ON intelligence.document_assurance_run
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_assurance_mutation();

CREATE TRIGGER trg_prevent_assurance_item_mutation
    BEFORE UPDATE OR DELETE ON intelligence.document_assurance_item
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_assurance_mutation();
