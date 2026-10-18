-- VarianceAI schema v1 — architecture §24
-- Service-owned schema; regulatory data (data.*, meta.*) is accessed READ-ONLY
-- via a separate role (invariant I1). Apply with a migration-owner role.

CREATE SCHEMA IF NOT EXISTS variance;

-- ============================================================ enums
DO $$ BEGIN
  CREATE TYPE variance.materiality_tier AS ENUM ('T1_CRITICAL','T2_REVIEW','T3_INFO','T4_BELOW_THRESHOLD');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE variance.comparison_basis AS ENUM ('AS_FILED','AS_RESTATED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE variance.analysis_status AS ENUM ('RUNNING','GENERATED','FAILED','SUPERSEDED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE variance.review_action AS ENUM
    ('CLAIM','APPROVE','APPROVE_WITH_EDITS','REJECT','NEEDS_INFO','INFO_ATTACHED','REGENERATE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE variance.driver_rank AS ENUM ('PRIMARY','SECONDARY');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================ cycle & snapshot
CREATE TABLE IF NOT EXISTS variance.reporting_cycle (
    cycle_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report                TEXT        NOT NULL,               -- FRY9C, CALL, FRY14Q…
    period                DATE        NOT NULL,
    legal_entity          TEXT        NOT NULL,               -- user input, validated vs rpt_run_control (§5.0)
    restatement_version   INT         NOT NULL DEFAULT 0,     -- user input, validated vs rpt_run_control
    comparison_basis      variance.comparison_basis NOT NULL DEFAULT 'AS_FILED',
    status                TEXT        NOT NULL DEFAULT 'OPEN',
    knowledge_snapshot_id TEXT,
    prompt_pinset         JSONB       NOT NULL DEFAULT '{}'::jsonb,
    model_pinset          JSONB       NOT NULL DEFAULT '{}'::jsonb,
    opened_by             TEXT        NOT NULL,
    opened_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (report, period, legal_entity, restatement_version)
);

CREATE TABLE IF NOT EXISTS variance.period_snapshot (
    snapshot_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cycle_id                BIGINT NOT NULL REFERENCES variance.reporting_cycle(cycle_id),
    mdrm_id                 TEXT   NOT NULL,      -- canonical {report}.{taxonomy_id}
    legal_entity            TEXT   NOT NULL,
    schedule                TEXT,
    current_value           NUMERIC(38,4),
    previous_value          NUMERIC(38,4),
    history                 JSONB  NOT NULL DEFAULT '[]'::jsonb,   -- trailing 8Q
    current_exec_id         BIGINT,               -- data.rpt_run_control lineage (§5.0a)
    previous_exec_id        BIGINT,
    rule_version_current    INT,
    rule_version_previous   INT,
    rule_json_hash_current  TEXT,                 -- methodology-change detection (§5.0c)
    rule_json_hash_previous TEXT,
    source_extract_ref      TEXT,
    extracted_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (cycle_id, mdrm_id, legal_entity)
);

CREATE TABLE IF NOT EXISTS variance.source_node_map (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report         TEXT NOT NULL,
    schedule       TEXT,
    node_id        INT  NOT NULL,                 -- data.inbound_run_control node (§5.0b)
    description    TEXT,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to   DATE
);

CREATE TABLE IF NOT EXISTS variance.threshold_config (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scope          TEXT NOT NULL CHECK (scope IN ('report','schedule','mdrm')),
    scope_key      TEXT NOT NULL,
    pct_threshold  NUMERIC(9,4),
    abs_threshold  NUMERIC(38,4),
    tier_rules     JSONB NOT NULL DEFAULT '{}'::jsonb,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to   DATE,
    approved_by    TEXT NOT NULL,
    UNIQUE (scope, scope_key, effective_from)
);

-- ============================================================ detection & analysis
CREATE TABLE IF NOT EXISTS variance.variance_item (
    variance_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cycle_id     BIGINT NOT NULL REFERENCES variance.reporting_cycle(cycle_id),
    mdrm_id      TEXT   NOT NULL,
    legal_entity TEXT   NOT NULL,
    schedule     TEXT,
    abs_variance NUMERIC(38,4),
    pct_variance NUMERIC(12,6),
    zscore_8q    NUMERIC(10,4),
    tier         variance.materiality_tier NOT NULL,
    flags        JSONB NOT NULL DEFAULT '{}'::jsonb,   -- rule_change, restatement_divergence, sign_flip…
    detected_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (cycle_id, mdrm_id, legal_entity)
);
CREATE INDEX IF NOT EXISTS ix_variance_item_cycle_tier ON variance.variance_item (cycle_id, tier);
CREATE INDEX IF NOT EXISTS ix_variance_item_mdrm       ON variance.variance_item (mdrm_id);

CREATE TABLE IF NOT EXISTS variance.analysis (
    analysis_id      TEXT   PRIMARY KEY,               -- va_<uuid>
    variance_id      BIGINT NOT NULL REFERENCES variance.variance_item(variance_id),
    version          INT    NOT NULL DEFAULT 1,
    status           variance.analysis_status NOT NULL DEFAULT 'RUNNING',
    result           JSONB,                            -- variance_explanation.v1
    confidence       NUMERIC(4,3),
    confidence_level TEXT,
    input_hash       TEXT,
    output_hash      TEXT,
    trace_id         TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (variance_id, version)
);
CREATE INDEX IF NOT EXISTS ix_analysis_result_gin ON variance.analysis USING GIN (result);

CREATE TABLE IF NOT EXISTS variance.driver_taxonomy (
    driver_code    TEXT PRIMARY KEY,
    version        INT  NOT NULL DEFAULT 1,
    name           TEXT NOT NULL,
    definition     TEXT NOT NULL,
    exemplars      JSONB NOT NULL DEFAULT '[]'::jsonb,
    status         TEXT NOT NULL DEFAULT 'ACTIVE',
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS variance.driver_assignment (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    analysis_id   TEXT NOT NULL REFERENCES variance.analysis(analysis_id),
    driver_code   TEXT NOT NULL REFERENCES variance.driver_taxonomy(driver_code),
    rank          variance.driver_rank NOT NULL,
    contribution_pct NUMERIC(6,3) CHECK (contribution_pct BETWEEN 0 AND 100),
    reason        TEXT,
    confidence    NUMERIC(4,3)
);

CREATE TABLE IF NOT EXISTS variance.evidence (
    evidence_id           TEXT PRIMARY KEY,             -- ev_<uuid>
    analysis_id           TEXT NOT NULL REFERENCES variance.analysis(analysis_id),
    source_type           TEXT NOT NULL,
    source_ref            TEXT NOT NULL,
    reliability           TEXT NOT NULL CHECK (reliability IN ('HIGH','MEDIUM','LOW')),
    summary               TEXT,
    retrieval_score       NUMERIC(6,5),
    chunk_ids             UUID[],
    knowledge_snapshot_id TEXT
);

CREATE TABLE IF NOT EXISTS variance.driver_evidence_link (
    driver_assignment_id BIGINT NOT NULL REFERENCES variance.driver_assignment(id),
    evidence_id          TEXT   NOT NULL REFERENCES variance.evidence(evidence_id),
    entailment_score     NUMERIC(6,5),
    PRIMARY KEY (driver_assignment_id, evidence_id)
);

-- ============================================================ review & feedback
CREATE TABLE IF NOT EXISTS variance.review (
    review_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    analysis_id       TEXT NOT NULL REFERENCES variance.analysis(analysis_id),
    reviewer_id       TEXT NOT NULL,
    action            variance.review_action NOT NULL,
    edited_narrative  TEXT,
    narrative_diff    JSONB,
    reason_code       TEXT,   -- WRONG_DRIVER | MISSING_EVIDENCE | TONE | NUMBER_ERROR | INCOMPLETE | OTHER
    answers           JSONB,
    second_approver_id TEXT,
    acted_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_review_analysis ON variance.review (analysis_id, acted_at);

CREATE TABLE IF NOT EXISTS variance.feedback_label (
    label_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    analysis_id TEXT NOT NULL REFERENCES variance.analysis(analysis_id),
    label_type  TEXT NOT NULL,
    payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================ governance registries
CREATE TABLE IF NOT EXISTS variance.prompt_registry (
    name            TEXT NOT NULL,
    version         TEXT NOT NULL,
    content_hash    TEXT NOT NULL,
    template_ref    TEXT NOT NULL,
    schema_ref      TEXT,
    status          TEXT NOT NULL DEFAULT 'DRAFT'
                    CHECK (status IN ('DRAFT','EVAL_PASSED','APPROVED','ACTIVE','RETIRED')),
    eval_report_ref TEXT,
    approved_by     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (name, version)
);

CREATE TABLE IF NOT EXISTS variance.model_registry (
    model_key       TEXT PRIMARY KEY,          -- e.g. openai:gpt-5.5:snap-2026-05-01
    provider        TEXT NOT NULL,
    model_id        TEXT NOT NULL,
    snapshot_pin    TEXT,
    params          JSONB NOT NULL DEFAULT '{}'::jsonb,
    status          TEXT NOT NULL DEFAULT 'DRAFT',
    eval_report_ref TEXT,
    approved_by     TEXT,
    effective_from  DATE
);

-- seed the closed driver taxonomy (invariant I4)
INSERT INTO variance.driver_taxonomy (driver_code, name, definition) VALUES
 ('RULE_METHODOLOGY_CHANGE','Rule / Methodology Change','Change in report rule logic, mappings, or methodology between periods'),
 ('BUSINESS_STRATEGY','Business Strategy','Deliberate business growth, contraction, or repositioning'),
 ('MARKET_EVENT','Market Event','External market disruption or event-driven movement'),
 ('PORTFOLIO_MIX_CHANGE','Portfolio Mix Change','Shift in composition across products, segments, or asset classes'),
 ('CREDIT_QUALITY','Credit Quality','Migration in credit quality, provisions, charge-offs, or recoveries'),
 ('INTEREST_RATE_MOVEMENT','Interest Rate Movement','Rate-driven valuation, income, or behavioral change'),
 ('FOREIGN_EXCHANGE','Foreign Exchange','FX translation or transaction effects'),
 ('SEASONALITY','Seasonality','Recurring intra-year pattern'),
 ('ACCOUNTING_ADJUSTMENT','Accounting Adjustment','GAAP/regulatory accounting adjustment or reclassification'),
 ('DATA_CORRECTION','Data Correction','Correction of prior data error'),
 ('ACQUISITION_DIVESTITURE','Acquisition / Divestiture','M&A, divestiture, or scope change'),
 ('FUNDING_STRATEGY','Funding Strategy','Change in funding composition or strategy'),
 ('CAPITAL_MANAGEMENT','Capital Management','Capital actions: buybacks, issuance, dividends, RWA management'),
 ('OTHER','Other','Requires analyst attention; must include reason and question')
ON CONFLICT (driver_code) DO NOTHING;
