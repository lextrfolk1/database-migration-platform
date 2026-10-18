-- Pin the V3 vector extension to schema public.
--
-- V3 creates vector without a SCHEMA clause, so it lands in the first schema
-- on the migration session's search_path (meta under Flyway).
-- service/variance/knowledge/pg_store.py uses it unqualified
-- (CAST(:query_vector AS vector), <=>), which only resolves while the role's
-- search_path happens to include meta. public is on the default search_path.
--
-- Guarded: a no-op where vector is absent or already in public (for example
-- when intelligence-service V9 has already moved it).

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension
               WHERE extname = 'vector'
                 AND extnamespace <> 'public'::regnamespace) THEN
        ALTER EXTENSION vector SET SCHEMA public;
    END IF;
END $$;
