

-- Insert ROOT node
INSERT INTO data.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    ('1', 'ROOT', 'ROOT', '2024-06-30', 'A', NULL,
    '{"period": "20240630", "isRuleWritingAllowed": false, "category": "root", "region": "global"}');

-- Insert REPORTS node
INSERT INTO data.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    ('2', 'REPORTS', 'REPORTS', '2024-06-30', 'A', '1',
    '{"period": "20240630", "isRuleWritingAllowed": false, "category": "reporting", "region": "global","hierarchyType": "SU"}');

-- Insert FRY9C node under REPORTS
INSERT INTO data.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    ('3', 'FRY9C', 'FRY9C', '2024-06-30', 'A', '2',
    '{"period": "20240630", "isRuleWritingAllowed": false, "category": "report", "region": "global"}');

-- Insert PRODUCTS node under ROOT
INSERT INTO data.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    ('4', 'PRODUCTS', 'PRODUCTS', '2024-06-30', 'A', '1',
    '{"period": "20240630", "isRuleWritingAllowed": false, "category": "products", "region": "nam","hierarchyType": "RULES"}');

-- Insert PRODUCTS Deposits node under PRODUCTS (with rule writing allowed)
INSERT INTO data.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    ('5', 'Deposits', 'DEPOSITS', '2024-06-30', 'A', '4',
    '{"period": "20240630", "isRuleWritingAllowed": true, "category": "products", "region": "global"}');
