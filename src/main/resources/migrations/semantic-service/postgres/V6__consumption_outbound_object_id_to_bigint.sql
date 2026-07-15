-- meta.consumption_outbound.object_id was a stored uuid, populated at insert time with the
-- (now-removed) fabricated md5-hash-cast-to-uuid form of meta.object_catalog's id. The Java
-- layer reading this column (JdbcConsumptionDao's row mapper, ConsumptionOutboundRecord) already
-- expected a Long/bigint - a pre-existing mismatch, predating the id-display-format cleanup this
-- migration is part of, that would throw a JDBC type-coercion error the first time GET
-- /exposures ran against a populated table. Also fixes a latent type-mismatch in
-- logical_physical_resolution.find_by_outbound_grain's `o.id = co.object_id` join (bigint = uuid
-- previously had no valid operator; the query text itself needs no change, only this column's
-- type).
--
-- Backfill technique matches V5: recompute the same md5 hash the old fabricated-UUID scheme used
-- to find each row's real object_catalog.id. (No rows existed in this table as of writing this
-- migration - verified via psql - so this is a safety net for other environments, not a known
-- live backfill.)

-- Postgres does not allow a subquery in ALTER COLUMN ... TYPE ... USING, so this goes through
-- add-column / backfill / drop / rename instead of a direct type change.
ALTER TABLE meta.consumption_outbound ADD COLUMN object_id_new bigint;

UPDATE meta.consumption_outbound co
SET object_id_new = oc.id
FROM meta.object_catalog oc
WHERE CAST(md5(oc.schema_cd || '/' || oc.object_cd) AS uuid) = co.object_id;

ALTER TABLE meta.consumption_outbound ALTER COLUMN object_id_new SET NOT NULL;

DROP INDEX IF EXISTS meta.ix_co_lookup;

ALTER TABLE meta.consumption_outbound DROP COLUMN object_id;
ALTER TABLE meta.consumption_outbound RENAME COLUMN object_id_new TO object_id;

CREATE INDEX IF NOT EXISTS ix_co_lookup ON meta.consumption_outbound (client_id, object_id, outbound_cd);
