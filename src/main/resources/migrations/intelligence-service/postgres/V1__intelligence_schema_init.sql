-- =============================================================================
-- Lextr Intelligence — `intelligence` schema DDL (FIXED CONTRACT)
-- =============================================================================
-- Product          : Lextr Intelligence (standalone, headless Vertical-AI product)
-- Source           : services/intelligence-service/src/main/resources/db/migration
--                    (upto_UC8 baseline) — embedded here VERBATIM, byte-for-byte.
-- Schema contract  : schema `intelligence`, 12 tables (model_registry, prompt_template,
--                    governance_envelope, preset, regulatory_document, document_chunk,
--                    embedding_store [vector(384)], cross_reference, form_version,
--                    walk_mapping, agent_run, agent_run_step) + UC1a seed + Knowledge-Hub
--                    ingestion + variance-SLM registration.
-- Tech stack       : PostgreSQL 16 + pgvector · SQL-first · Flyway-owned · no JPA
-- Writer boundary  : intelligence-service is the SOLE DB writer. lexie-ai holds NO DB
--                    grant and never persists — it emits RunResult for the service to write.
-- Tenancy          : client_id on scoped rows (never placed in a URL/query string);
--                    isolation enforced in OPA, not RLS.
-- Authorization    : ALL policy externalized to OPA/Rego (tool_scope, *_ready capability
--                    gates, cost_guardrails, embedding_call, masking egress, MRM/SoD).
--                    NO policy logic in the schema or the code.
-- Layer            : PRODUCT-SPECIFIC. Lextr Intelligence is its own product. The ONLY
--                    external surfaces are UPSTREAM/DOWNSTREAM objects it leverages from
--                    the Semantic Layer (C1/C9 exposure contract, regstruct.* gold copy)
--                    and Lextr Core (host adapter, element_dependency) — consumed
--                    read-only via the adapter, never redefined here.
-- =============================================================================
-- RING-FENCED CONTRACT. The team builds AGAINST this schema and MUST NOT alter it.
-- Apply via Flyway as the versioned migrations below (V1 baseline first).
-- =============================================================================
-- PART-M (naming/metadata standard) RECONCILIATION — DOWNSTREAM-ONLY.
--   This schema PRE-DATES the Part-M physical naming/metadata standard used by newer
--   Lextr schemas (<=32-char controlled abbreviations; canonical-datatype /
--   semantic-group / ai_*_txt / lifecycle columns; meta.* register-first catalogs).
--   Per the downstream-only rule it is embedded VERBATIM and is NOT rewritten. Any
--   Part-M delta (rename map, missing metadata columns, meta.* registration) is carried
--   as an OWNER-APPROVAL proposal / P-item — never silently applied. NEW tables/columns
--   this manifest proposes are authored Part-M-clean from the start.
-- =============================================================================



-- =============================================================================
-- MIGRATION: V1__intelligence_schema_init.sql  (V1 — schema baseline (12 tables))
-- =============================================================================
-- =====================================================================
-- Lextr Intelligence  |  intelligence schema  |  Flyway migration (DRAFT)
-- V1__intelligence_schema_init.sql
-- ---------------------------------------------------------------------
-- Deliverable #1 of the Foundation chat. Integration-ready DRAFT, not
-- production-ready: not yet run against the live stack/test suite.
-- Owned downstream by the development team for review/test/security/merge.
--
-- TARGET: PostgreSQL 14+ (GENERATED ALWAYS AS IDENTITY; HNSW needs pgvector 0.5+)
-- STACK ALIGNMENT: PostgreSQL + SQL scripts + Flyway (Tech Stack Overview).
--   DDL lives in Flyway migrations; runtime DAO SQL stays in
--   queries.properties via SQLQueryLoaderUtil (Engineering Reference Pack).
--
-- RESOLVED DECISIONS (agreed with SME):
--  D0  PRIMARY KEY TYPE = BIGINT GENERATED ALWAYS AS IDENTITY.
--      Matches the ERP GeneratedKeyHolder DAO template exactly. The Python
--      ingestion pipeline must therefore use DB-returned generated keys (insert
--      -> returning id) rather than minting uuid4 client-side; pipeline upserts
--      key on the natural unique constraints already defined per table
--      (e.g. document_chunk has no natural key, so ingestion inserts and reads
--      back the id — see note on document_chunk).
--  D1  TENANT ISOLATION = in-code at the Intelligence Core layer + the
--      DEPLOYMENT BOUNDARY. NO Postgres RLS. Authorization stays in OPA
--      (Blueprint Table 6; user preference: policy externalized in OPA).
--      Day-1 deployment model: Lextr Intelligence (the AI piece) is
--      SINGLE-TENANT PER DEPLOYMENT on customer infra — one AI instance serves
--      one tenant, so the deployment itself is the isolation boundary (stronger
--      than RLS; there is no second tenant in the same DB to protect against).
--  D2  MULTI-TENANT PROVISION IS BUILT IN, NOT DEFERRED. client_id stays
--      mandatory + indexed on every table, every Core query stays tenant-scoped
--      in code, and the adapter always passes client_id to the host. Reason: the
--      underlying DATA platform (Lextr Core / host) MAY be multi-tenant in a
--      single instance even while the AI piece is single-tenant per deploy, so
--      client_id is the live join key that lets one AI deployment address the
--      correct tenant slice of a multi-tenant host TODAY — not just future-proofing.
--      NOT built day 1: Postgres RLS, and the SaaS shared inference pool. A
--      hosted multi-tenant AI tier becomes an explicit later milestone; the
--      column + code scoping make that path additive, not a rewrite.
--  D3  Evidence ledger (agent_run / agent_run_step) lives in `intelligence`
--      (Fork A, agreed). SPEC §5 / Blueprint Table 12 references to a
--      `provenance` home are treated as superseded for this build.
--  D4  Embedding dimension (Fork B, agreed): physical default column is
--      vector(384); every row carries model_id + embedding_dim. A tenant on a
--      non-384 model gets a sibling table (embedding_store_<dim>) created by a
--      later migration — embedding_store is CHECK-pinned to 384 so a wider
--      model can never silently truncate here.
--  D5  Dimensions in the GPT4_Mode PDF (1536 / 768) are POC-mode and are NOT
--      used. Production = all-MiniLM-L6-v2 @ 384 (SPEC §8.4 / user constraint).
--
-- ADDED BEYOND THE NAMED LIST (transparent; reject if unwanted):
--  + governance_envelope — SPEC §1.2 makes the envelope a SEPARATE object from
--    the preset with its own versioning/MRM approval. `preset` references it;
--    without it the preset table is structurally incomplete.
--
-- DELIBERATELY DE-SCOPED for this deliverable (offered next turn):
--  - review_action (two-level review log, SPEC §5.2/5.3) + agent_run_source
--    (M:N senior-mgmt synthesis -> underlying analyst runs). Senior-management
--    synthesis is a senior-mgmt-mode feature (UC6 / Mode 2), which is M5+; no
--    M3-M4 use-case produces it. So parent_run_id (1:1 drill-down) is
--    SUFFICIENT for M3-M4; agent_run_source (M:N) is added when UC6 lands.
--    Review outcome is captured inline on agent_run; reviewer is recorded at
--    the RUN level (review is of the assembled output, not per step, §5.2).
--  - preset_style / guided_question / prompt_library_entry as normalized
--    child tables. Held as jsonb on `preset` for v1 (static per §1.3); promote
--    to tables when they need independent querying/versioning.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Schema rename (ai -> intelligence) and extensions
-- ---------------------------------------------------------------------
-- `ai` is confirmed greenfield/empty (Blueprint Table 22). Rename if present,
-- else create. Near-zero risk because there are no tables to migrate.
--
-- SCHEMA OWNERSHIP (D1/6.1): all DML on `intelligence` is performed by
-- `intelligence-service` under a dedicated schema-owner functional ID (FID)
-- holding DML rights on this schema; `lexie-ai` holds NO grant on the DB and
-- reaches persistence only via intelligence-service's HTTP API. This single
-- writer is what the BIGINT identity keys (D0) assume. GRANT/role statements
-- are environment-specific and owned by the dev/infra team — not issued here.
-- (If the team standardizes a specific FID name/role, swap it in at deploy.)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'intelligence')
  THEN
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS intelligence';
  END IF;
END
$$;

CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector: embedding_store
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- trigram lookup for cross_reference _by_name_words

SET search_path TO intelligence, public;

-- ---------------------------------------------------------------------
-- 1. Enumerated types (regulated product -> typed taxonomies)
-- ---------------------------------------------------------------------
CREATE TYPE intelligence.source_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form');                 -- PDF SourceType

CREATE TYPE intelligence.doc_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form', 'walk_procedure'); -- + WALK_PROCEDURE; extend via migration

CREATE TYPE intelligence.ingestion_status AS ENUM
    ('pending', 'ingesting', 'completed', 'failed');                          -- PDF FormVersion

CREATE TYPE intelligence.data_classification AS ENUM
    ('PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED', 'MNPI', 'SENSITIVE', 'AI_PROHIBITED'); -- masking §4.1 + KH MNPI
-- Enforcement model (the schema RECORDS the tier; it does NOT enforce it):
--   PUBLIC / INTERNAL ............ pass through unmasked.
--   CONFIDENTIAL / RESTRICTED .... masked by the masking layer (semantic form) before any skill sees them.
--   MNPI ......................... masked AND OPA forces local SLM (is_local=true) at all routing tiers; never external.
--   SENSITIVE .................... masked by the masking layer (e.g. specific provenance fields).
--   AI_PROHIBITED ................ HARD DENY: the adapter / Scoped Tool Registry never returns it and OPA blocks it.
--                                  It is never masked because it never reaches a skill. Recorded here so the ledger
--                                  and document_chunk.classification can mark content that must never be embedded,
--                                  retrieved, or routed to a model.

CREATE TYPE intelligence.model_type AS ENUM
    ('SLM', 'LLM', 'EMBEDDING', 'RERANKER');

CREATE TYPE intelligence.model_tier AS ENUM
    ('platform', 'tenant');                                                   -- routing tiers 1/2; tier 3 = preset override

CREATE TYPE intelligence.output_type AS ENUM
    ('narrative', 'dataset', 'chart', 'reconciliation', 'validation', 'impact_list', 'ranked_list'); -- §4 + use-case map

CREATE TYPE intelligence.skill_type AS ENUM
    ('SKILL_1', 'SKILL_2', 'SKILL_3');

CREATE TYPE intelligence.masking_type AS ENUM
    ('none', 'relative_change', 'entity_token', 'threshold_boolean', 'rank_ordinal', 'client_token'); -- masking §4.2

CREATE TYPE intelligence.run_status AS ENUM
    ('created', 'running', 'completed', 'in_review', 'accepted', 'corrected', 'rejected', 'failed');

CREATE TYPE intelligence.review_level AS ENUM
    ('analyst', 'senior_management');                                         -- SPEC §5.2

CREATE TYPE intelligence.review_decision AS ENUM
    ('accept', 'correct', 'reject');                                          -- SPEC §5.2

CREATE TYPE intelligence.preset_status AS ENUM
    ('draft', 'observed', 'operational', 'retired');                          -- distribution model §1.5

CREATE TYPE intelligence.envelope_status AS ENUM
    ('draft', 'pending_approval', 'approved', 'rejected', 'retired');         -- MRM states

CREATE TYPE intelligence.lifecycle_status AS ENUM
    ('draft', 'active', 'retired');                                           -- generic for templates/mappings/models

-- =====================================================================
-- 2. MODEL & GOVERNANCE LAYER
-- =====================================================================

-- ---------------------------------------------------------------------
-- model_registry — tenant-scoped, embedding-dim-aware (Blueprint Table 8)
-- Drives BaseLLMConnector resolution + the three-tier routing.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.model_registry (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id       text NOT NULL,                  -- '__platform__' sentinel for Tier-1 default rows
    tier            intelligence.model_tier NOT NULL DEFAULT 'tenant',
    model_type      intelligence.model_type NOT NULL,
    model_id        text NOT NULL,                  -- e.g. 'Qwen3-4B', 'sentence-transformers/all-MiniLM-L6-v2'
    connector_class text NOT NULL,                  -- e.g. 'QLoRAChatConnector', 'OpenAIConnector'
    adapter_path    text,                           -- QLoRA adapter path (SLM rows)
    embedding_model text,                           -- for SLM rows that pair an embedder; or self for EMBEDDING rows
    embedding_dim   integer,                        -- EMBEDDING/SLM rows; 384 today (Fork B)
    is_local        boolean NOT NULL,               -- false => OPA blocks call for MNPI/RESTRICTED/on-prem (SPEC §8)
    is_default      boolean NOT NULL DEFAULT false,
    params          jsonb NOT NULL DEFAULT '{}'::jsonb,  -- quantization=4bit NF4, lora_rank=16, alpha=32, temperature, max_tokens, enable_thinking=false ...
    secrets_ref     text,                           -- Vault/KMS key reference ONLY — never a credential (Table 8)
    status          intelligence.lifecycle_status NOT NULL DEFAULT 'active',
    created_by      text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT model_registry_embedding_dim_chk
        CHECK (embedding_dim IS NULL OR embedding_dim > 0),
    CONSTRAINT model_registry_uq UNIQUE (client_id, model_type, model_id)
);
-- At most one default per (tenant, model_type)
CREATE UNIQUE INDEX model_registry_one_default_uq
    ON intelligence.model_registry (client_id, model_type)
    WHERE is_default;
CREATE INDEX model_registry_client_idx ON intelligence.model_registry (client_id, model_type);

-- ---------------------------------------------------------------------
-- prompt_template — versioned model-instruction templates (Blueprint §4.3)
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.prompt_template (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     text NOT NULL,                    -- '__platform__' for Lextr-published base templates
    template_key  text NOT NULL,
    version       integer NOT NULL DEFAULT 1,
    task          text,                             -- task axis: variance_explanation, dq_check, ...
    report_type   text,                             -- report-type axis: Y-9C, Y-14Q-H, ...
    body          text NOT NULL,                    -- system prompt template (placeholder-templated)
    variables     jsonb NOT NULL DEFAULT '[]'::jsonb,
    status        intelligence.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by    text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT prompt_template_uq UNIQUE (client_id, template_key, version)
);
CREATE INDEX prompt_template_task_idx ON intelligence.prompt_template (client_id, task, report_type);

-- ---------------------------------------------------------------------
-- governance_envelope — MRM-approved envelope a preset lives inside (SPEC §1.2)
-- OPA policies are NOT stored here. Only the binding REFERENCE (package/id) is
-- stored; the Rego lives in OPA (user preference: policy externalized in OPA).
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.governance_envelope (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id            text NOT NULL,
    envelope_key         text NOT NULL,
    version              integer NOT NULL DEFAULT 1,
    status               intelligence.envelope_status NOT NULL DEFAULT 'draft',
    allowed_model_ids    bigint[] NOT NULL DEFAULT '{}',   -- references model_registry.id (array -> no FK by design)
    prohibited_model_ids bigint[] NOT NULL DEFAULT '{}',
    mnpi_rules           jsonb NOT NULL DEFAULT '{}'::jsonb,  -- data-access rules (which classifications/schemas)
    data_access          jsonb NOT NULL DEFAULT '{}'::jsonb,  -- allowed schemas / governance tiers (ALLOWED/RESTRICTED/EXCLUDED)
    cost_guardrails      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- e.g. OPA-COST-018 limits: max_tokens, max_cost_per_run
    opa_policy_bindings  jsonb NOT NULL DEFAULT '[]'::jsonb,  -- e.g. [{"id":"OPA-AI-001","package":"lextr.ai.model_routing"}]
    mrm_approved_by      text,
    mrm_approved_at      timestamptz,
    created_by           text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT governance_envelope_uq UNIQUE (client_id, envelope_key, version)
);
CREATE INDEX governance_envelope_status_idx ON intelligence.governance_envelope (client_id, status);

-- ---------------------------------------------------------------------
-- preset — packaged expert knowledge for a task x report-type (SPEC §1.3)
-- Lives inside a governance_envelope; carries the 5 preset elements.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.preset (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id            text NOT NULL,
    preset_key           text NOT NULL,
    version              integer NOT NULL DEFAULT 1,
    task                 text NOT NULL,             -- task axis
    report_type          text,                      -- report-type axis (null = report-agnostic)
    envelope_id          bigint NOT NULL REFERENCES intelligence.governance_envelope (id),
    -- Element 1 — model instruction (via template ref OR inline)
    prompt_template_id   bigint REFERENCES intelligence.prompt_template (id),
    model_instruction    text,
    -- Element 2..5
    complementary_context jsonb NOT NULL DEFAULT '{}'::jsonb,  -- Knowledge Hub asset refs (Element 2)
    style                jsonb NOT NULL DEFAULT '{}'::jsonb,    -- preset-level style override (Element 3 cascade)
    guided_questions     jsonb NOT NULL DEFAULT '[]'::jsonb,    -- Element 4
    prompt_library       jsonb NOT NULL DEFAULT '[]'::jsonb,    -- Element 5 (starter prompts)
    -- runtime contract
    model_id_override    bigint REFERENCES intelligence.model_registry (id),  -- Tier-3 preset model override
    skill_pattern        text,                      -- e.g. '1+3', '1+2', '1+2+3'
    is_agentic           boolean NOT NULL DEFAULT false,
    max_steps            smallint NOT NULL DEFAULT 6,   -- Skill 3 cap (SPEC §2.3)
    kg_depth_default     smallint NOT NULL DEFAULT 3,   -- Skill 2 depth (SPEC §2.2)
    kg_depth_max         smallint NOT NULL DEFAULT 5,
    output_type          intelligence.output_type,
    review_level         intelligence.review_level NOT NULL DEFAULT 'analyst',
    status               intelligence.preset_status NOT NULL DEFAULT 'draft',
    is_global            boolean NOT NULL DEFAULT false,  -- Lextr-published base preset
    forked_from          bigint REFERENCES intelligence.preset (id),  -- client fork of a global preset
    created_by           text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT preset_uq UNIQUE (client_id, preset_key, version),
    CONSTRAINT preset_max_steps_chk CHECK (max_steps BETWEEN 1 AND 8),       -- SPEC: cannot exceed 8
    CONSTRAINT preset_kg_depth_chk  CHECK (kg_depth_default >= 1 AND kg_depth_max BETWEEN kg_depth_default AND 5)
);
CREATE INDEX preset_axis_idx     ON intelligence.preset (client_id, task, report_type);
CREATE INDEX preset_envelope_idx ON intelligence.preset (envelope_id);
CREATE INDEX preset_status_idx   ON intelligence.preset (client_id, status);

-- =====================================================================
-- 3. KNOWLEDGE / GROUNDING LAYER  (PDF data models as starting design)
-- =====================================================================

-- ---------------------------------------------------------------------
-- regulatory_document — parser output, one per section/table (PDF §1)
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
    updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX reg_doc_form_idx ON intelligence.regulatory_document (client_id, form_code, effective_date);
CREATE INDEX reg_doc_mdrm_idx ON intelligence.regulatory_document (client_id, mdrm_code);

-- ---------------------------------------------------------------------
-- document_chunk — parent/child chunks (PDF §2). doc_type incl. walk_procedure.
-- document_id is nullable: WALK_PROCEDURE / Knowledge-Hub client docs are not
-- parsed regulatory_document rows.
-- BIGINT identity note (D0): ids are DB-generated, so the ingestion pipeline
-- must insert PARENT chunks first, read back their ids (insert ... returning id),
-- then insert child chunks with parent_chunk_id set — it cannot pre-mint the
-- self-reference client-side as it did with uuid4. Within a batch, order by
-- parent-before-child.
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
    classification  intelligence.data_classification NOT NULL DEFAULT 'INTERNAL',  -- KH classification
    metadata        jsonb NOT NULL DEFAULT '{}'::jsonb,  -- flat metadata contract (PDF §2)
    is_parent       boolean GENERATED ALWAYS AS (parent_chunk_id IS NULL) STORED,
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX doc_chunk_doc_idx    ON intelligence.document_chunk (document_id);
CREATE INDEX doc_chunk_parent_idx ON intelligence.document_chunk (parent_chunk_id);
CREATE INDEX doc_chunk_form_idx   ON intelligence.document_chunk (client_id, form_code, doc_type);
CREATE INDEX doc_chunk_mdrm_idx   ON intelligence.document_chunk (client_id, mdrm_code);

-- ---------------------------------------------------------------------
-- embedding_store — child-chunk vectors. Default physical dim = 384 (Fork B).
-- Divergent-dim tenants get a sibling table embedding_store_<dim> (later
-- migration). The CHECK guarantees no wider vector lands here by mistake.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.embedding_store (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     text NOT NULL,
    chunk_id      bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE CASCADE,
    model_id      bigint NOT NULL REFERENCES intelligence.model_registry (id),  -- which embedder produced this (Fork B)
    embedding_dim integer NOT NULL DEFAULT 384,
    embedding     vector(384) NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT embedding_store_dim_chk CHECK (embedding_dim = 384),
    CONSTRAINT embedding_store_chunk_model_uq UNIQUE (chunk_id, model_id)
);
-- Cosine ANN (PDF distance metric). For high tenant counts, consider partial
-- per-tenant indexes or partitioning — flagged, not done here.
CREATE INDEX embedding_store_hnsw_idx
    ON intelligence.embedding_store USING hnsw (embedding vector_cosine_ops);
CREATE INDEX embedding_store_client_idx ON intelligence.embedding_store (client_id);

-- ---------------------------------------------------------------------
-- cross_reference — persisted MDRM lookup (PDF §7 MdrmEntry).
-- POC kept this in RAM; persisted here (any runtime cache is derived from it).
-- form_code included so the same item_code resolves correctly ACROSS reports.
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
    authoritative boolean NOT NULL DEFAULT false,   -- merge semantics (PDF §7)
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
-- form_version — ingestion lifecycle per (form, effective_date, artifact) (PDF §8)
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
-- walk_mapping — across-report WALK reconciliation (UC5b).
-- The STRUCTURAL cross-report aggregation edges (walk_component) live in the
-- Knowledge Graph (Neo4j). This table is the Postgres-side CURATED mapping:
-- target line = ordered components, sourced from edit checks / rules / business
-- procedure, plus links to WALK_PROCEDURE chunks (the interpretive methodology).
-- Components reference MDRM codes logically (cross-store), not via FK.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.walk_mapping (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id           text NOT NULL,
    walk_key            text NOT NULL,              -- e.g. 'Y9C_TOTAL_LOANS'
    version             integer NOT NULL DEFAULT 1,
    target_form_code    text NOT NULL,              -- FRY9C
    target_mdrm_code    text NOT NULL,              -- the number being reconciled
    target_schedule     text,
    components          jsonb NOT NULL,             -- [{form_code, mdrm_code, schedule, operator:add|subtract, basis:edit_check|rule|procedure, ref_id}]
    source_basis        text,                       -- edit_check | rule | business_procedure | mixed
    procedure_chunk_ids bigint[] NOT NULL DEFAULT '{}',  -- document_chunk ids (doc_type='walk_procedure')
    status              intelligence.lifecycle_status NOT NULL DEFAULT 'draft',
    created_by          text,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT walk_mapping_uq UNIQUE (client_id, walk_key, version)
);
CREATE INDEX walk_mapping_target_idx ON intelligence.walk_mapping (client_id, target_form_code, target_mdrm_code);

-- =====================================================================
-- 4. EVIDENCE LEDGER  (Fork A: lives in intelligence)
-- =====================================================================

-- ---------------------------------------------------------------------
-- agent_run — one row per Intelligence call (the run header + review outcome)
-- Holds the structured output + placeholder map (handover protocol §4.4).
-- part1_context stores the MASKED/structured context only — never raw
-- RESTRICTED values.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id              text NOT NULL,              -- human-readable, e.g. 'run_20250527_001'
    client_id           text NOT NULL,
    preset_id           bigint REFERENCES intelligence.preset (id),
    preset_version      integer,                    -- snapshot at run time
    model_id            bigint REFERENCES intelligence.model_registry (id),  -- model actually used
    use_case            text,                       -- UC1a, UC2, ...
    intent              text,                       -- variance_explanation, impact_analysis, ...
    skill_pattern       text,
    part1_context       jsonb,                      -- structured API/process context (masked)
    part3_user_input    text,                       -- analyst enrichment (Part 3, optional)
    output              jsonb,                      -- {analysis, placeholders{}, confidence_score, evidence_trace_id}
    output_type         intelligence.output_type,
    confidence_score    numeric(4,3),
    status              intelligence.run_status NOT NULL DEFAULT 'created',
    observed_mode       boolean NOT NULL DEFAULT true,  -- observed mode is the default (§1.5)
    evidence_trace_id   text,
    -- review outcome (run-level; reviewer recorded here — review is of the output)
    review_level        intelligence.review_level,
    reviewer_id         text,
    reviewer_role       text,
    review_decision     intelligence.review_decision,
    review_rationale    text,
    correction          jsonb,                      -- corrected output, if decision = correct
    confidence_at_review numeric(4,3),
    reviewed_at         timestamptz,
    parent_run_id       bigint REFERENCES intelligence.agent_run (id),  -- senior-mgmt synthesis -> analyst run (1:1 drill-down)
    user_id             text,                       -- requesting user
    started_at          timestamptz,
    completed_at        timestamptz,
    duration_ms         integer,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT agent_run_run_id_uq UNIQUE (client_id, run_id),
    CONSTRAINT agent_run_conf_chk CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
    CONSTRAINT agent_run_conf_rev_chk CHECK (confidence_at_review IS NULL OR confidence_at_review BETWEEN 0 AND 1)
);
CREATE INDEX agent_run_status_idx ON intelligence.agent_run (client_id, status);
CREATE INDEX agent_run_preset_idx ON intelligence.agent_run (preset_id);
CREATE INDEX agent_run_parent_idx ON intelligence.agent_run (parent_run_id);

-- ---------------------------------------------------------------------
-- agent_run_step — the per-step evidence ledger (SPEC §5).
-- Records masking applied, data classification, model used, output type.
-- Reviewer is rolled up at the run level (agent_run) per SPEC §5.2.
-- ---------------------------------------------------------------------
CREATE TABLE intelligence.agent_run_step (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trace_id           text NOT NULL,               -- e.g. 'evt_20250527_HC-C_BHCK2150_001'
    run_id             bigint NOT NULL REFERENCES intelligence.agent_run (id) ON DELETE CASCADE,
    client_id          text NOT NULL,
    step_number        smallint NOT NULL,
    step_name          text NOT NULL,
    skill              intelligence.skill_type,
    tool_called        text,
    input              jsonb,
    output_summary     text,
    output_node_count  integer,
    masking_applied    boolean NOT NULL DEFAULT false,
    masking_types      intelligence.masking_type[] NOT NULL DEFAULT '{}',  -- which masks (richer than §5 boolean)
    data_classification intelligence.data_classification,
    model_id           bigint REFERENCES intelligence.model_registry (id),    -- model used at this step (if any)
    output_type        intelligence.output_type,
    preset_id          bigint,                         -- snapshot
    user_id            text,
    "timestamp"        timestamptz NOT NULL DEFAULT now(),
    duration_ms        integer,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT agent_run_step_uq UNIQUE (run_id, step_number)
);
CREATE INDEX agent_run_step_run_idx   ON intelligence.agent_run_step (run_id);
CREATE INDEX agent_run_step_trace_idx ON intelligence.agent_run_step (trace_id);

-- ---------------------------------------------------------------------
-- Selected table comments for the dev team
-- ---------------------------------------------------------------------
COMMENT ON TABLE intelligence.agent_run      IS 'Evidence ledger header: one row per Intelligence call. Output stores placeholder tokens only; raw RESTRICTED values are resolved at render by the reporting layer under entitlement.';
COMMENT ON TABLE intelligence.agent_run_step IS 'Per-step evidence ledger (MRM explainability artifact). The full trace is written before any output surfaces to a human reviewer.';
COMMENT ON TABLE intelligence.walk_mapping   IS 'Postgres-side curated across-report WALK reconciliation. Structural walk_component edges are owned by the Neo4j Knowledge Graph; components here reference MDRM codes logically (cross-store).';
COMMENT ON TABLE intelligence.embedding_store IS 'Default physical dim = vector(384). Tenants on a non-384 model use a sibling table embedding_store_<dim>; embedding_dim/model_id pin provenance per row.';
COMMENT ON COLUMN intelligence.model_registry.is_local IS 'False blocks external model calls for MNPI/RESTRICTED data and on-prem deployments (OPA-enforced). True (local SLM) always permitted.';
COMMENT ON COLUMN intelligence.governance_envelope.opa_policy_bindings IS 'Reference to OPA policy packages/ids only. Rego policy is externalized in OPA, never stored in the DB.';
COMMENT ON COLUMN intelligence.document_chunk.classification IS 'Masking/governance tier. CONFIDENTIAL/RESTRICTED/MNPI/SENSITIVE are masked by the masking layer before any skill use; MNPI additionally forces local SLM via OPA. AI_PROHIBITED chunks must never be embedded, retrieved, or routed to a model — adapter/OPA hard-deny.';

-- =====================================================================
-- END V1__intelligence_schema_init.sql
-- =====================================================================


-- =============================================================================
-- MIGRATION: V2__uc1a_seed.sql  (V2 — UC1a runnable seed)
-- =============================================================================
-- =====================================================================
-- V2__uc1a_seed.sql  |  Lextr Intelligence  |  UC1a runnable seed (D1)
-- ---------------------------------------------------------------------
-- Purpose: give the thinnest end-to-end path (UC1a — Variance horizontal,
-- skill_pattern 1+3, no-KG, M3) a preset/envelope/model set to resolve,
-- BEFORE the 7-step wizard (D7) can author presets. This is a SEED, not a
-- fixture: idempotent (guarded by the natural unique keys), safe to re-run.
--
-- Tenants:
--   '__platform__'  Tier-1 platform default model rows (SLM + embedder).
--   'client_001'    demo tenant carrying the UC1a envelope + preset
--                   (matches the SPEC's example client_001).
--
-- DB-generated BIGINT identity keys (D0): we cannot pre-mint ids, so each
-- dependent insert resolves its FK via a sub-SELECT on the parent's natural
-- unique key. All FK targets are created earlier in this same migration.
--
-- FLAGS (see chat): (a) preset.is_agentic=true for the 1+3 row, aligning to
-- the only concrete run-payload example (arch §4.4); the decision table's
-- finer "simple-agentic vs bounded-agentic" split is carried by skill_pattern
-- + max_steps, not this boolean. (b) status='operational' so the seed is
-- runnable now; wizard-authored presets follow draft -> observed -> operational.
-- (c) report_type='Y-9C' (the taxonomy key); the Trigger API (D2) normalizes
-- the runtime part1.report ('Y9C') to this key during resolution.
-- =====================================================================

SET search_path TO intelligence, public;

-- ---------------------------------------------------------------------
-- 1. Platform Tier-1 default SLM (Qwen3-4B + QLoRA) — generation.
-- ---------------------------------------------------------------------
INSERT INTO intelligence.model_registry
    (client_id, tier, model_type, model_id, connector_class, adapter_path,
     embedding_model, embedding_dim, is_local, is_default, params, status, created_by)
SELECT '__platform__', 'platform', 'SLM', 'Qwen3-4B', 'QLoRAChatConnector',
       'data/qlora_adapter/qwen3-4b-fry9c/final', NULL, NULL, true, true,
       '{"quantization":"4bit_nf4","lora_rank":16,"alpha":32,"temperature":0.2,"max_tokens":1024,"enable_thinking":false}'::jsonb,
       'active', 'seed'
WHERE NOT EXISTS (
    SELECT 1 FROM intelligence.model_registry
    WHERE client_id = '__platform__' AND model_type = 'SLM' AND model_id = 'Qwen3-4B');

-- ---------------------------------------------------------------------
-- 2. Platform Tier-1 default embedder (all-MiniLM-L6-v2, 384) — declared
--    now for registry completeness; first EXERCISED at D8 (retrieval).
-- ---------------------------------------------------------------------
INSERT INTO intelligence.model_registry
    (client_id, tier, model_type, model_id, connector_class, adapter_path,
     embedding_model, embedding_dim, is_local, is_default, params, status, created_by)
SELECT '__platform__', 'platform', 'EMBEDDING', 'sentence-transformers/all-MiniLM-L6-v2',
       'MiniLMEmbeddingConnector', NULL, 'sentence-transformers/all-MiniLM-L6-v2', 384,
       true, true, '{}'::jsonb, 'active', 'seed'
WHERE NOT EXISTS (
    SELECT 1 FROM intelligence.model_registry
    WHERE client_id = '__platform__' AND model_type = 'EMBEDDING'
      AND model_id = 'sentence-transformers/all-MiniLM-L6-v2');

-- ---------------------------------------------------------------------
-- 3. Governance envelope (MRM-approved) for variance on Y-9C.
--    allowed_model_ids -> the platform SLM. cost_guardrails read by the
--    pre-run OPA gate (D2). opa_policy_bindings = REFERENCES only (Rego
--    lives in policy-service).
-- ---------------------------------------------------------------------
INSERT INTO intelligence.governance_envelope
    (client_id, envelope_key, version, status, allowed_model_ids, prohibited_model_ids,
     mnpi_rules, data_access, cost_guardrails, opa_policy_bindings,
     mrm_approved_by, mrm_approved_at, created_by)
SELECT 'client_001', 'ENV_VARIANCE_Y9C', 1, 'approved',
       ARRAY[(SELECT id FROM intelligence.model_registry
              WHERE client_id = '__platform__' AND model_type = 'SLM' AND model_id = 'Qwen3-4B')]::bigint[],
       '{}'::bigint[],
       '{"external_forbidden_classifications":["RESTRICTED","MNPI"]}'::jsonb,
       '{"allowed_tiers":["ALLOWED","RESTRICTED"],"excluded_never_returned":true}'::jsonb,
       '{"max_tokens_per_run":4096,"max_cost_per_run_usd":0.50}'::jsonb,
       '[{"id":"OPA-AI-001","package":"lextr.ai.model_routing"},{"id":"OPA-COST-018","package":"lextr.ai.cost_guardrails"}]'::jsonb,
       'seed_mrm', now(), 'seed'
WHERE NOT EXISTS (
    SELECT 1 FROM intelligence.governance_envelope
    WHERE client_id = 'client_001' AND envelope_key = 'ENV_VARIANCE_Y9C' AND version = 1);

-- ---------------------------------------------------------------------
-- 4. Prompt template (Element 1) for variance explanation on Y-9C.
-- ---------------------------------------------------------------------
INSERT INTO intelligence.prompt_template
    (client_id, template_key, version, task, report_type, body, variables, status, created_by)
SELECT 'client_001', 'TPL_VARIANCE_Y9C', 1, 'variance_explanation', 'Y-9C',
       'You are a regulatory reporting analyst assistant. Explain the period-over-period change in the referenced line using ONLY the masked values, complementary context, and analyst input provided. Reference entities by their placeholder tokens (e.g. {{ENTITY_1_LABEL}}); never invent figures. Cite drivers explicitly (rule change / strategy / market event) where the evidence supports them; state uncertainty otherwise.',
       '["report","schedule","mdrm","period","masked_values","complementary_context","analyst_input"]'::jsonb,
       'active', 'seed'
WHERE NOT EXISTS (
    SELECT 1 FROM intelligence.prompt_template
    WHERE client_id = 'client_001' AND template_key = 'TPL_VARIANCE_Y9C' AND version = 1);

-- ---------------------------------------------------------------------
-- 5. The UC1a preset — variance_explanation x Y-9C, skill_pattern 1+3,
--    no Tier-3 model override (resolves to platform SLM via tenant->platform).
--    kg_depth_* keep schema defaults (CHECK >= 1); unused (no Skill 2 on 1+3).
-- ---------------------------------------------------------------------
INSERT INTO intelligence.preset
    (client_id, preset_key, version, task, report_type, envelope_id,
     prompt_template_id, model_instruction, complementary_context, style,
     guided_questions, prompt_library, model_id_override, skill_pattern,
     is_agentic, max_steps, kg_depth_default, kg_depth_max, output_type,
     review_level, status, is_global, created_by)
SELECT 'client_001', 'UC1A_VARIANCE_Y9C', 1, 'variance_explanation', 'Y-9C',
       (SELECT id FROM intelligence.governance_envelope
        WHERE client_id = 'client_001' AND envelope_key = 'ENV_VARIANCE_Y9C' AND version = 1),
       (SELECT id FROM intelligence.prompt_template
        WHERE client_id = 'client_001' AND template_key = 'TPL_VARIANCE_Y9C' AND version = 1),
       NULL,
       '{"knowledge_hub_refs":[]}'::jsonb,
       '{}'::jsonb,
       '[]'::jsonb,
       '[]'::jsonb,
       NULL,
       '1+3',
       true,
       6,
       3, 5,
       'narrative',
       'analyst',
       'operational',
       false,
       'seed'
WHERE NOT EXISTS (
    SELECT 1 FROM intelligence.preset
    WHERE client_id = 'client_001' AND preset_key = 'UC1A_VARIANCE_Y9C' AND version = 1);

-- =====================================================================
-- END V2__uc1a_seed.sql
-- =====================================================================


-- =============================================================================
-- MIGRATION: V9__knowledge_hub_ingestion.sql  (V9 — Knowledge Hub ingestion (D1))
-- =============================================================================
-- =====================================================================
-- V9__knowledge_hub_ingestion.sql   (D1 — Knowledge Hub ingestion)
-- RENUMBER to your next free Flyway version before merge.
--
-- ADDITIVE + NON-DESTRUCTIVE over the frozen intelligence schema. Builds over the
-- three existing tables (regulatory_document -> document_chunk -> embedding_store).
-- Does NOT create a knowledge_hub table (A1). Does NOT create source_type /
-- effective_date (those are frozen, already present on regulatory_document).
--
-- Four additive columns on regulatory_document:
--   (1) content_sha256       — A5 content hash (confirmed)
--   (2) ingestion_status     — lifecycle (flagged; header-less docs use chunk metadata)
--   (3) classification       — document-level confirmed tier (reconcile decision)
--   (4) version              — version/period label (reconcile decision)
-- =====================================================================

SET search_path TO intelligence, public;

-- (1) Content integrity hash (A5). Nullable here for migration-safety on a populated
--     table; backfill, then enforce NOT NULL in a follow-up. New ingests always set it.
ALTER TABLE intelligence.regulatory_document
    ADD COLUMN IF NOT EXISTS content_sha256 CHAR(64);

CREATE INDEX IF NOT EXISTS ix_regdoc_tenant_sha
    ON intelligence.regulatory_document (client_id, content_sha256);

-- (2) Ingestion lifecycle status + column.
-- Reuse the existing enum to keep the baseline and later migrations aligned.
ALTER TABLE intelligence.regulatory_document
    ADD COLUMN IF NOT EXISTS ingestion_status intelligence.ingestion_status
        NOT NULL DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS ix_regdoc_tenant_status
    ON intelligence.regulatory_document (client_id, ingestion_status);
-- (3) Document-level classification (reconcile decision). The frozen schema keeps
--     classification on document_chunk; this denormalizes the HUMAN-CONFIRMED
--     document-level tier (A4) onto the header so it has a home, and chunks inherit it.
--     Nullable until confirmed (gating tier must never be set by unconfirmed inference);
--     enforce NOT NULL in a follow-up after backfill if desired.
ALTER TABLE intelligence.regulatory_document
    ADD COLUMN IF NOT EXISTS classification intelligence.data_classification;

-- (4) Version / period label (reconcile decision). Distinct from effective_date.
ALTER TABLE intelligence.regulatory_document
    ADD COLUMN IF NOT EXISTS version VARCHAR(64);

-- =====================================================================
-- END V9__knowledge_hub_ingestion.sql
-- =====================================================================


-- =============================================================================
-- MIGRATION: V20260604_01__register_variance_slm.sql  (V-1 — register the fine-tuned variance SLM)
-- =============================================================================
-- =============================================================================
-- V-1: register the fine-tuned variance SLM in the model registry.
--
-- intelligence-service is the SOLE schema owner (lexie-ai holds no DB grant).
-- This migration seeds the model the variance presets pin to.
--
-- ROUTING INVARIANT (Q4): from_classifications is AUTHORITATIVE. This model is
-- marked local-only / external_eligible = false, so a preset can NEVER route
-- variance to an external LLM — even if a preset names it, classified data
-- (RESTRICTED/CONFIDENTIAL/MNPI) keeps it on the local fine-tuned SLM.
--
-- SME SUPPLIES (do not invent): the real model_id, the artifact URI, and the
-- exact fine-tune version. They are left as {{TOKENS}} below for the SME/dev to
-- fill before this migration is applied. Base = Qwen3-4B variance fine-tune.
--
-- SCHEMA CAVEAT (OI-2): column names below assume the D4 model_registry shape.
-- The schema name is `ai` today, slated to rename to `intelligence`; this file
-- uses ${schema} so the dev sets it once. Reconcile column names against the
-- real D4 DDL before applying — this is a seed, not the table definition.
-- =============================================================================

-- Placeholder convention: {{...}} markers are resolved by SME/dev pre-apply.
-- Flyway placeholder form ${schema} resolves from flyway.placeholders.schema.

INSERT INTO intelligence.model_registry (
    client_id,
    tier,
    model_type,
    model_id,
    connector_class,
    adapter_path,
    embedding_model,
    embedding_dim,
    is_local,
    is_default,
    params,
    secrets_ref,
    status,
    created_by,
    created_at
) VALUES (
    '__platform__',
    'platform',
    'SLM',
    'lextr-variance-qwen3-4b-v1',
    'QLoRAChatConnector',
    'file:///models/lextr/variance-qwen3-4b-v1',
    NULL,
    NULL,
    TRUE,
    FALSE,
    jsonb_build_object(
        'fine_tune_version', 'variance-v1',
        'base_model', 'Qwen3-4B',
        'artifact_uri', 'file:///models/lextr/variance-qwen3-4b-v1'
    ),
    NULL,
    'active',
    'seed',
    now()
)
ON CONFLICT (client_id, model_type, model_id) DO UPDATE SET
    connector_class = EXCLUDED.connector_class,
    adapter_path    = EXCLUDED.adapter_path,
    is_local        = EXCLUDED.is_local,
    params          = EXCLUDED.params,
    status          = EXCLUDED.status,
    updated_at      = now();

-- NOTE: AI_PROHIBITED data never reaches any model (D3 hard-stop / D5
-- MaskingBoundary) — excluded by the hard-stop, NOT by max_classification.
-- Canonical data_classification orders SENSITIVE ABOVE MNPI, so 'sensitive' is
-- the highest non-prohibited class and covers MNPI variance (and all lower
-- classes). The earlier 'mnpi' would have EXCLUDED SENSITIVE. Confirm D4's
-- ladder semantics before applying (OI-2); intent = "cover the highest
-- non-prohibited class."
