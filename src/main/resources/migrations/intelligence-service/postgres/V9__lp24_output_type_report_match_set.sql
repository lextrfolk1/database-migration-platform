-- LP-24.2 Split 1: Add report_match_set to output_type enum
-- Part-M clean: enum addition in separate transaction
ALTER TYPE intelligence.output_type ADD VALUE IF NOT EXISTS 'report_match_set';
