-- =============================================================================
-- V8 — Logical→Physical resolution lookup indexes
-- =============================================================================
-- Supports governed downstream engine resolution by accelerating approved
-- logical-name override lookups and consumption outbound grain expansion.
-- =============================================================================

CREATE INDEX IF NOT EXISTS ix_alno_lookup
    ON meta.attribute_logical_name_override (
        schema_cd,
        object_cd,
        attribute_cd,
        override_status_cd,
        approved_ts DESC,
        requested_ts DESC,
        id DESC
    );

CREATE INDEX IF NOT EXISTS ix_cog_outbound_lookup
    ON meta.consumption_outbound_grain (
        client_id,
        outbound_id,
        grain_level_nbr,
        logical_attribute_cd
    );
