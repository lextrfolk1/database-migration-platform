-- =====================================================================
-- Migration: V20260916_20__lp53_chunking_two_table_split.sql
-- LP-53.2 & LP-53.3: Chunking and the two-table split (element vs vector)
--
-- 1. Extend intelligence.document_chunk with provenance columns & invariants.
-- 2. Create intelligence.embedding_chunk (one row per vector).
-- 3. Create intelligence.embedding_chunk_source (join back from vector to elements).
-- 4. Re-point intelligence.embedding_store.chunk_id -> embedding_chunk.id
--    and clear pre-existing stale vectors computed over un-split elements.
-- =====================================================================

-- 1. Extend document_chunk with parser element metadata
ALTER TABLE intelligence.document_chunk
    ADD COLUMN IF NOT EXISTS page_number integer,
    ADD COLUMN IF NOT EXISTS element_type text NOT NULL DEFAULT 'paragraph',
    ADD COLUMN IF NOT EXISTS table_ref text,
    ADD COLUMN IF NOT EXISTS table_row integer,
    ADD COLUMN IF NOT EXISTS table_col integer,
    ADD COLUMN IF NOT EXISTS parent_path text,
    ADD COLUMN IF NOT EXISTS text_source text NOT NULL DEFAULT 'extracted';

-- Constraints on document_chunk
ALTER TABLE intelligence.document_chunk
    ADD CONSTRAINT chk_doc_chunk_page_number
        CHECK (page_number IS NULL OR page_number > 0),
    ADD CONSTRAINT chk_doc_chunk_table_ref
        CHECK (table_row IS NULL OR table_ref IS NOT NULL),
    ADD CONSTRAINT chk_doc_chunk_row_col
        CHECK ((table_row IS NULL AND table_col IS NULL) OR (table_row IS NOT NULL AND table_col IS NOT NULL)),
    ADD CONSTRAINT chk_doc_chunk_text_source
        CHECK (text_source IN ('extracted', 'ocr'));

-- 2. Create embedding_chunk (one row per vector)
CREATE TABLE IF NOT EXISTS intelligence.embedding_chunk (
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

CREATE INDEX IF NOT EXISTS emb_chunk_doc_idx ON intelligence.embedding_chunk (document_id);
CREATE INDEX IF NOT EXISTS emb_chunk_client_idx ON intelligence.embedding_chunk (client_id);
CREATE INDEX IF NOT EXISTS emb_chunk_created_idx ON intelligence.embedding_chunk (created_at);

-- 3. Create embedding_chunk_source (join back)
CREATE TABLE IF NOT EXISTS intelligence.embedding_chunk_source (
    embedding_chunk_id bigint NOT NULL REFERENCES intelligence.embedding_chunk (id) ON DELETE CASCADE,
    document_chunk_id  bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE RESTRICT,
    sequence_index     integer NOT NULL DEFAULT 0,
    PRIMARY KEY (embedding_chunk_id, document_chunk_id)
);

CREATE INDEX IF NOT EXISTS emb_chunk_src_doc_chunk_idx ON intelligence.embedding_chunk_source (document_chunk_id);

-- 3b. Safe upgrade backfill: preserve existing vector chunks from document_chunk
INSERT INTO intelligence.embedding_chunk (
    id, client_id, document_id, content, token_count, chunk_index, content_sha256, created_at
) OVERRIDING SYSTEM VALUE
SELECT 
    dc.id, 
    dc.client_id, 
    dc.document_id, 
    dc.content, 
    COALESCE(dc.token_count, 0), 
    dc.chunk_index, 
    encode(sha256(dc.content::bytea), 'hex'), 
    dc.created_at
FROM intelligence.document_chunk dc
WHERE dc.id IN (SELECT chunk_id FROM intelligence.embedding_store)
ON CONFLICT (id) DO NOTHING;

-- Populate join mapping in embedding_chunk_source for backfilled chunks
INSERT INTO intelligence.embedding_chunk_source (embedding_chunk_id, document_chunk_id, sequence_index)
SELECT ec.id, ec.id, 0
FROM intelligence.embedding_chunk ec
WHERE ec.id IN (SELECT id FROM intelligence.document_chunk)
ON CONFLICT (embedding_chunk_id, document_chunk_id) DO NOTHING;

-- 4. Re-point embedding_store to embedding_chunk (clean orphaned legacy un-split vectors)
DELETE FROM intelligence.embedding_store
WHERE chunk_id NOT IN (SELECT id FROM intelligence.embedding_chunk);

ALTER TABLE intelligence.embedding_store
    DROP CONSTRAINT IF EXISTS embedding_store_chunk_id_fkey;

ALTER TABLE intelligence.embedding_store
    ADD CONSTRAINT fk_embedding_store_embedding_chunk
        FOREIGN KEY (chunk_id) REFERENCES intelligence.embedding_chunk (id) ON DELETE CASCADE;

COMMENT ON COLUMN intelligence.embedding_store.chunk_id IS 'References intelligence.embedding_chunk (id), one row per vector chunk.';
