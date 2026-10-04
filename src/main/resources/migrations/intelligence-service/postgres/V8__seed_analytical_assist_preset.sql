-- =====================================================================
-- UC10 Analytical Assist: the governed, family-less preset for tenant 1 (PENDING_FEATURES 10.5)
--
-- Until now every UC10 run fell back to a preset built in code (AnalyticalPresetResolverImpl,
-- preset_id 99903). This seeds the real one the resolver looks up:
--   task = 'ANALYTICAL_ASSIST', report_type IS NULL, status = 'operational'.
-- UC10 discovery makes no model call (the parse and matching are deterministic and on-prem, LP-24.5), so
-- its envelope allows no model and binds only the analytical tool scope. kg_depth is the table's minimum:
-- discovery does not walk the graph.
-- Idempotent: each insert is skipped when its row already exists.
-- =====================================================================

INSERT INTO intelligence.governance_envelope
    (client_id, envelope_key, version, status, allowed_model_ids, prohibited_model_ids,
     mnpi_rules, data_access, cost_guardrails, opa_policy_bindings,
     mrm_approved_by, mrm_approved_at, created_by)
SELECT '1', 'ENV_ANALYTICAL_ASSIST', 1, 'approved',
       '{}'::bigint[],
       '{}'::bigint[],
       '{"external_forbidden_classifications":["RESTRICTED","MNPI"]}'::jsonb,
       '{"report_metadata_only":true,"values_read":false}'::jsonb,
       '{"max_tokens_per_run":0,"max_cost_per_run_usd":0}'::jsonb,
       '[{"package":"lextr.ai.tool_scope_analytical"}]'::jsonb,
       'seed_mrm', now(), 'seed'
WHERE NOT EXISTS (SELECT 1 FROM intelligence.governance_envelope
                  WHERE client_id = '1' AND envelope_key = 'ENV_ANALYTICAL_ASSIST' AND version = 1);

INSERT INTO intelligence.preset
    (client_id, preset_key, version, task, report_type, envelope_id,
     prompt_template_id, model_instruction, complementary_context, style,
     guided_questions, prompt_library, model_id_override, skill_pattern,
     is_agentic, max_steps, kg_depth_default, kg_depth_max, output_type,
     review_level, status, is_global, created_by)
SELECT '1', 'UC10_ANALYTICAL_DISCOVERY', 1, 'ANALYTICAL_ASSIST', NULL,
       (SELECT id FROM intelligence.governance_envelope
        WHERE client_id = '1' AND envelope_key = 'ENV_ANALYTICAL_ASSIST' AND version = 1),
       NULL,
       'Analytical assist report discovery and construction',
       '{}'::jsonb,
       '{}'::jsonb,
       '[]'::jsonb,
       '[]'::jsonb,
       NULL,
       'analytical_assist_discovery',
       false,
       6,
       1, 1,
       'report_match_set',
       'analyst',
       'operational',
       false,
       'seed'
WHERE NOT EXISTS (SELECT 1 FROM intelligence.preset
                  WHERE client_id = '1' AND preset_key = 'UC10_ANALYTICAL_DISCOVERY' AND version = 1);
