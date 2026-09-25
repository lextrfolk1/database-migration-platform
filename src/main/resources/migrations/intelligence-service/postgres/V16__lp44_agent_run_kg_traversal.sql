-- ============================================================================
-- Migration: V20260916_13__lp44_agent_run_kg_traversal.sql
-- Sub-task: LP-44.4 (Java / Spring & Flyway Evidence Storage)
-- Description: Creates child table intelligence.agent_run_kg_traversal
-- Enforces:
-- 1. Snapshot ID required or declared degradation (never null without declared fallback)
-- 2. Declared degradation never written to snapshot_id
-- 3. Depth walked and STOP bound on incomplete runs
-- 4. graph_edge_rule_kind_chk (AMD-DAT-38): edges JSONB enforces rule_kind on RULE
-- ============================================================================

CREATE TABLE IF NOT EXISTS intelligence.agent_run_kg_traversal (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    run_id VARCHAR(64) NOT NULL,
    step_number INT NOT NULL,
    op_name VARCHAR(64) NOT NULL,
    root_node_id VARCHAR(128) NOT NULL,
    snapshot_id VARCHAR(128),
    degradation_hash VARCHAR(128),
    is_degraded BOOLEAN NOT NULL DEFAULT FALSE,
    depth_walked INT NOT NULL,
    is_complete BOOLEAN NOT NULL DEFAULT TRUE,
    stop_bound VARCHAR(64),
    node_count INT NOT NULL DEFAULT 0,
    edge_count INT NOT NULL DEFAULT 0,
    edges JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(128) NOT NULL DEFAULT 'system',

    -- Constraint 1: Snapshot ID or declared degradation required
    CONSTRAINT chk_snapshot_or_degraded CHECK (
        snapshot_id IS NOT NULL OR (is_degraded = TRUE AND degradation_hash IS NOT NULL)
    ),

    -- Constraint 2: Degraded hash is never written into snapshot_id field
    CONSTRAINT chk_degradation_distinct CHECK (
        is_degraded = FALSE OR snapshot_id IS NULL
    ),

    -- Constraint 3: Incomplete run must record stop bound
    CONSTRAINT chk_stop_bound_on_incomplete CHECK (
        is_complete = TRUE OR stop_bound IS NOT NULL
    ),

    -- Constraint 4: graph_edge_rule_kind_chk (AMD-DAT-38)
    -- Asserts that for every edge with provenance = 'RULE', rule_kind is not null
    CONSTRAINT graph_edge_rule_kind_chk CHECK (
        NOT (edges @> '[{"provenance": "RULE", "rule_kind": null}]'::jsonb)
    )
);

CREATE INDEX IF NOT EXISTS idx_kg_traversal_step
    ON intelligence.agent_run_kg_traversal (client_id, run_id, step_number);

CREATE INDEX IF NOT EXISTS idx_kg_traversal_snapshot
    ON intelligence.agent_run_kg_traversal (client_id, snapshot_id)
    WHERE snapshot_id IS NOT NULL;
