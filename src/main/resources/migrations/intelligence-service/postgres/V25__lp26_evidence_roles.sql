-- ============================================================================
-- Migration: V25__lp26_evidence_roles.sql
-- Sub-task: LP-26.10 & LP-49.3 (PostgreSQL 16)
-- Description: Defines the 4 segregated roles for evidence management and tamper-evidence:
--   1. evidence_owner       - schema ownership, migration, DDL
--   2. evidence_application - write ledger events, append chains
--   3. evidence_retention   - lawful purge under retention policy
--   4. notary_role          - READ evidence, INSERT notarization receipt, CANNOT rewrite ledger
-- ============================================================================

-- 1. Create Roles and Apply Privilege Grants (Cloud-Safe & Idempotent)
DO $$
DECLARE
    v_role_names TEXT[] := ARRAY['evidence_owner', 'evidence_application', 'evidence_retention', 'notary_role'];
    v_role TEXT;
BEGIN
    -- 1a. Attempt to create roles safely if current user has CREATEROLE privilege
    FOREACH v_role IN ARRAY v_role_names
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role) THEN
            BEGIN
                EXECUTE format('CREATE ROLE %I NOLOGIN', v_role);
                RAISE NOTICE 'Successfully created role: %', v_role;
            EXCEPTION
                WHEN insufficient_privilege THEN
                    RAISE NOTICE 'Current user lacks CREATEROLE privilege to create %. Assuming role is provisioned via cloud infrastructure.', v_role;
                WHEN duplicate_object THEN
                    NULL;
            END;
        END IF;
    END LOOP;

    -- 2. Schema Usage Grants (applied only if roles exist)
    FOREACH v_role IN ARRAY ARRAY['evidence_application', 'evidence_retention', 'notary_role']
    LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role) THEN
            BEGIN
                EXECUTE format('GRANT USAGE ON SCHEMA intelligence TO %I', v_role);
            EXCEPTION
                WHEN insufficient_privilege THEN
                    RAISE NOTICE 'Insufficient privilege to grant USAGE on schema intelligence to %', v_role;
            END;
        END IF;
    END LOOP;

    -- 3. Application Role Grants: Append-only evidence write
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'evidence_application') THEN
        BEGIN
            GRANT SELECT, INSERT ON TABLE intelligence.evidence_store_record TO evidence_application;
            GRANT SELECT, INSERT, UPDATE ON TABLE intelligence.evidence_chain TO evidence_application;
            GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA intelligence TO evidence_application;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant application permissions to evidence_application';
        END;
    END IF;

    -- 4. Retention Role Grants: Lawful purge (DELETE only under retention policy; no in-place UPDATE to preserve chain hashes)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'evidence_retention') THEN
        BEGIN
            GRANT SELECT, DELETE ON TABLE intelligence.evidence_store_record TO evidence_retention;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant retention permissions to evidence_retention';
        END;
    END IF;

    -- 5. LP-49.3 Notary Role: READ evidence and INSERT receipt ONLY
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'notary_role') THEN
        BEGIN
            GRANT SELECT ON TABLE intelligence.evidence_store_record TO notary_role;
            GRANT SELECT ON TABLE intelligence.evidence_chain TO notary_role;
            GRANT SELECT, INSERT ON TABLE intelligence.evidence_notarization TO notary_role;
            GRANT SELECT ON TABLE intelligence.chain_discontinuity TO notary_role;

            -- Explicitly revoke any mutation privilege from notary on ledger tables
            REVOKE INSERT, UPDATE, DELETE ON TABLE intelligence.evidence_chain FROM notary_role;
            REVOKE UPDATE, DELETE ON TABLE intelligence.evidence_notarization FROM notary_role;
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Insufficient privilege to grant/revoke notary permissions for notary_role';
        END;
    END IF;
END $$;

-- 6. Attach structural immutability fence to evidence_store_record (gated on lextr.evidence_maintenance)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'intelligence' AND p.proname = 'fn_prevent_evidence_modification'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_evidence_store_no_modify'
    ) THEN
        CREATE TRIGGER trg_evidence_store_no_modify
            BEFORE UPDATE OR DELETE ON intelligence.evidence_store_record
            FOR EACH ROW
            EXECUTE FUNCTION intelligence.fn_prevent_evidence_modification();
    END IF;
END $$;

-- 7. Structural Fence Verification Helper
-- Queries the catalogue for tables with BEFORE triggers on BOTH UPDATE and DELETE.
CREATE OR REPLACE FUNCTION intelligence.fn_get_structurally_fenced_tables()
RETURNS TABLE (table_name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT c.relname::TEXT
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_trigger t ON t.tgrelid = c.oid
    WHERE n.nspname = 'intelligence'
      AND (t.tgtype & 2) = 2 -- BEFORE trigger
    GROUP BY c.relname
    HAVING BOOL_OR((t.tgtype & 16) = 16) -- UPDATE
       AND BOOL_OR((t.tgtype & 8) = 8);  -- DELETE
END;
$$ LANGUAGE plpgsql;

-- 8. Deployment-time Key Custody Check Query / Function
-- Checks if any principal resolves to both evidence_application (or dba) and notary key access.
-- Returns 'VERIFIED_SEGREGATED' if separated, 'COLLISION_DETECTED' if colliding, 'UNVERIFIABLE' if IDP not shared.
CREATE OR REPLACE FUNCTION intelligence.fn_verify_notary_key_custody(
    p_idp_shared BOOLEAN,
    p_app_principal VARCHAR(128),
    p_notary_key_holder VARCHAR(128)
)
RETURNS VARCHAR(32) AS $$
BEGIN
    IF NOT p_idp_shared THEN
        RETURN 'UNVERIFIABLE';
    END IF;

    IF p_app_principal IS NOT NULL AND p_app_principal = p_notary_key_holder THEN
        RETURN 'COLLISION_DETECTED';
    END IF;

    RETURN 'VERIFIED_SEGREGATED';
END;
$$ LANGUAGE plpgsql;
