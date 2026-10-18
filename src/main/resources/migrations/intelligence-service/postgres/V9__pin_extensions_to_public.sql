-- Pin the V1 extensions to schema public.
--
-- V1 creates vector, pg_trgm and pgcrypto without a SCHEMA clause, so they
-- land in the first schema on the migration session's search_path (meta under
-- Flyway). Application SQL uses them unqualified (CAST(... AS vector(384)),
-- <=>) on connections that set no currentSchema, which only resolves while
-- the role's search_path happens to include meta. public is on the default
-- search_path, so pinning the extensions there removes that dependency.
--
-- Guarded: a no-op where an extension is absent or already in public.
-- ALTER EXTENSION ... SET SCHEMA moves the types/operators by OID, so
-- existing vector columns and indexes keep working.

DO $$
DECLARE
    ext text;
BEGIN
    FOREACH ext IN ARRAY ARRAY['vector', 'pg_trgm', 'pgcrypto'] LOOP
        IF EXISTS (SELECT 1 FROM pg_extension
                   WHERE extname = ext
                     AND extnamespace <> 'public'::regnamespace) THEN
            EXECUTE format('ALTER EXTENSION %I SET SCHEMA public', ext);
        END IF;
    END LOOP;
END $$;
