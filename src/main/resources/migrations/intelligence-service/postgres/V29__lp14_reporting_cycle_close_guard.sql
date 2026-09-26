-- =============================================================================
-- V29: reporting cycle close-as-attestation and reopen-with-reason (LP-14.0)
-- =============================================================================
-- V5 created intelligence.reporting_cycle but nothing enforced its two rules:
--   (1) a CLOSE is REFUSED while analyses bound to the cycle await review, unless
--       the close attestation carries an OVERRIDE that names every outstanding run
--       INDIVIDUALLY (close_attestation.override.outstanding_run_ids) with a reason
--       - never a count;
--   (2) a REOPEN must carry its reason and who reopened it.
-- The rule lives with the data so no writer can skip it. Additive: V5 untouched.
-- =============================================================================

SET search_path TO intelligence, public;

CREATE OR REPLACE FUNCTION intelligence.fn_reporting_cycle_close_guard()
RETURNS TRIGGER AS $$
DECLARE
    outstanding text[];
    named       text[];
BEGIN
    IF NEW.status = 'closed' AND OLD.status IS DISTINCT FROM 'closed' THEN
        SELECT coalesce(array_agg(r.run_id ORDER BY r.run_id), '{}')
          INTO outstanding
          FROM intelligence.agent_run r
         WHERE r.client_id = NEW.client_id
           AND r.cycle_id = NEW.id
           AND r.status IN ('completed', 'in_review');

        IF cardinality(outstanding) > 0 THEN
            IF NEW.close_attestation IS NULL
               OR jsonb_typeof(NEW.close_attestation -> 'override' -> 'outstanding_run_ids') <> 'array'
               OR coalesce(btrim(NEW.close_attestation -> 'override' ->> 'reason'), '') = '' THEN
                RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: % analyses await review in cycle %; an override must name each run and give a reason',
                    cardinality(outstanding), NEW.cycle_key
                    USING ERRCODE = 'check_violation';
            END IF;

            SELECT coalesce(array_agg(v ORDER BY v), '{}')
              INTO named
              FROM jsonb_array_elements_text(NEW.close_attestation -> 'override' -> 'outstanding_run_ids') AS v;

            IF NOT (named @> outstanding) THEN
                RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: override does not name every outstanding run in cycle %', NEW.cycle_key
                    USING ERRCODE = 'check_violation';
            END IF;
        END IF;

        IF NEW.closed_by IS NULL THEN
            RAISE EXCEPTION 'CYCLE_CLOSE_REFUSED: a close is an attestation and must name closed_by'
                USING ERRCODE = 'check_violation';
        END IF;
        NEW.closed_at := coalesce(NEW.closed_at, now());
    END IF;

    IF NEW.status = 'reopened' AND OLD.status IS DISTINCT FROM 'reopened' THEN
        IF coalesce(btrim(NEW.reopen_reason), '') = '' OR NEW.reopened_by IS NULL THEN
            RAISE EXCEPTION 'CYCLE_REOPEN_REFUSED: a reopen must carry reopen_reason and reopened_by'
                USING ERRCODE = 'check_violation';
        END IF;
        NEW.reopened_at := coalesce(NEW.reopened_at, now());
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reporting_cycle_close_guard ON intelligence.reporting_cycle;
CREATE TRIGGER trg_reporting_cycle_close_guard
BEFORE UPDATE ON intelligence.reporting_cycle
FOR EACH ROW EXECUTE FUNCTION intelligence.fn_reporting_cycle_close_guard();
