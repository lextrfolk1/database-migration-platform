-- Knowledge graph: driver-impacts-line and document-to-document relations.
-- (doc/knowledge-graph-design.md §3.2)
--
-- One edge table for two edge kinds, rather than two parallel tables:
--   DRIVER_IMPACTS_LINE      DRIVER -> MDRM_LINE   (derived, best-effort, from every
--                                                    completed analysis' drivers)
--   DOCUMENT_IMPACTS_LINE    DOCUMENT -> MDRM_LINE (curated)
--   SUPERSEDES / REFERENCES / CONTRADICTS / RELATED_TO   DOCUMENT -> DOCUMENT (curated;
--                                                    LLM-extracted is a phase 2 follow-on)
--
-- Nodes are typed references (node_type, node_id), not rows in a node table — the
-- underlying entities already have identity (knowledge_document.doc_id, the canonical
-- MDRM id string, the Driver enum value) and a node table would just duplicate that.
--
-- Deliberately does not touch variance.driver_assignment / variance.evidence /
-- variance.driver_evidence_link (001_variance_schema.sql) — those are pre-existing dead
-- schema (defined, never written to); this feature does not depend on them (see the
-- design doc §3.2 for why).

CREATE TABLE IF NOT EXISTS variance.graph_edge (
    edge_id           TEXT PRIMARY KEY,
    source_type       TEXT NOT NULL CHECK (source_type IN ('DOCUMENT','MDRM_LINE','DRIVER')),
    source_id         TEXT NOT NULL,
    target_type       TEXT NOT NULL CHECK (target_type IN ('DOCUMENT','MDRM_LINE','DRIVER')),
    target_id         TEXT NOT NULL,
    relation_type     TEXT NOT NULL CHECK (relation_type IN (
                          'DRIVER_IMPACTS_LINE', 'DOCUMENT_IMPACTS_LINE',
                          'SUPERSEDES', 'REFERENCES', 'CONTRADICTS', 'RELATED_TO')),
    confidence        NUMERIC(4,3) CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
    contribution_pct  NUMERIC(6,3) CHECK (contribution_pct IS NULL
                                          OR contribution_pct BETWEEN 0 AND 100),
    evidence_ref      TEXT,
    provenance        TEXT NOT NULL,
    created_by        TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata          JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS ix_graph_edge_source ON variance.graph_edge (source_type, source_id);
CREATE INDEX IF NOT EXISTS ix_graph_edge_target ON variance.graph_edge (target_type, target_id);
CREATE INDEX IF NOT EXISTS ix_graph_edge_relation ON variance.graph_edge (relation_type);
