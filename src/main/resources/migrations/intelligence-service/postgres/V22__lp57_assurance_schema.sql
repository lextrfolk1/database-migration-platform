-- LP-57.4: Knowledge Hub Document Assurance Schema Migration
-- Per-document assurance runs and granular six-facet item evaluation records.
-- Append-only immutability; staleness is derived from document version and profile version.

CREATE TABLE IF NOT EXISTS intelligence.document_assurance_run (
    run_id VARCHAR(64) PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    document_id VARCHAR(64) NOT NULL,
    document_version_id VARCHAR(64) NOT NULL,
    drop_profile_version VARCHAR(64) NOT NULL,
    retrieval_mode VARCHAR(64) NOT NULL,
    as_of_date DATE NOT NULL,
    service_identity VARCHAR(64) NOT NULL DEFAULT 'svc.assurance',
    total_questions INT NOT NULL,
    verifiable_count INT NOT NULL,
    passed_count INT NOT NULL,
    pass_rate NUMERIC(5,4) NOT NULL,
    ablated_run BOOLEAN NOT NULL DEFAULT false,
    judgement_status VARCHAR(64) NOT NULL DEFAULT 'PENDING_REVIEW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(64) NOT NULL DEFAULT 'svc.assurance',
    CONSTRAINT chk_doc_assr_ver CHECK (length(trim(document_version_id)) > 0),
    CONSTRAINT chk_doc_assr_profile CHECK (length(trim(drop_profile_version)) > 0),
    CONSTRAINT chk_doc_assr_rate CHECK (pass_rate >= 0.0 AND pass_rate <= 1.0)
);

CREATE TABLE IF NOT EXISTS intelligence.document_assurance_item (
    item_id VARCHAR(64) PRIMARY KEY,
    run_id VARCHAR(64) NOT NULL REFERENCES intelligence.document_assurance_run(run_id),
    client_id VARCHAR(64) NOT NULL,
    question_id VARCHAR(64) NOT NULL,
    prompt TEXT NOT NULL,
    expected_anchor_id VARCHAR(64) NOT NULL,
    retrieved_anchor_id VARCHAR(64),
    anchor_matched BOOLEAN NOT NULL,
    rank INT,
    verifiable BOOLEAN NOT NULL,
    answered BOOLEAN NOT NULL,
    grounded BOOLEAN NOT NULL,
    value_present BOOLEAN NOT NULL,
    complete BOOLEAN NOT NULL,
    citation_ok BOOLEAN NOT NULL,
    confidence NUMERIC(5,4) NOT NULL,
    citation_doc_id VARCHAR(64),
    citation_page INT,
    citation_section VARCHAR(256),
    citation_content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices for efficient client, document, and version scoping
CREATE INDEX IF NOT EXISTS idx_doc_assr_run_client_doc_ver
    ON intelligence.document_assurance_run (client_id, document_id, document_version_id);

CREATE INDEX IF NOT EXISTS idx_doc_assr_item_run
    ON intelligence.document_assurance_item (run_id, client_id);

-- Append-only immutability trigger for assurance records
CREATE OR REPLACE FUNCTION intelligence.fn_prevent_assurance_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Assurance records are append-only. Modification or deletion prohibited.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_assurance_run_mutation ON intelligence.document_assurance_run;
CREATE TRIGGER trg_prevent_assurance_run_mutation
    BEFORE UPDATE OR DELETE ON intelligence.document_assurance_run
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_assurance_mutation();

DROP TRIGGER IF EXISTS trg_prevent_assurance_item_mutation ON intelligence.document_assurance_item;
CREATE TRIGGER trg_prevent_assurance_item_mutation
    BEFORE UPDATE OR DELETE ON intelligence.document_assurance_item
    FOR EACH ROW
    EXECUTE FUNCTION intelligence.fn_prevent_assurance_mutation();
