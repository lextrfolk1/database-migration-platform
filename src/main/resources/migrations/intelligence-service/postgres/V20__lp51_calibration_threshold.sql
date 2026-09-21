-- =====================================================================
-- LP-51.4 Flyway Migration: Calibration Thresholds & Governed Rows
-- Additive migration creating intelligence.calibration_threshold table,
-- check constraints, immutability trigger, and initial governed thresholds.
-- Part-M-clean (identifiers <= 32 chars).
-- =====================================================================

-- 1. Ensure definition_kind enum carries 'calibrator' (idempotent)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'intelligence' AND t.typname = 'definition_kind'
    ) THEN
        BEGIN
            ALTER TYPE intelligence.definition_kind ADD VALUE IF NOT EXISTS 'calibrator';
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END;
    END IF;
END $$;

-- 2. Create Table: intelligence.calibration_threshold
CREATE TABLE IF NOT EXISTS intelligence.calibration_threshold (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    threshold_key VARCHAR(64) NOT NULL,
    data_type VARCHAR(32) NOT NULL,
    threshold_value NUMERIC(10, 4) NOT NULL,
    bounds_min NUMERIC(10, 4) NOT NULL,
    bounds_max NUMERIC(10, 4) NOT NULL,
    consequence_class VARCHAR(64) NOT NULL,
    blast_radius TEXT NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ,
    superseded_by_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',

    -- Constraints
    CONSTRAINT chk_cal_thresh_bounds CHECK (bounds_min <= threshold_value AND threshold_value <= bounds_max),
    CONSTRAINT chk_cal_thresh_type CHECK (data_type IS NOT NULL AND length(trim(data_type)) > 0),
    CONSTRAINT chk_cal_thresh_consequence CHECK (consequence_class IS NOT NULL AND length(trim(consequence_class)) > 0),
    CONSTRAINT chk_cal_thresh_blast CHECK (blast_radius IS NOT NULL AND length(trim(blast_radius)) > 0),
    CONSTRAINT chk_cal_thresh_key CHECK (threshold_key IN ('observation_floor', 'absolute_promotion_threshold', 'relative_promotion_threshold'))
);

-- Indexes for active effective threshold lookups
CREATE INDEX IF NOT EXISTS idx_cal_thresh_lookup ON intelligence.calibration_threshold (
    client_id, threshold_key, effective_from, effective_to
);

-- Unique index ensuring at most one active threshold per client and key
CREATE UNIQUE INDEX IF NOT EXISTS uq_cal_thresh_active ON intelligence.calibration_threshold (
    client_id, threshold_key
) WHERE effective_to IS NULL;

-- 3. Immutability Trigger (superseded, never updated in place)
CREATE OR REPLACE FUNCTION intelligence.fn_calibration_threshold_immutable()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'Calibration thresholds are immutable and cannot be updated in place. Supersede with a new effective row.';
    ELSIF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'Calibration thresholds are immutable and cannot be deleted.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cal_thresh_immutable ON intelligence.calibration_threshold;
CREATE TRIGGER trg_cal_thresh_immutable
BEFORE UPDATE OR DELETE ON intelligence.calibration_threshold
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_calibration_threshold_immutable();

-- 4. Initial Governed Seed Rows (observation floor, absolute threshold, relative threshold)
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
ON CONFLICT (client_id, threshold_key) WHERE effective_to IS NULL DO NOTHING;
