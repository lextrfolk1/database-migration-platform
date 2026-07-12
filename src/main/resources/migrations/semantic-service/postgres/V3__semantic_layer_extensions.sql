-- =============================================================================
-- V3 — Data Classification, Observability, Consumption, and Data Quality Extensions
-- =============================================================================

-- ============================================================================
-- 1. DATA CLASSIFICATION SCHEMA (formerly V3)
-- ============================================================================
DROP TABLE IF EXISTS meta.data_classification_ref CASCADE;

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

ALTER TABLE meta.object_catalog
    ADD COLUMN IF NOT EXISTS ai_business_context_txt text,
    ADD COLUMN IF NOT EXISTS ai_prompt_guidance_txt text;

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

DROP TABLE IF EXISTS meta.attribute_access_grant CASCADE;

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

-- ============================================================================
-- 2. DATA OBSERVABILITY SCHEMA (formerly V4, V5, V6, V7)
-- ============================================================================
DROP TABLE IF EXISTS meta.observability_signal CASCADE;

CREATE TABLE IF NOT EXISTS meta.observability_signal (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    signal_type_cd          varchar(40)  NOT NULL,
    severity_cd             varchar(20)  NOT NULL DEFAULT 'INFO',
    signal_status_cd        varchar(20)  NOT NULL DEFAULT 'OPEN',
    source_system_cd        varchar(60)  NOT NULL,
    source_entity_type_cd   varchar(40),
    source_entity_ref_txt   varchar(120),
    correlation_key_txt     varchar(200),
    finding_summary_txt     text,
    finding_detail_txt      text,
    detected_ts             timestamptz  NOT NULL,
    acknowledged_ts        timestamptz,
    resolved_ts            timestamptz,
    workflow_task_id        bigint,
    dq_rerun_requested_flg  boolean      NOT NULL DEFAULT false,
    dq_rerun_reason_txt     text,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT ck_os_type CHECK (signal_type_cd IN
        ('FRESHNESS','VOLUME','SCHEMA_DRIFT','NULL_RATE_SPIKE','DISTRIBUTION_SHIFT')),
    CONSTRAINT ck_os_severity CHECK (severity_cd IN ('HIGH','WARN','INFO')),
    CONSTRAINT ck_os_status CHECK (signal_status_cd IN ('OPEN','TRIAGE','ACK','RESOLVED')),
    CONSTRAINT fk_os_workflow_task FOREIGN KEY (workflow_task_id)
        REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS ix_os_client ON meta.observability_signal (client_id);
CREATE INDEX IF NOT EXISTS ix_os_status ON meta.observability_signal
    (client_id, signal_status_cd, severity_cd, detected_ts DESC);
CREATE INDEX IF NOT EXISTS ix_os_type ON meta.observability_signal
    (client_id, signal_type_cd, detected_ts DESC);
CREATE INDEX IF NOT EXISTS ix_os_detected ON meta.observability_signal (detected_ts DESC);
CREATE INDEX IF NOT EXISTS ix_os_workflow_task ON meta.observability_signal (workflow_task_id);

INSERT INTO governance.policy_preset
  (policy_cd, policy_nm, policy_scope_cd, default_value_txt, data_type_cd,
   is_overrideable_flg, override_requires_approval_flg)
VALUES
  ('GOV-OS-001', 'Observability workflow route severity floor', 'OBSERVABILITY_SIGNAL', 'WARN', 'STRING', true, true),
  ('GOV-OS-002', 'Observability DQ rerun severity floor', 'OBSERVABILITY_SIGNAL', 'HIGH', 'STRING', true, true)
ON CONFLICT (policy_cd) DO NOTHING;

CREATE INDEX IF NOT EXISTS ix_os_client_corr_key
    ON meta.observability_signal (client_id, correlation_key_txt);

CREATE INDEX IF NOT EXISTS ix_pp_scope_code_effective
    ON governance.policy_preset (policy_scope_cd, policy_cd, effective_from_dt DESC, effective_to_dt);

-- ============================================================================
-- 3. OUTBOUND CONSUMPTION SCHEMA (formerly V8)
-- ============================================================================
DROP TABLE IF EXISTS meta.consumption_layer CASCADE;

CREATE TABLE IF NOT EXISTS meta.consumption_layer (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    layer_cd                varchar(120) NOT NULL,
    layer_nm                varchar(200) NOT NULL,
    layer_desc_txt          text,
    layer_type_cd           varchar(40)  NOT NULL,
    lifecycle_status_cd     varchar(20)  NOT NULL DEFAULT 'ACTIVE',
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT uq_consumption_layer UNIQUE (client_id, layer_cd),
    CONSTRAINT ck_cl_lifecycle CHECK (lifecycle_status_cd IN ('DRAFT', 'ACTIVE', 'INACTIVE'))
);

CREATE INDEX IF NOT EXISTS ix_cl_client ON meta.consumption_layer (client_id, layer_cd);

DROP TABLE IF EXISTS meta.consumption_outbound CASCADE;

CREATE TABLE IF NOT EXISTS meta.consumption_outbound (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    layer_cd                varchar(120) NOT NULL,
    object_id               uuid         NOT NULL,
    outbound_cd             varchar(120) NOT NULL,
    outbound_nm             varchar(200) NOT NULL,
    structure_type_cd       varchar(40)  NOT NULL,
    description_txt         text,
    sdlc_status_cd          varchar(20)  NOT NULL DEFAULT 'DEV',
    version_nbr             integer      NOT NULL DEFAULT 1,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT uq_consumption_outbound UNIQUE (client_id, layer_cd, outbound_cd),
    CONSTRAINT ck_co_sdlc CHECK (sdlc_status_cd IN ('DEV', 'QA', 'PROD')),
    CONSTRAINT fk_co_layer FOREIGN KEY (client_id, layer_cd) 
        REFERENCES meta.consumption_layer (client_id, layer_cd) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_co_lookup ON meta.consumption_outbound (client_id, object_id, outbound_cd);

DROP TABLE IF EXISTS meta.consumption_outbound_grain CASCADE;

CREATE TABLE IF NOT EXISTS meta.consumption_outbound_grain (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    outbound_id             bigint       NOT NULL,
    grain_level_nbr         integer      NOT NULL,
    logical_attribute_cd    varchar(120) NOT NULL,
    attribute_role_cd       varchar(40)  NOT NULL,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT fk_cog_outbound FOREIGN KEY (outbound_id) 
        REFERENCES meta.consumption_outbound (id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS meta.consumption_promotion CASCADE;

CREATE TABLE IF NOT EXISTS meta.consumption_promotion (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    outbound_id             bigint       NOT NULL,
    source_sdlc_status_cd   varchar(20)  NOT NULL,
    target_sdlc_status_cd   varchar(20)  NOT NULL,
    validation_status_cd    varchar(20)  NOT NULL,
    opa_decision_cd         varchar(20)  NOT NULL,
    workflow_task_id        bigint,
    promotion_status_cd     varchar(40)  NOT NULL,
    version_nbr             integer      NOT NULL,
    applied_ts              timestamptz,
    applied_by              varchar(100),
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT fk_cp_outbound FOREIGN KEY (outbound_id) 
        REFERENCES meta.consumption_outbound (id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_workflow_task FOREIGN KEY (workflow_task_id) 
        REFERENCES wkfl.workflow_task (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS ix_alno_lookup
    ON meta.attribute_logical_name_override (
        schema_cd,
        object_cd,
        attribute_cd,
        override_status_cd,
        approved_ts DESC,
        requested_ts DESC,
        id DESC
    );

CREATE INDEX IF NOT EXISTS ix_cog_outbound_lookup
    ON meta.consumption_outbound_grain (
        client_id,
        outbound_id,
        grain_level_nbr,
        logical_attribute_cd
    );

-- ============================================================================
-- 4. METADATA AUDIT TRAILS (formerly V9)
-- ============================================================================
CREATE INDEX IF NOT EXISTS ix_mch_entity_ref_lookup
    ON meta.metadata_change_history (entity_type_cd, entity_ref, changed_ts DESC);

-- ============================================================================
-- 5. EXTERNAL RULE RESULTS SCHEMA (formerly V10)
-- ============================================================================
DROP TABLE IF EXISTS meta.external_rule_result CASCADE;

CREATE TABLE IF NOT EXISTS meta.external_rule_result (
    id                  bigserial    PRIMARY KEY,
    client_id           varchar(40)  NOT NULL,
    outbound_id         bigint       NOT NULL
        REFERENCES meta.consumption_outbound (id),
    rule_ref_cd         varchar(120) NOT NULL,
    output_kind_cd      varchar(40)  NOT NULL,
    output_payload_jsonb jsonb,
    observed_ts         timestamptz   NOT NULL,
    created_ts          timestamptz   NOT NULL DEFAULT now(),
    created_by          varchar(100)  NOT NULL DEFAULT current_user,
    updated_ts          timestamptz,
    updated_by          varchar(100)
);

CREATE INDEX IF NOT EXISTS ix_err_client
    ON meta.external_rule_result (client_id);

CREATE INDEX IF NOT EXISTS ix_err_outbound
    ON meta.external_rule_result (client_id, outbound_id, observed_ts DESC, id DESC);

CREATE INDEX IF NOT EXISTS ix_err_rule_ref
    ON meta.external_rule_result (client_id, rule_ref_cd, observed_ts DESC, id DESC);

-- ============================================================================
-- 6. DATA QUALITY RULES AND VERDICTS SCHEMA (formerly V11)
-- ============================================================================
DROP TABLE IF EXISTS meta.dq_rule_catalog CASCADE;

CREATE TABLE IF NOT EXISTS meta.dq_rule_catalog (
    id                      bigserial    PRIMARY KEY,
    rule_cd                 varchar(120) NOT NULL,
    rule_nm                 varchar(200) NOT NULL,
    rule_dimension_cd       varchar(80)  NOT NULL,
    logical_attribute_cd    varchar(120) NOT NULL,
    rule_scope_cd           varchar(40)  NOT NULL,
    rule_expression_txt     text         NOT NULL,
    severity_cd             varchar(20)  NOT NULL DEFAULT 'HIGH',
    lifecycle_status_cd     varchar(20)  NOT NULL DEFAULT 'ACTIVE',
    client_id               varchar(40)  NOT NULL,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT uq_dq_rule UNIQUE (client_id, rule_cd),
    CONSTRAINT ck_dq_rule_severity CHECK (severity_cd IN ('HIGH', 'WARN', 'INFO')),
    CONSTRAINT ck_dq_rule_status CHECK (lifecycle_status_cd IN ('DRAFT', 'ACTIVE', 'INACTIVE'))
);

CREATE INDEX IF NOT EXISTS ix_dqrc_client ON meta.dq_rule_catalog (client_id, rule_cd);

DROP TABLE IF EXISTS meta.dq_rule_attribute CASCADE;

CREATE TABLE IF NOT EXISTS meta.dq_rule_attribute (
    id                      bigserial    PRIMARY KEY,
    rule_cd                 varchar(120) NOT NULL,
    attribute_cd            varchar(120) NOT NULL,
    attribute_role_cd       varchar(40)  NOT NULL,
    client_id               varchar(40)  NOT NULL,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100)
);

CREATE INDEX IF NOT EXISTS ix_dqra_rule ON meta.dq_rule_attribute (client_id, rule_cd);

DROP TABLE IF EXISTS meta.dq_result CASCADE;

CREATE TABLE IF NOT EXISTS meta.dq_result (
    id                      bigserial    PRIMARY KEY,
    rule_cd                 varchar(120) NOT NULL,
    logical_attribute_cd    varchar(120) NOT NULL,
    client_id               varchar(40)  NOT NULL,
    observed_value_txt      varchar(1000),
    expected_value_txt      varchar(1000),
    result_status_cd        varchar(20)  NOT NULL,
    result_reason_txt       text,
    observed_ts             timestamptz  NOT NULL,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT ck_dq_result_status CHECK (result_status_cd IN ('PASS', 'FAIL', 'ERROR'))
);

CREATE INDEX IF NOT EXISTS ix_dqr_lookup ON meta.dq_result (client_id, logical_attribute_cd, observed_ts DESC);

-- ============================================================================
-- 7. DATA PROFILING RESULTS SCHEMA (formerly V12)
-- ============================================================================
DROP TABLE IF EXISTS meta.profiling_result CASCADE;

CREATE TABLE IF NOT EXISTS meta.profiling_result (
    id                      bigserial    PRIMARY KEY,
    client_id               varchar(40)  NOT NULL,
    schema_cd               varchar(120) NOT NULL,
    object_cd               varchar(120) NOT NULL,
    logical_attribute_cd    varchar(120) NOT NULL,
    attribute_role_cd       varchar(40)  NOT NULL,
    null_pct_nbr            integer,
    distinct_pct_nbr        integer,
    profiling_status_cd     varchar(20)  NOT NULL DEFAULT 'ACTIVE',
    last_profiled_ts        timestamptz,
    created_ts              timestamptz  NOT NULL DEFAULT now(),
    created_by              varchar(100) NOT NULL DEFAULT current_user,
    updated_ts              timestamptz,
    updated_by              varchar(100),
    CONSTRAINT ck_pr_status CHECK (profiling_status_cd IN ('ACTIVE', 'INACTIVE', 'STALE'))
);

CREATE INDEX IF NOT EXISTS ix_pr_lookup ON meta.profiling_result (client_id, schema_cd, object_cd, logical_attribute_cd);
