-- =============================================================================
-- V4 — Data Observability Signal Ingest
-- =============================================================================
-- Tenant-scoped signal ingest table for the shared data observability workflow.
-- External tooling posts pipeline/store signals here; semantic-layer services
-- correlate them, can route to wkfl.workflow_task, and may trigger LP-24 DQ
-- reruns downstream.
-- =============================================================================

-- ============================================================================
-- meta.observability_signal — ingested signal envelope + correlation state
-- ============================================================================
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
