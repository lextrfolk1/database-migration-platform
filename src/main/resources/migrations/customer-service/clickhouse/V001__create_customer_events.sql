CREATE TABLE IF NOT EXISTS customer_events
(
    id UInt64,
    customer_id UInt64,
    event_type String,
    created_at DateTime
)
ENGINE = MergeTree
ORDER BY (customer_id, created_at);
