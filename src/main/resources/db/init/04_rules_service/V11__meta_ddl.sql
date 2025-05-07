DROP TABLE IF EXISTS meta.rule_component;

CREATE TABLE meta.rule_component (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(255) NOT NULL,
    properties   JSONB,
    created_on   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   VARCHAR(100) NOT NULL
);