-- =============================================================================
-- V5 — Observability policy presets for signal routing and DQ reruns
-- =============================================================================
-- These presets keep observability automation DB-driven:
-- * route threshold controls when a signal is pushed into workflow
-- * DQ rerun threshold controls when LP-24 is triggered
-- =============================================================================

INSERT INTO governance.policy_preset
  (policy_cd, policy_nm, policy_scope_cd, default_value_txt, data_type_cd,
   is_overrideable_flg, override_requires_approval_flg)
VALUES
  ('GOV-OS-001', 'Observability workflow route severity floor', 'OBSERVABILITY_SIGNAL', 'WARN', 'STRING', true, true),
  ('GOV-OS-002', 'Observability DQ rerun severity floor', 'OBSERVABILITY_SIGNAL', 'HIGH', 'STRING', true, true)
ON CONFLICT (policy_cd) DO NOTHING;
