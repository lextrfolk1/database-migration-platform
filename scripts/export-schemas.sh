#!/usr/bin/env bash
# Exports schema-only DDL (one .sql per schema) plus a table/column structure
# listing, for later verification of migrations.
#
# Usage: scripts/export-schemas.sh [output-dir]
#   PGHOST (localhost) PGPORT (5433) PGDATABASE (lextr) PGUSER (postgres)
#   LEXTR_POSTGRES_PASSWORD — PostgreSQL password
set -euo pipefail

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5433}"
export PGDATABASE="${PGDATABASE:-lextr}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${LEXTR_POSTGRES_PASSWORD:-${PGPASSWORD:-}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${1:-$SCRIPT_DIR/../db-schema-export}"
mkdir -p "$OUT_DIR"

SCHEMAS=$(psql -Atc "select nspname from pg_namespace
  where nspname not in ('pg_catalog','information_schema','public')
    and nspname not like 'pg_toast%' and nspname not like 'pg_temp%'
  order by 1")

for s in $SCHEMAS; do
    echo "Exporting schema: $s"
    pg_dump --schema-only --no-owner --no-privileges --schema="$s" \
        | grep -v -E '^-- Dumped (from|by)|^\\(un)?restrict ' > "$OUT_DIR/$s.sql"

    psql -At -F $'\t' -c "
      select c.table_name, c.ordinal_position, c.column_name,
             c.data_type || coalesce('(' || c.character_maximum_length || ')', ''),
             c.is_nullable, coalesce(c.column_default, '')
      from information_schema.columns c
      join information_schema.tables t
        on t.table_schema = c.table_schema and t.table_name = c.table_name
      where c.table_schema = '$s' and t.table_type = 'BASE TABLE'
      order by c.table_name, c.ordinal_position" \
      | awk -F'\t' 'BEGIN{print "table\t#\tcolumn\ttype\tnullable\tdefault"} {print}' \
      > "$OUT_DIR/$s.structure.tsv"
done

echo "Done. Output: $OUT_DIR"
