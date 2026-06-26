-- =============================================================================
-- Lextr Semantic Layer — metadata change history lookup index
-- =============================================================================
CREATE INDEX IF NOT EXISTS ix_mch_entity_ref_lookup
    ON meta.metadata_change_history (entity_type_cd, entity_ref, changed_ts DESC);
