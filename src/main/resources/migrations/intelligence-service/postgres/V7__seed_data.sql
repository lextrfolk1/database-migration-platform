-- =============================================================================
-- V7: seed data
-- =============================================================================
-- Folds in the seeds of old V1 (UC1a runnable seed + the fine-tuned variance SLM),
-- V13 (tenants), V20 (governed calibration thresholds) and V38/V39/V40 (evidence
-- coverage registry). Insert order matches the original chain, so identity values
-- are the same (model_registry: 1 Qwen3-4B, 2 MiniLM embedder, 3 variance SLM).
--
-- Tenants:
--   '__platform__'  Tier-1 platform default model rows.
--   '1'    demo tenant carrying the UC1a envelope + preset.
-- =============================================================================

-- ---------------------------------------------------------------------
-- Tenants (preset / agent_run / registered_definition reference these)
-- ---------------------------------------------------------------------
INSERT INTO intelligence.tenant_profile (tenant_id, org_name, tier, isolation_level, status)
VALUES
    ('__platform__', 'Lextr Platform System', 'SYSTEM', 'ROW_LEVEL_SECURITY', 'ACTIVE'),
    ('1', 'Lextr Enterprise Client 001', 'ENTERPRISE', 'ROW_LEVEL_SECURITY', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- UC1a - variance_explanation x Y-9C, skill_pattern 1+3, no KG
-- ---------------------------------------------------------------------
-- 1. Platform Tier-1 default SLM (Qwen3-4B + QLoRA)
INSERT INTO intelligence.model_registry
    (client_id, tier, model_type, model_id, connector_class, adapter_path,
     embedding_model, embedding_dim, is_local, is_default, params, status, created_by)
VALUES ('__platform__', 'platform', 'SLM', 'Qwen3-4B', 'QLoRAChatConnector',
       'data/qlora_adapter/qwen3-4b-fry9c/final', NULL, NULL, true, true,
       '{"quantization":"4bit_nf4","lora_rank":16,"alpha":32,"temperature":0.2,"max_tokens":1024,"enable_thinking":false}'::jsonb,
       'active', 'seed')
ON CONFLICT DO NOTHING;

-- 2. Platform Tier-1 default embedder (all-MiniLM-L6-v2, 384)
INSERT INTO intelligence.model_registry
    (client_id, tier, model_type, model_id, connector_class, adapter_path,
     embedding_model, embedding_dim, is_local, is_default, params, status, created_by)
VALUES ('__platform__', 'platform', 'EMBEDDING', 'sentence-transformers/all-MiniLM-L6-v2',
       'MiniLMEmbeddingConnector', NULL, 'sentence-transformers/all-MiniLM-L6-v2', 384,
       true, true, '{}'::jsonb, 'active', 'seed')
ON CONFLICT DO NOTHING;

-- 3. Governance envelope (MRM-approved) for variance on Y-9C; allowed model = the platform SLM
INSERT INTO intelligence.governance_envelope
    (client_id, envelope_key, version, status, allowed_model_ids, prohibited_model_ids,
     mnpi_rules, data_access, cost_guardrails, opa_policy_bindings,
     mrm_approved_by, mrm_approved_at, created_by)
SELECT '1', 'ENV_VARIANCE_Y9C', 1, 'approved',
       ARRAY[(SELECT id FROM intelligence.model_registry
              WHERE client_id = '__platform__' AND model_type = 'SLM' AND model_id = 'Qwen3-4B')]::bigint[],
       '{}'::bigint[],
       '{"external_forbidden_classifications":["RESTRICTED","MNPI"]}'::jsonb,
       '{"allowed_tiers":["ALLOWED","RESTRICTED"],"excluded_never_returned":true}'::jsonb,
       '{"max_tokens_per_run":4096,"max_cost_per_run_usd":0.50}'::jsonb,
       '[{"id":"OPA-AI-001","package":"lextr.ai.model_routing"},{"id":"OPA-COST-018","package":"lextr.ai.cost_guardrails"}]'::jsonb,
       'seed_mrm', now(), 'seed'
ON CONFLICT DO NOTHING;

-- 4. Prompt template (Element 1) for variance explanation on Y-9C
INSERT INTO intelligence.prompt_template
    (client_id, template_key, version, task, report_type, body, variables, status, created_by)
VALUES ('1', 'TPL_VARIANCE_Y9C', 1, 'variance_explanation', 'Y-9C',
       'You are a regulatory reporting analyst assistant. Explain the period-over-period change in the referenced line using ONLY the masked values, complementary context, and analyst input provided. Reference entities by their placeholder tokens (e.g. {{ENTITY_1_LABEL}}); never invent figures. Cite drivers explicitly (rule change / strategy / market event) where the evidence supports them; state uncertainty otherwise.',
       '["report","schedule","mdrm","period","masked_values","complementary_context","analyst_input"]'::jsonb,
       'active', 'seed')
ON CONFLICT DO NOTHING;

-- 5. The UC1a preset - no Tier-3 model override (resolves to the platform SLM)
INSERT INTO intelligence.preset
    (client_id, preset_key, version, task, report_type, envelope_id,
     prompt_template_id, model_instruction, complementary_context, style,
     guided_questions, prompt_library, model_id_override, skill_pattern,
     is_agentic, max_steps, kg_depth_default, kg_depth_max, output_type,
     review_level, status, is_global, created_by)
SELECT '1', 'UC1A_VARIANCE_Y9C', 1, 'variance_explanation', 'Y-9C',
       (SELECT id FROM intelligence.governance_envelope
        WHERE client_id = '1' AND envelope_key = 'ENV_VARIANCE_Y9C' AND version = 1),
       (SELECT id FROM intelligence.prompt_template
        WHERE client_id = '1' AND template_key = 'TPL_VARIANCE_Y9C' AND version = 1),
       NULL,
       '{"knowledge_hub_refs":[]}'::jsonb,
       '{}'::jsonb,
       '[]'::jsonb,
       '[]'::jsonb,
       NULL,
       '1+3',
       true,
       6,
       3, 5,
       'narrative',
       'analyst',
       'operational',
       false,
       'seed'
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- The fine-tuned variance SLM (local-only; the model the variance presets pin to)
-- ---------------------------------------------------------------------
INSERT INTO intelligence.model_registry (
    client_id, tier, model_type, model_id, connector_class, adapter_path,
    embedding_model, embedding_dim, is_local, is_default, params, secrets_ref,
    status, created_by, created_at
) VALUES (
    '__platform__', 'platform', 'SLM', 'lextr-variance-qwen3-4b-v1', 'QLoRAChatConnector',
    'file:///models/lextr/variance-qwen3-4b-v1', NULL, NULL, TRUE, FALSE,
    jsonb_build_object(
        'fine_tune_version', 'variance-v1',
        'base_model', 'Qwen3-4B',
        'artifact_uri', 'file:///models/lextr/variance-qwen3-4b-v1'
    ),
    NULL, 'active', 'seed', now()
)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- Governed calibration thresholds (observation floor, absolute, relative)
-- ---------------------------------------------------------------------
INSERT INTO intelligence.calibration_threshold (
    client_id, threshold_key, data_type, threshold_value, bounds_min, bounds_max,
    consequence_class, blast_radius, created_by
) VALUES
(
    'default', 'observation_floor', 'integer', 50.0000, 10.0000, 10000.0000,
    'SAFETY_FLOOR', 'Fits below floor refuse promotion with NOT-CALIBRATED state.', 'system'
),
(
    'default', 'absolute_promotion_threshold', 'numeric', 0.1000, 0.0100, 0.5000,
    'ACCURACY_GATE', 'Calibrators with ECE above threshold refuse promotion.', 'system'
),
(
    'default', 'relative_promotion_threshold', 'numeric', 0.0500, 0.0010, 0.2000,
    'MODEL_VALIDATION', 'Calibrators exceeding relative drift threshold fail promotion.', 'system'
)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- Evidence coverage registry - the chained tables the offline verifier can see
-- ---------------------------------------------------------------------
INSERT INTO intelligence.evidence_coverage (table_name, registered_by) VALUES
    ('agent_run_step', 'LP-26.1'), ('agent_run_anchor', 'LP-26.1'),
    ('evidence_archive', 'LP-26.8'), ('agent_run_event', 'LP-26.9'),
    ('evidence_read_event', 'LP-26.24'), ('evidence_export_pack', 'LP-26.24'),
    ('evidence_payload_erasure', 'LP-26.28')
ON CONFLICT DO NOTHING;
