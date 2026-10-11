-- CLICKHOUSE LEDGER SUMMARY TABLE
DROP TABLE IF EXISTS data.ledger_summary;
CREATE TABLE data.ledger_summary
(
    client_id           Int32 DEFAULT 1,
    exec_id             Int32,
    ledger_id           String,
    outstanding_balance Float64,
    interest_income_ytd Float64,
    charge_off_amount   Float64,
    created_at          DateTime64(3, 'UTC'),
    updated_at          DateTime64(3, 'UTC'),
    period              Date,
    restatement_version Int32 DEFAULT 0,
    prov_id             String,
    src_rec_seq         String DEFAULT '',

    INDEX idx_src_rec_seq (src_rec_seq) TYPE bloom_filter GRANULARITY 4
)
    ENGINE = MergeTree
  PARTITION BY toYYYYMM(period)
  ORDER BY (client_id, exec_id, ledger_id, period, restatement_version)
  PRIMARY KEY (client_id, exec_id, ledger_id)
  SETTINGS index_granularity = 8192;
