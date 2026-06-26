-- =============================================================================
-- Lextr Semantic Layer — external rule-engine output result ingest
-- =============================================================================
-- Additive migration: persists governed outputs emitted by external rule engines
-- against a tenant-scoped outbound reference and engine-controlled rule reference.
-- =============================================================================

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
