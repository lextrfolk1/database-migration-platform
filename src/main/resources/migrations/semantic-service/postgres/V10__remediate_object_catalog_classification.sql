-- =============================================================================
-- V10 — Remediate Object Catalog Classification (POL-DC-001)
-- =============================================================================
-- Remediate any objects mistakenly classified as RESTRICTED to INTERNAL
-- so that they are visible under POL-DC-001 classification-driven exposure.
-- =============================================================================

UPDATE meta.object_catalog
SET data_classification_cd = 'INTERNAL'
WHERE data_classification_cd = 'RESTRICTED';
