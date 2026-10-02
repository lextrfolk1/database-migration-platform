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
DO $$ BEGIN
    CREATE TYPE intelligence.source_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.doc_type AS ENUM
    ('instruction', 'edit_check', 'data_dictionary', 'form', 'walk_procedure',
     'policy', 'procedure', 'standard', 'prior_filing');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;                       -- last four: UC11 Rules Copilot sources

-- form_version lifecycle
DO $$ BEGIN
    CREATE TYPE intelligence.ingestion_status AS ENUM
    ('pending', 'ingesting', 'completed', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Knowledge Hub lifecycle on regulatory_document (deliberately NOT shared with form_version)
DO $$ BEGIN
    CREATE TYPE intelligence.kh_ingestion_status AS ENUM
    ('RECEIVED', 'CLASSIFIED', 'CHUNKED', 'EMBEDDED', 'AVAILABLE', 'FAILED', 'QUARANTINED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Enforcement model (the schema RECORDS the tier; it does NOT enforce it):
--   PUBLIC / INTERNAL ............ pass through unmasked.
--   CONFIDENTIAL / RESTRICTED .... masked by the masking layer before any skill sees them.
--   MNPI ......................... masked AND OPA forces local SLM (is_local=true); never external.
--   SENSITIVE .................... masked by the masking layer.
--   AI_PROHIBITED ................ HARD DENY: never returned, never embedded, never routed to a model.
DO $$ BEGIN
    CREATE TYPE intelligence.data_classification AS ENUM
    ('PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED', 'MNPI', 'SENSITIVE', 'AI_PROHIBITED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------
-- Models, presets, runs
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE intelligence.model_type AS ENUM
    ('SLM', 'LLM', 'EMBEDDING', 'RERANKER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.model_tier AS ENUM
    ('platform', 'tenant');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;                                                   -- routing tiers 1/2; tier 3 = preset override

DO $$ BEGIN
    CREATE TYPE intelligence.output_type AS ENUM
    ('narrative', 'dataset', 'chart', 'reconciliation', 'validation', 'impact_list', 'ranked_list',
     'report_match_set',                                                      -- UC10 analytical assist
     'narrative_dataset', 'needs_input', 'route_out', 'driver_breakdown',     -- /run wire vocabulary
     'rule_draft');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;                                                           -- UC11 Rules Copilot

DO $$ BEGIN
    CREATE TYPE intelligence.skill_type AS ENUM
    ('SKILL_1', 'SKILL_2', 'SKILL_3');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.masking_type AS ENUM
    ('none', 'relative_change', 'entity_token', 'threshold_boolean', 'rank_ordinal', 'client_token');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.run_status AS ENUM
    ('created', 'running', 'completed', 'in_review', 'accepted', 'corrected', 'rejected', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.review_level AS ENUM
    ('analyst', 'senior_management');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.review_decision AS ENUM
    ('accept', 'correct', 'reject');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.preset_status AS ENUM
    ('draft', 'observed', 'operational', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE intelligence.envelope_status AS ENUM
    ('draft', 'pending_approval', 'approved', 'rejected', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;         -- MRM states

DO $$ BEGIN
    CREATE TYPE intelligence.lifecycle_status AS ENUM
    ('draft', 'active', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;                                           -- templates / mappings / models

-- ---------------------------------------------------------------------
-- Skill registry
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE intelligence.definition_kind AS ENUM ('skill', 'content_schema', 'calibrator');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.definition_status AS ENUM ('draft', 'observed', 'operational', 'deprecated', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.definition_mrm_status AS ENUM ('pending', 'approved', 'rejected', 'exempt');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------
-- Training data (a dataset does not run: no `observed` state)
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE intelligence.trn_dataset_status AS ENUM ('draft', 'frozen', 'attested', 'operational', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.trn_dataset_purpose AS ENUM ('training', 'evaluation');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.trn_sample_status AS ENUM ('candidate', 'accepted', 'retired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.trn_load_path AS ENUM ('review_correction', 'sme_authoring', 'bulk_import');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE TYPE intelligence.trn_run_status AS ENUM ('initiated', 'training', 'evaluating', 'registered', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
