-- =============================================================================
-- V6 — Domain Registration & Governed AI Resolve (LP-43)
-- =============================================================================
-- Governed domains (domain_catalog + domain_value)
-- Domain Sources: INLINE | ENUMERATED | REFERENCE_TABLE
-- Domain Value Synonyms, Source Maps, and Localized Text
-- Attribute Catalog Domain Wiring & Governance Policy Presets
-- =============================================================================

-- 1. meta.domain_catalog
CREATE TABLE IF NOT EXISTS meta.domain_catalog (
    id                              bigserial    PRIMARY KEY,
    domain_cd                       varchar(60)  NOT NULL UNIQUE,
    domain_nm                       varchar(200) NOT NULL,
    domain_desc                     text,
    domain_source_cd                varchar(30)  NOT NULL DEFAULT 'INLINE',
    data_type_cd                    varchar(30)  NOT NULL DEFAULT 'STRING',
    version_nbr                     integer      NOT NULL DEFAULT 1,
    value_count_nbr                 integer      NOT NULL DEFAULT 0,
    client_id                       varchar(40),
    lifecycle_status_cd             varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    governance_review_status_cd     varchar(30)  NOT NULL DEFAULT 'APPROVED',
    created_ts                      timestamptz  NOT NULL DEFAULT now(),
    created_by                      varchar(100) NOT NULL DEFAULT current_user,
    updated_ts                      timestamptz,
    updated_by                      varchar(100),
    CONSTRAINT ck_dc_source CHECK (domain_source_cd IN ('INLINE','ENUMERATED','REFERENCE_TABLE')),
    CONSTRAINT ck_dc_lifecycle CHECK (lifecycle_status_cd IN ('DRAFT','REVIEW','APPROVED','ACTIVE','DEPRECATED','RETIRED','REJECTED'))
);

CREATE INDEX IF NOT EXISTS ix_dc_client ON meta.domain_catalog (client_id);

-- 2. meta.domain_value
CREATE TABLE IF NOT EXISTS meta.domain_value (
    id                  bigserial    PRIMARY KEY,
    domain_cd           varchar(60)  NOT NULL REFERENCES meta.domain_catalog (domain_cd) ON DELETE CASCADE,
    value_cd            varchar(100) NOT NULL,
    value_nm            varchar(200),
    value_desc          text,
    sort_order_nbr      integer      NOT NULL DEFAULT 0,
    is_default_flg      boolean      NOT NULL DEFAULT false,
    ai_exposure_cd      varchar(20)  NOT NULL DEFAULT 'ALLOWED',
    client_id           varchar(40),
    lifecycle_status_cd varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    created_ts          timestamptz  NOT NULL DEFAULT now(),
    created_by          varchar(100) NOT NULL DEFAULT current_user,
    updated_ts          timestamptz,
    updated_by          varchar(100),
    CONSTRAINT uq_dv_domain_value_client UNIQUE (domain_cd, value_cd, client_id),
    CONSTRAINT ck_dv_ai_exposure CHECK (ai_exposure_cd IN ('ALLOWED', 'RESTRICTED', 'BLOCKED'))
);

CREATE INDEX IF NOT EXISTS ix_dv_domain ON meta.domain_value (domain_cd);
CREATE INDEX IF NOT EXISTS ix_dv_client ON meta.domain_value (client_id);

-- 3. meta.attribute_catalog domain columns
ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS domain_cd varchar(60),
    ADD COLUMN IF NOT EXISTS domain_source_cd varchar(30);

-- 4. meta.domain_value_synonym
CREATE TABLE IF NOT EXISTS meta.domain_value_synonym (
    id                  bigserial    PRIMARY KEY,
    domain_cd           varchar(60)  NOT NULL REFERENCES meta.domain_catalog (domain_cd) ON DELETE CASCADE,
    value_cd            varchar(100) NOT NULL,
    synonym_txt         varchar(200) NOT NULL,
    client_id           varchar(40),
    lifecycle_status_cd varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    created_ts          timestamptz  NOT NULL DEFAULT now(),
    created_by          varchar(100) NOT NULL DEFAULT current_user,
    updated_ts          timestamptz,
    updated_by          varchar(100),
    CONSTRAINT uq_dvs_synonym UNIQUE (domain_cd, value_cd, synonym_txt, client_id)
);

CREATE INDEX IF NOT EXISTS ix_dvs_domain_val ON meta.domain_value_synonym (domain_cd, value_cd);
CREATE INDEX IF NOT EXISTS ix_dvs_synonym ON meta.domain_value_synonym (synonym_txt);

-- 5. meta.domain_value_source_map
CREATE TABLE IF NOT EXISTS meta.domain_value_source_map (
    id                  bigserial    PRIMARY KEY,
    domain_cd           varchar(60)  NOT NULL REFERENCES meta.domain_catalog (domain_cd) ON DELETE CASCADE,
    canonical_value_cd  varchar(100) NOT NULL,
    source_system_cd    varchar(50)  NOT NULL,
    source_value_cd     varchar(100) NOT NULL,
    client_id           varchar(40),
    created_ts          timestamptz  NOT NULL DEFAULT now(),
    created_by          varchar(100) NOT NULL DEFAULT current_user,
    updated_ts          timestamptz,
    updated_by          varchar(100),
    CONSTRAINT uq_dvsm_source UNIQUE (domain_cd, source_system_cd, source_value_cd, client_id)
);

CREATE INDEX IF NOT EXISTS ix_dvsm_domain_canonical ON meta.domain_value_source_map (domain_cd, canonical_value_cd);

-- 6. meta.domain_value_text
CREATE TABLE IF NOT EXISTS meta.domain_value_text (
    id                  bigserial    PRIMARY KEY,
    domain_cd           varchar(60)  NOT NULL REFERENCES meta.domain_catalog (domain_cd) ON DELETE CASCADE,
    value_cd            varchar(100) NOT NULL,
    locale_cd           varchar(10)  NOT NULL DEFAULT 'en_US',
    display_txt         varchar(200) NOT NULL,
    long_desc_txt       text,
    client_id           varchar(40),
    created_ts          timestamptz  NOT NULL DEFAULT now(),
    created_by          varchar(100) NOT NULL DEFAULT current_user,
    updated_ts          timestamptz,
    updated_by          varchar(100),
    CONSTRAINT uq_dvt_locale UNIQUE (domain_cd, value_cd, locale_cd, client_id)
);

CREATE INDEX IF NOT EXISTS ix_dvt_domain_val ON meta.domain_value_text (domain_cd, value_cd);

-- 7. Governance policy presets
ALTER TABLE governance.policy_preset ALTER COLUMN policy_cd TYPE varchar(60);

INSERT INTO governance.policy_preset (
    policy_cd, policy_nm, policy_scope_cd, default_value_txt, data_type_cd, is_overrideable_flg, override_requires_approval_flg
) VALUES
    ('DOMAIN_INLINE_MAX_CARDINALITY', 'Domain Inline Max Cardinality', 'GLOBAL', '100', 'INTEGER', true, false),
    ('DOMAIN_MAX_ENUMERATE_CARDINALITY', 'Domain Max Enumerate Cardinality', 'GLOBAL', '5000', 'INTEGER', true, false),
    ('DOMAIN_RESOLVE_TTL_SECONDS', 'Domain Resolve Cache TTL Seconds', 'GLOBAL', '3600', 'INTEGER', true, false)
ON CONFLICT (policy_cd) DO NOTHING;
