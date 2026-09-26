-- =============================================================================
-- V31: the locale a run was answered in (LP-40.1)
-- =============================================================================
-- Additive, nullable (absent for runs that pre-date localization). locale_source
-- records whether the locale ARRIVED on the request or the default was APPLIED
-- explicitly - a default is never implied. Intelligence never guesses a locale;
-- this is the evidence of which one a run used, not a stored user preference.
-- =============================================================================

ALTER TABLE intelligence.agent_run
    ADD COLUMN IF NOT EXISTS locale        text,
    ADD COLUMN IF NOT EXISTS locale_source text;

ALTER TABLE intelligence.agent_run
    ADD CONSTRAINT agent_run_locale_source_chk
        CHECK (locale_source IS NULL OR locale_source IN ('REQUEST', 'DEFAULT')),
    ADD CONSTRAINT agent_run_locale_pair_chk
        CHECK ((locale IS NULL) = (locale_source IS NULL));
