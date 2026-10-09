-- Knowledge Hub schema (architecture §8, §24).
-- Requires the pgvector extension, already used by the platform
-- (service/mdrm_suggestion_service.py -> agno PgVector).

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS variance.knowledge_document (
    doc_id         TEXT PRIMARY KEY,
    collection     TEXT NOT NULL,
    title          TEXT NOT NULL,
    object_key     TEXT,                       -- raw artifact in S3/GCS
    content_hash   TEXT NOT NULL,              -- idempotent re-ingestion
    doc_version    INT  NOT NULL DEFAULT 1,
    reliability    TEXT NOT NULL DEFAULT 'MEDIUM'
                   CHECK (reliability IN ('HIGH','MEDIUM','LOW')),
    effective_from DATE,                       -- temporal validity: instruction
    effective_to   DATE,                       -- vintages differ per period
    mdrm_affinity  TEXT[] NOT NULL DEFAULT '{}',
    report         TEXT,
    schedule       TEXT,
    source_ref     TEXT,                       -- resolvable citation URI
    curated_by     TEXT,
    status         TEXT NOT NULL DEFAULT 'ACTIVE',
    metadata       JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (doc_id, doc_version)
);
CREATE INDEX IF NOT EXISTS ix_kdoc_collection ON variance.knowledge_document (collection, status);
CREATE INDEX IF NOT EXISTS ix_kdoc_effective  ON variance.knowledge_document (effective_from, effective_to);
CREATE INDEX IF NOT EXISTS ix_kdoc_mdrm       ON variance.knowledge_document USING GIN (mdrm_affinity);

CREATE TABLE IF NOT EXISTS variance.knowledge_chunk (
    chunk_id       TEXT PRIMARY KEY,
    doc_id         TEXT NOT NULL,
    doc_version    INT  NOT NULL DEFAULT 1,
    seq            INT  NOT NULL,
    content        TEXT NOT NULL,              -- already PII/CSI-masked (§20)
    content_hash   TEXT NOT NULL,
    collection     TEXT NOT NULL,
    reliability    TEXT NOT NULL DEFAULT 'MEDIUM',
    effective_from DATE,
    effective_to   DATE,
    mdrm_affinity  TEXT[] NOT NULL DEFAULT '{}',
    report         TEXT,
    schedule       TEXT,
    source_ref     TEXT,
    -- 1536, not the model's native 3072: pgvector's HNSW index rejects more
    -- than 2000 dimensions. text-embedding-3-large is Matryoshka-trained, so
    -- requesting 1536 dimensions truncates with little retrieval loss and
    -- halves storage. Keep this in step with VAI_EMBEDDING_DIMENSIONS.
    --
    -- To use the full 3072 instead, store it and index as halfvec:
    --   embedding vector(3072)
    --   CREATE INDEX … USING hnsw ((embedding::halfvec(3072)) halfvec_cosine_ops)
    -- which lifts the limit to 4000 at half precision (pgvector >= 0.7).
    embedding      vector(1536),
    tsv            tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,
    metadata       JSONB NOT NULL DEFAULT '{}'::jsonb,
    FOREIGN KEY (doc_id, doc_version) REFERENCES variance.knowledge_document (doc_id, doc_version)
);
-- hybrid search: HNSW for dense, GIN for lexical (§8.3)
CREATE INDEX IF NOT EXISTS ix_kchunk_embedding ON variance.knowledge_chunk
    USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 200);
CREATE INDEX IF NOT EXISTS ix_kchunk_tsv        ON variance.knowledge_chunk USING GIN (tsv);
CREATE INDEX IF NOT EXISTS ix_kchunk_collection ON variance.knowledge_chunk (collection);
CREATE INDEX IF NOT EXISTS ix_kchunk_mdrm       ON variance.knowledge_chunk USING GIN (mdrm_affinity);

CREATE TABLE IF NOT EXISTS variance.knowledge_snapshot (
    snapshot_id  TEXT PRIMARY KEY,             -- ks_2026Q2_r3
    cycle_hint   TEXT,
    doc_versions JSONB NOT NULL,               -- {doc_id: version} — immutable
    content_hash TEXT NOT NULL,
    frozen_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    frozen_by    TEXT NOT NULL
);

-- Masking audit: records THAT a value was masked, never the value (§20).
CREATE TABLE IF NOT EXISTS variance.masking_event (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scope       TEXT NOT NULL,                 -- doc_id or analysis_id
    scope_type  TEXT NOT NULL CHECK (scope_type IN ('DOCUMENT','CONTEXT')),
    label       TEXT NOT NULL,                 -- SSN, TIN, OBLIGOR, …
    token       TEXT NOT NULL,
    value_hash  TEXT NOT NULL,                 -- salted hash, not reversible
    detector    TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_masking_scope ON variance.masking_event (scope, scope_type);
