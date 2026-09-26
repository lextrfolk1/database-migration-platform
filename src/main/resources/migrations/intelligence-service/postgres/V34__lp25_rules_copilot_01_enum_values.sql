-- =============================================================================
-- V34: UC11 Rules Copilot - enum values ONLY (LP-25.2, migration _01)
-- =============================================================================
-- ALTER TYPE ... ADD VALUE cannot have its new value USED in the same
-- transaction, so this migration adds values and uses none; V35 adds columns
-- and references no new value. The split is a correctness requirement.
-- =============================================================================

ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'rule_draft';

-- Knowledge Hub sources a rule author cites beyond regulatory instructions.
ALTER TYPE intelligence.doc_type ADD VALUE IF NOT EXISTS 'policy';
ALTER TYPE intelligence.doc_type ADD VALUE IF NOT EXISTS 'procedure';
ALTER TYPE intelligence.doc_type ADD VALUE IF NOT EXISTS 'standard';
ALTER TYPE intelligence.doc_type ADD VALUE IF NOT EXISTS 'prior_filing';
