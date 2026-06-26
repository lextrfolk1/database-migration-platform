-- =============================================================================
-- V3 — Data Classification & Attribute Access Grants
-- =============================================================================

-- ============================================================================
-- meta.data_classification_ref — governed classification reference
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.data_classification_ref (
    data_classification_cd      varchar(30)  PRIMARY KEY,
    data_classification_nm      varchar(100) NOT NULL,
    data_classification_desc    text,
    classification_rank_nbr     integer      NOT NULL,
    ai_exposure_default_cd      varchar(20)  NOT NULL DEFAULT 'RESTRICTED',
    created_ts                  timestamptz  NOT NULL DEFAULT now(),
    created_by                  varchar(100) NOT NULL DEFAULT current_user,
    updated_ts                  timestamptz,
    updated_by                  varchar(100),
    CONSTRAINT ck_dcr_cd CHECK (data_classification_cd IN
        ('PUBLIC','INTERNAL','CONFIDENTIAL','RESTRICTED')),
    CONSTRAINT ck_dcr_ai_exposure CHECK (ai_exposure_default_cd IN
        ('ALLOWED','RESTRICTED','BLOCKED'))
);

INSERT INTO meta.data_classification_ref (
    data_classification_cd,
    data_classification_nm,
    data_classification_desc,
    classification_rank_nbr,
    ai_exposure_default_cd
) VALUES
    ('PUBLIC', 'Public', 'Approved for broad internal and external access.', 10, 'ALLOWED'),
    ('INTERNAL', 'Internal', 'Approved for internal operational use.', 20, 'RESTRICTED'),
    ('CONFIDENTIAL', 'Confidential', 'Restricted to approved business users with need-to-know.', 30, 'RESTRICTED'),
    ('RESTRICTED', 'Restricted', 'Highly sensitive data requiring explicit policy approval.', 40, 'BLOCKED')
ON CONFLICT (data_classification_cd) DO NOTHING;

-- ============================================================================
-- meta.object_catalog — anchor existing object classification to governed ref
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'meta'
          AND table_name = 'object_catalog'
          AND constraint_name = 'fk_oc_data_class_ref'
    ) THEN
        ALTER TABLE meta.object_catalog
            ADD CONSTRAINT fk_oc_data_class_ref
                FOREIGN KEY (data_classification_cd)
                REFERENCES meta.data_classification_ref (data_classification_cd);
    END IF;
END $$;

-- ============================================================================
-- meta.attribute_catalog — additive classification controls
-- ============================================================================
ALTER TABLE meta.attribute_catalog
    ADD COLUMN IF NOT EXISTS data_classification_cd varchar(30),
    ADD COLUMN IF NOT EXISTS mnpi_flg boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS csi_flg boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ai_exposure_cd varchar(20) NOT NULL DEFAULT 'RESTRICTED';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'meta'
          AND table_name = 'attribute_catalog'
          AND constraint_name = 'fk_ac_data_class_ref'
    ) THEN
        ALTER TABLE meta.attribute_catalog
            ADD CONSTRAINT fk_ac_data_class_ref
                FOREIGN KEY (data_classification_cd)
                REFERENCES meta.data_classification_ref (data_classification_cd);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'meta'
          AND table_name = 'attribute_catalog'
          AND constraint_name = 'ck_ac_data_class'
    ) THEN
        ALTER TABLE meta.attribute_catalog
            ADD CONSTRAINT ck_ac_data_class CHECK (
                data_classification_cd IS NULL OR data_classification_cd IN
                    ('PUBLIC','INTERNAL','CONFIDENTIAL','RESTRICTED')
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'meta'
          AND table_name = 'attribute_catalog'
          AND constraint_name = 'ck_ac_ai_exposure'
    ) THEN
        ALTER TABLE meta.attribute_catalog
            ADD CONSTRAINT ck_ac_ai_exposure CHECK (
                ai_exposure_cd IN ('ALLOWED','RESTRICTED','BLOCKED')
            );
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_ac_data_class ON meta.attribute_catalog (data_classification_cd);
CREATE INDEX IF NOT EXISTS ix_ac_ai_exposure ON meta.attribute_catalog (ai_exposure_cd);

-- ============================================================================
-- meta.attribute_access_grant — optional tenant-scoped access overrides
-- ============================================================================
CREATE TABLE IF NOT EXISTS meta.attribute_access_grant (
    id                   bigserial    PRIMARY KEY,
    client_id            varchar(40)  NOT NULL,
    schema_cd            varchar(30)  NOT NULL,
    object_cd            varchar(50)  NOT NULL,
    attribute_cd         varchar(32)  NOT NULL,
    role_cd              varchar(100) NOT NULL,
    purpose_cd           varchar(100) NOT NULL,
    grant_scope_cd       varchar(30)  NOT NULL DEFAULT 'READ',
    grant_status_cd      varchar(30)  NOT NULL DEFAULT 'ACTIVE',
    approved_by          varchar(100),
    approved_ts          timestamptz,
    created_ts           timestamptz  NOT NULL DEFAULT now(),
    created_by           varchar(100) NOT NULL DEFAULT current_user,
    updated_ts           timestamptz,
    updated_by           varchar(100),
    CONSTRAINT uq_aag UNIQUE (
        client_id,
        schema_cd,
        object_cd,
        attribute_cd,
        role_cd,
        purpose_cd,
        grant_scope_cd
    ),
    CONSTRAINT fk_aag_attribute FOREIGN KEY (schema_cd, object_cd, attribute_cd)
        REFERENCES meta.attribute_catalog (schema_cd, object_cd, attribute_cd)
        ON DELETE CASCADE,
    CONSTRAINT ck_aag_scope CHECK (grant_scope_cd IN ('READ','MASK','DENY')),
    CONSTRAINT ck_aag_status CHECK (grant_status_cd IN
        ('ACTIVE','REVIEW','REVOKED','EXPIRED'))
);

CREATE INDEX IF NOT EXISTS ix_aag_client ON meta.attribute_access_grant (client_id);
CREATE INDEX IF NOT EXISTS ix_aag_attribute ON meta.attribute_access_grant (schema_cd, object_cd, attribute_cd);
CREATE INDEX IF NOT EXISTS ix_aag_status ON meta.attribute_access_grant (grant_status_cd);
