-- =============================================================================
-- V6 — Observability signal correlation key index
-- =============================================================================
-- Speeds up observability signal list/filter lookups when clients search by
-- correlation key.
-- =============================================================================

CREATE INDEX IF NOT EXISTS ix_os_client_corr_key
    ON meta.observability_signal (client_id, correlation_key_txt);
