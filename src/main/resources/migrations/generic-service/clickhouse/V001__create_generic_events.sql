CREATE TABLE IF NOT EXISTS generic_events
(
    id UInt64,
    entity_id UInt64,
    event_type String,
    created_at DateTime
)
ENGINE = MergeTree
ORDER BY (entity_id, created_at);
