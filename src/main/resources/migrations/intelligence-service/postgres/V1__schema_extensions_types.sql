-- =============================================================================
-- Lextr Intelligence - `intelligence` schema, consolidated baseline
-- V1: schema, extensions and every enumerated type
-- =============================================================================
-- V1..V7 build the schema and seed data on an EMPTY database. They consolidate the
-- earlier V1..V45 chain ("old Vn" in the headers); each type carries its FINAL value
-- list, so the old ALTER TYPE ... ADD VALUE steps (old V9, V20, V27, V34) are folded in.
--
-- Apply in version order (PostgreSQL 16+ with pgvector), each in its own transaction:
--   psql -v ON_ERROR_STOP=1 -1 -f V1__schema_extensions_types.sql
-- pgvector is not a trusted extension: create it first as a superuser
-- (rds_superuser / cloudsqlsuperuser on managed Postgres).
--
-- Tenancy: client_id on scoped rows; isolation enforced in OPA, not RLS.
-- Authorization: all policy externalized to OPA/Rego - none in the schema.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS intelligence;

CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector: embedding_store
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- trigram lookup for cross_reference _by_name_words
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid() keys on the drop-profile / footnote tables

-- ---------------------------------------------------------------------
-- Knowledge / grounding
-- ---------------------------------------------------------------------
CREATE TYPE intelligence.source_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form');

CREATE TYPE intelligence.doc_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form', 'walk_procedure',
     'policy', 'procedure', 'standard', 'prior_filing');                       -- last four: UC11 Rules Copilot sources

-- form_version lifecycle
CREATE TYPE intelligence.ingestion_status AS ENUM
    ('pending', 'ingesting', 'completed', 'failed');

-- Knowledge Hub lifecycle on regulatory_document (deliberately NOT shared with form_version)
CREATE TYPE intelligence.kh_ingestion_status AS ENUM
    ('RECEIVED', 'CLASSIFIED', 'CHUNKED', 'EMBEDDED', 'AVAILABLE', 'FAILED', 'QUARANTINED');

-- Enforcement model (the schema RECORDS the tier; it does NOT enforce it):
--   PUBLIC / INTERNAL ............ pass through unmasked.
--   CONFIDENTIAL / RESTRICTED .... masked by the masking layer before any skill sees them.
--   MNPI ......................... masked AND OPA forces local SLM (is_local=true); never external.
--   SENSITIVE .................... masked by the masking layer.
--   AI_PROHIBITED ................ HARD DENY: never returned, never embedded, never routed to a model.
CREATE TYPE intelligence.data_classification AS ENUM
    ('PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED', 'MNPI', 'SENSITIVE', 'AI_PROHIBITED');

-- ---------------------------------------------------------------------
-- Models, presets, runs
-- ---------------------------------------------------------------------
CREATE TYPE intelligence.model_type AS ENUM
    ('SLM', 'LLM', 'EMBEDDING', 'RERANKER');

CREATE TYPE intelligence.model_tier AS ENUM
    ('platform', 'tenant');                                                   -- routing tiers 1/2; tier 3 = preset override

CREATE TYPE intelligence.output_type AS ENUM
    ('narrative', 'dataset', 'chart', 'reconciliation', 'validation', 'impact_list', 'ranked_list',
     'report_match_set',                                                      -- UC10 analytical assist
     'narrative_dataset', 'needs_input', 'route_out', 'driver_breakdown',     -- /run wire vocabulary
     'rule_draft');                                                           -- UC11 Rules Copilot

CREATE TYPE intelligence.skill_type AS ENUM
    ('SKILL_1', 'SKILL_2', 'SKILL_3');

CREATE TYPE intelligence.masking_type AS ENUM
    ('none', 'relative_change', 'entity_token', 'threshold_boolean', 'rank_ordinal', 'client_token');

CREATE TYPE intelligence.run_status AS ENUM
    ('created', 'running', 'completed', 'in_review', 'accepted', 'corrected', 'rejected', 'failed');

CREATE TYPE intelligence.review_level AS ENUM
    ('analyst', 'senior_management');

CREATE TYPE intelligence.review_decision AS ENUM
    ('accept', 'correct', 'reject');

CREATE TYPE intelligence.preset_status AS ENUM
    ('draft', 'observed', 'operational', 'retired');

CREATE TYPE intelligence.envelope_status AS ENUM
    ('draft', 'pending_approval', 'approved', 'rejected', 'retired');         -- MRM states

CREATE TYPE intelligence.lifecycle_status AS ENUM
    ('draft', 'active', 'retired');                                           -- templates / mappings / models

-- ---------------------------------------------------------------------
-- Skill registry
-- ---------------------------------------------------------------------
CREATE TYPE intelligence.definition_kind AS ENUM ('skill', 'content_schema', 'calibrator');
CREATE TYPE intelligence.definition_status AS ENUM ('draft', 'observed', 'operational', 'deprecated', 'retired');
CREATE TYPE intelligence.definition_mrm_status AS ENUM ('pending', 'approved', 'rejected', 'exempt');

-- ---------------------------------------------------------------------
-- Training data (a dataset does not run: no `observed` state)
-- ---------------------------------------------------------------------
CREATE TYPE intelligence.trn_dataset_status AS ENUM ('draft', 'frozen', 'attested', 'operational', 'retired');
CREATE TYPE intelligence.trn_dataset_purpose AS ENUM ('training', 'evaluation');
CREATE TYPE intelligence.trn_sample_status AS ENUM ('candidate', 'accepted', 'retired');
CREATE TYPE intelligence.trn_load_path AS ENUM ('review_correction', 'sme_authoring', 'bulk_import');
CREATE TYPE intelligence.trn_run_status AS ENUM ('initiated', 'training', 'evaluating', 'registered', 'failed');
