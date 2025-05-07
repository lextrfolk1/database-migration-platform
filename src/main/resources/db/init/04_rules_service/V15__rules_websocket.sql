-- Function to notify WebSocket clients on INSERT in rule_detail table
CREATE OR REPLACE FUNCTION data.notify_insert_rule_details()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    transformed_row JSON;
BEGIN
    -- Fetch and transform the inserted row, joining with rule_master to get node_id
    SELECT json_build_object(
            'ruleId', m.rule_id,  -- Use rule_id from rule_master
            'parentNodeId', m.node_id,  -- Fetch node_id from rule_master
            'ruleName', d.rule_name,  -- Use rule_name from rule_detail
            'version', d.version,
            'status', d.status,
            'ruleJson', d.rule_json::text,
            'workflowId', d.workflow_id,
            'createdOn', TO_CHAR(d.created_on::timestamp, 'YYYY-MM-DD HH24:MI:SS'),
            'createdBy', d.created_by,
            'updatedOn', TO_CHAR(d.updated_on::timestamp, 'YYYY-MM-DD HH24:MI:SS'),
            'updatedBy', d.updated_by,
            'comments', d.comments,
            'nodeName',d.rule_name,  -- Assuming rule_name represents node_name here
            'nodeId', (m.node_id || '' || LPAD(m.rule_id::text, 6, '0'))::integer  -- Use node_id from rule_master table
        )
    INTO transformed_row
    FROM data.rule_master m
    JOIN data.rule_detail d ON m.rule_id = d.rule_id  -- Assuming rule_id is the correct key
    WHERE d.rule_id = NEW.rule_id;  -- Use the rule_id of the inserted row

    -- Build the notification payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'INSERT',
        'row_data', transformed_row
    );

    -- Send the notification
    PERFORM pg_notify('rule_detail_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Function to notify WebSocket clients on UPDATE in rule_detail table
CREATE OR REPLACE FUNCTION data.notify_update_rule_details()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    transformed_row JSON;
BEGIN
    -- Fetch and transform the updated row, joining with rule_master to get node_id
    SELECT json_build_object(
       'ruleId', m.rule_id,  -- Use rule_id from rule_master
            'parentNodeId', m.node_id,  -- Fetch node_id from rule_master
            'ruleName', d.rule_name,  -- Use rule_name from rule_detail
            'version', d.version,
            'status', d.status,
            'ruleJson', d.rule_json::text,
            'workflowId', d.workflow_id,
            'createdOn', TO_CHAR(d.created_on::timestamp, 'YYYY-MM-DD HH24:MI:SS'),
            'createdBy', d.created_by,
            'updatedOn', TO_CHAR(d.updated_on::timestamp, 'YYYY-MM-DD HH24:MI:SS'),
            'updatedBy', d.updated_by,
            'comments', d.comments,
            'nodeName',d.rule_name,  -- Assuming rule_name represents node_name here
            'nodeId', (m.node_id || '' || LPAD(m.rule_id::text, 6, '0'))::integer   -- Use node_id from rule_master table
        )
    INTO transformed_row
    FROM data.rule_master m
    JOIN data.rule_detail d ON m.rule_id = d.rule_id  -- Assuming rule_id is the correct key
    WHERE d.rule_id = NEW.rule_id;  -- Use the rule_id to locate the updated row

    -- Build the notification payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'UPDATE',
        'row_data', transformed_row
    );

    -- Send the notification
    PERFORM pg_notify('rule_detail_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Create trigger for rule_detail

-- Drop and create trigger for INSERT on rule_detail
DROP TRIGGER IF EXISTS trg_rule_detail_insert ON data.rule_detail;
CREATE TRIGGER trg_rule_detail_insert
AFTER INSERT ON data.rule_detail
FOR EACH ROW EXECUTE FUNCTION data.notify_insert_rule_details();

-- Drop and create trigger for UPDATE on rule_detail
DROP TRIGGER IF EXISTS trg_rule_detail_update ON data.rule_detail;
CREATE TRIGGER trg_rule_detail_update
AFTER UPDATE ON data.rule_detail
FOR EACH ROW EXECUTE FUNCTION data.notify_update_rule_details();
