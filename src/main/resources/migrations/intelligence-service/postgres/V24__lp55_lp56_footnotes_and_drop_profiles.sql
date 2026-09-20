-- =====================================================================
-- Migration: V20260916_21__lp55_lp56_footnotes_and_drop_profiles.sql
-- LP-55.3: Chunk reference edge tables for footnote association
-- LP-56.3: Drop profile tables and per-document drop declarations
-- =====================================================================

-- 1. chunk_reference (LP-55.3)
CREATE TABLE IF NOT EXISTS intelligence.chunk_reference (
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

CREATE INDEX IF NOT EXISTS idx_chunk_ref_from ON intelligence.chunk_reference (client_id, from_chunk_id);
CREATE INDEX IF NOT EXISTS idx_chunk_ref_to ON intelligence.chunk_reference (client_id, to_chunk_id);

-- 2. chunk_reference_unresolved (LP-55.3)
CREATE TABLE IF NOT EXISTS intelligence.chunk_reference_unresolved (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id       bigint NOT NULL REFERENCES intelligence.document_chunk (id) ON DELETE CASCADE,
    marker         varchar(64) NOT NULL,
    scope          varchar(64) NOT NULL,
    reason         varchar(128) NOT NULL,
    client_id      varchar(64) NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chunk_ref_unres ON intelligence.chunk_reference_unresolved (client_id, chunk_id);

-- 3. drop_profile (LP-56.3)
CREATE TABLE IF NOT EXISTS intelligence.drop_profile (
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

CREATE INDEX IF NOT EXISTS idx_drop_profile_client ON intelligence.drop_profile (client_id, doc_family);

-- 4. drop_profile_version (LP-56.3)
CREATE TABLE IF NOT EXISTS intelligence.drop_profile_version (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      uuid NOT NULL REFERENCES intelligence.drop_profile (id) ON DELETE CASCADE,
    version         integer NOT NULL,
    client_id       varchar(64) NOT NULL,
    config_json     text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      varchar(64) NOT NULL,
    CONSTRAINT uq_drop_prof_ver UNIQUE (profile_id, version, client_id)
);

CREATE INDEX IF NOT EXISTS idx_drop_prof_ver ON intelligence.drop_profile_version (client_id, profile_id, version);

-- 5. drop_profile_ruling (LP-56.3)
CREATE TABLE IF NOT EXISTS intelligence.drop_profile_ruling (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_version_id  uuid NOT NULL REFERENCES intelligence.drop_profile_version (id) ON DELETE CASCADE,
    client_id           varchar(64) NOT NULL,
    question_id         varchar(64) NOT NULL,
    ruling              varchar(32) NOT NULL,
    reason              text NOT NULL,
    author              varchar(64) NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_drop_ruling_ver ON intelligence.drop_profile_ruling (client_id, profile_version_id);

-- 6. document_drop_declaration (LP-56.3)
CREATE TABLE IF NOT EXISTS intelligence.document_drop_declaration (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id           varchar(64) NOT NULL,
    document_id         bigint NOT NULL,
    document_version_id text NOT NULL,
    scope               varchar(64) NOT NULL,
    reason              text NOT NULL,
    submitter           varchar(64) NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_doc_drop_decl ON intelligence.document_drop_declaration (client_id, document_id, document_version_id);
