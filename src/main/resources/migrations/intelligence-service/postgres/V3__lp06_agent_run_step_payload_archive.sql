-- =====================================================================
-- PENDING OWNER APPROVAL: Flyway Migration (LP-06.5 / LEX-28)
-- Additive archive columns on intelligence.agent_run_step
-- All columns are NULLABLE with NO DEFAULT.
-- Reuses baseline enum intelligence.data_classification.
-- =====================================================================

ALTER TABLE intelligence.agent_run_step
    ADD COLUMN IF NOT EXISTS payload_hash                text,
    ADD COLUMN IF NOT EXISTS payload_ref                 text,
    ADD COLUMN IF NOT EXISTS payload_truncated           boolean,
    ADD COLUMN IF NOT EXISTS model_input_hash            text,
    ADD COLUMN IF NOT EXISTS model_input_ref             text,
    ADD COLUMN IF NOT EXISTS payload_classification      intelligence.data_classification,
    ADD COLUMN IF NOT EXISTS model_input_classification  intelligence.data_classification;

-- ---------------------------------------------------------------------
-- Integrity Constraints:
-- 1. A payload reference requires a verifiable payload hash.
-- 2. A model input reference requires a verifiable model input hash.
-- Availability states:
--   - INLINE: input IS NOT NULL, payload_ref IS NULL
--   - ARCHIVED: input IS NULL, payload_ref IS NOT NULL, payload_hash IS NOT NULL
--   - NO_PAYLOAD: input IS NULL, payload_ref IS NULL
-- ---------------------------------------------------------------------
ALTER TABLE intelligence.agent_run_step
    ADD CONSTRAINT agent_run_step_payload_ref_hash_chk
        CHECK (payload_ref IS NULL OR payload_hash IS NOT NULL);

ALTER TABLE intelligence.agent_run_step
    ADD CONSTRAINT agent_run_step_model_input_ref_hash_chk
        CHECK (model_input_ref IS NULL OR model_input_hash IS NOT NULL);

-- ---------------------------------------------------------------------
-- Comments
-- ---------------------------------------------------------------------
COMMENT ON COLUMN intelligence.agent_run_step.payload_hash IS 'RFC 8785 canonical SHA-256 hash of step payload. Required if payload_ref is present.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_ref IS 'Content-addressed object store URI for offloaded step payload body.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_truncated IS 'Indicates if payload body exceeded size limits prior to hashing/archiving.';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_hash IS 'RFC 8785 canonical SHA-256 hash of direct model prompt input.';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_ref IS 'Content-addressed object store URI for model prompt input.';
COMMENT ON COLUMN intelligence.agent_run_step.payload_classification IS 'Per-object data classification (independent of step classification).';
COMMENT ON COLUMN intelligence.agent_run_step.model_input_classification IS 'Per-object data classification for model prompt input.';
