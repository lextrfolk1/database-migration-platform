-- =============================================================================
-- V5: Training Data & Model Improvement (LP-39.1)
-- =============================================================================
-- Folds in old V32. The fifth governed object kind: a ring-fenced home for
-- fine-tuning corpora and exams. Enums are in V1; model_registry lineage
-- columns (trained_on_dataset_*) are in V2.
--
--  * attest (curator) + approve (independent approver) are ONE gate in two halves;
--    four-eyes is OPA (lextr.ai.mrm_sod), never a column comparison here.
--  * one open draft per dataset key, and one designated-inbox coordinate per
--    (use_case, task, report_type, purpose), are DATABASE guarantees.
--  * a registered run with a failed or unmeasured exam is physically impossible.
--  * AI_PROHIBITED never enters, and RESTRICTED/MNPI only masked (OPA-TDM-001/002 backstop).
-- =============================================================================

CREATE TABLE IF NOT EXISTS intelligence.training_dataset (
    id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id               text NOT NULL,
    dataset_key             text NOT NULL,
    version                 integer NOT NULL DEFAULT 1,
    purpose                 intelligence.trn_dataset_purpose NOT NULL,
    status                  intelligence.trn_dataset_status NOT NULL DEFAULT 'draft',
    use_case                text,
    task                    text,
    report_type             text,
    content_schema_id       bigint REFERENCES intelligence.registered_definition (id),
    content_hash            char(64),
    sample_count            integer,
    created_by              text NOT NULL,
    frozen_by               text,
    frozen_at               timestamptz,
    attested_by             text,
    attested_at             timestamptz,
    approved_by             text,
    approved_at             timestamptz,
    retired_at              timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT trn_dataset_version_uq UNIQUE (client_id, dataset_key, version),
    CONSTRAINT trn_dataset_version_chk CHECK (version >= 1),
    -- a frozen (or later) version carries its content hash and count; a draft does not.
    CONSTRAINT trn_dataset_frozen_hash_chk CHECK (status = 'draft' OR (content_hash IS NOT NULL AND sample_count IS NOT NULL))
);

-- ONE open draft per key
CREATE UNIQUE INDEX IF NOT EXISTS trn_dataset_draft_uq
    ON intelligence.training_dataset (client_id, dataset_key) WHERE status = 'draft';

-- The designated-inbox coordinate; purpose is IN the key, so a corpus and its exam may share axes.
CREATE UNIQUE INDEX IF NOT EXISTS trn_dataset_axes_uq
    ON intelligence.training_dataset (client_id, use_case, task, report_type, purpose) NULLS NOT DISTINCT
    WHERE status = 'draft';

CREATE INDEX IF NOT EXISTS trn_dataset_status_idx ON intelligence.training_dataset (client_id, status);

CREATE TABLE IF NOT EXISTS intelligence.training_sample (
    id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id               text NOT NULL,
    dataset_id              bigint NOT NULL REFERENCES intelligence.training_dataset (id),
    sample_key              text NOT NULL,
    status                  intelligence.trn_sample_status NOT NULL DEFAULT 'candidate',
    load_path               intelligence.trn_load_path NOT NULL,
    classification          intelligence.data_classification NOT NULL,
    masked                  boolean NOT NULL DEFAULT false,
    payload                 jsonb NOT NULL,
    payload_hash            char(64) NOT NULL,
    source_run_id           text,
    replaces_ref            bigint REFERENCES intelligence.training_sample (id),
    revalidation_required   boolean NOT NULL DEFAULT false,
    created_by              text NOT NULL,
    curated_by              text,
    curated_at              timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT trn_sample_key_uq UNIQUE (dataset_id, sample_key),
    CONSTRAINT training_sample_class_chk CHECK (
        classification <> 'AI_PROHIBITED'
        AND (classification NOT IN ('RESTRICTED', 'MNPI') OR masked)
    )
);

CREATE INDEX IF NOT EXISTS trn_sample_dataset_idx ON intelligence.training_sample (dataset_id, status);
CREATE INDEX IF NOT EXISTS trn_sample_hash_idx ON intelligence.training_sample (client_id, payload_hash);

-- What a sample was grounded on, and at which version - anchor freshness is dataset HEALTH.
CREATE TABLE IF NOT EXISTS intelligence.training_sample_anchor (
    id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sample_id               bigint NOT NULL REFERENCES intelligence.training_sample (id),
    anchor_kind             text NOT NULL,
    anchor_ref              text NOT NULL,
    anchor_version          text NOT NULL,
    current_version         text,
    created_at              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT trn_anchor_uq UNIQUE (sample_id, anchor_kind, anchor_ref)
);

CREATE TABLE IF NOT EXISTS intelligence.training_run (
    id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id               text NOT NULL,
    run_key                 text NOT NULL,
    dataset_id              bigint NOT NULL REFERENCES intelligence.training_dataset (id),
    exam_dataset_id         bigint NOT NULL REFERENCES intelligence.training_dataset (id),
    base_model_id           bigint REFERENCES intelligence.model_registry (id),
    status                  intelligence.trn_run_status NOT NULL DEFAULT 'initiated',
    initiated_by            text NOT NULL,
    initiated_at            timestamptz NOT NULL DEFAULT now(),
    eval_floor              numeric(6,4),
    eval_score_base         numeric(6,4),
    eval_score_tuned        numeric(6,4),
    eval_malformed_rows     integer,
    eval_passed             boolean,
    adapter_path            text,
    registered_model_id     bigint,
    registered_by           text,
    failure_code            text,
    completed_at            timestamptz,
    CONSTRAINT trn_run_key_uq UNIQUE (client_id, run_key),
    CONSTRAINT trn_run_exam_distinct_chk CHECK (exam_dataset_id <> dataset_id),
    CONSTRAINT training_run_evalgate_chk CHECK (
        status <> 'registered' OR (eval_passed IS TRUE AND eval_score_tuned IS NOT NULL AND eval_floor IS NOT NULL)
    ),
    CONSTRAINT trn_run_failed_code_chk CHECK (status <> 'failed' OR failure_code IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS trn_run_dataset_idx ON intelligence.training_run (client_id, dataset_id);
CREATE INDEX IF NOT EXISTS trn_run_status_idx ON intelligence.training_run (client_id, status);
