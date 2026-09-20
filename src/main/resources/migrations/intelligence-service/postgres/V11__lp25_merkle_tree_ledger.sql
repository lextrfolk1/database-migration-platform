-- LP-25.1: Merkle Tree Audit Ledger Schema Migration
-- Establishes tamper-evident Merkle tree ledger and cryptographic node index tables

CREATE TABLE IF NOT EXISTS intelligence.merkle_tree_ledger (
    id BIGSERIAL PRIMARY KEY,
    tree_id VARCHAR(64) NOT NULL UNIQUE,
    client_id VARCHAR(64) NOT NULL,
    root_hash VARCHAR(64) NOT NULL,
    leaf_count INT NOT NULL DEFAULT 0,
    tree_depth INT NOT NULL DEFAULT 0,
    is_sealed BOOLEAN NOT NULL DEFAULT FALSE,
    sealed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS intelligence.merkle_tree_node (
    id BIGSERIAL PRIMARY KEY,
    tree_id VARCHAR(64) NOT NULL REFERENCES intelligence.merkle_tree_ledger(tree_id) ON DELETE CASCADE,
    node_hash VARCHAR(64) NOT NULL,
    level INT NOT NULL,
    position INT NOT NULL,
    is_leaf BOOLEAN NOT NULL DEFAULT FALSE,
    leaf_data_hash VARCHAR(64),
    leaf_run_id VARCHAR(64),
    left_child_hash VARCHAR(64),
    right_child_hash VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_merkle_node_pos UNIQUE (tree_id, level, position)
);

CREATE INDEX IF NOT EXISTS idx_merkle_tree_client ON intelligence.merkle_tree_ledger(client_id);
CREATE INDEX IF NOT EXISTS idx_merkle_tree_root ON intelligence.merkle_tree_ledger(root_hash);
CREATE INDEX IF NOT EXISTS idx_merkle_node_tree_pos ON intelligence.merkle_tree_node(tree_id, level, position);
CREATE INDEX IF NOT EXISTS idx_merkle_node_leaf_run ON intelligence.merkle_tree_node(leaf_run_id);
