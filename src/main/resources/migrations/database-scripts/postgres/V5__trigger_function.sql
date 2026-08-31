-- Function to notify WebSocket clients on INSERT in supplementary_upload table
-- pg_notify requires VOLATILE because it causes side effects and must not be optimized by the planner.
CREATE OR REPLACE FUNCTION data.notify_insert_supplementary_upload()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    transformed_row JSON;
BEGIN
    -- Fetch and transform the inserted row using business logic
    SELECT json_build_object(
            'id', id,
            'wfId', workflow_id,
            'fileName', file_name,
            'filePath', file_path,
            'nodeId', node_id,
            'source', source,
            'status', status,
            'errorFileName', error_file_name,
            'errorFilePath', error_file_path,
            'comments', comments,
            'uploadedBy', uploaded_by,
            'uploadedOn', TO_CHAR(uploaded_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedBy', updated_by,
            'updatedOn', TO_CHAR(updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),          'updatedFileName',updated_file_name,
            'validationStatus',validation_status,
            'period', period,
            'restatementVersion', restatement_version
        )
    INTO transformed_row
    FROM data.su_upload_control
    WHERE id = NEW.id; -- Use the ID of the inserted row

    -- Build the notification payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'INSERT',
        'row_data', transformed_row
    );

    -- Send the notification
    PERFORM pg_notify('supplementary_upload_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Function to notify WebSocket clients on UPDATE in supplementary_upload table
CREATE OR REPLACE FUNCTION data.notify_update_supplementary_upload()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    transformed_row JSON;
BEGIN
    -- Fetch and transform the updated row using business logic
    SELECT json_build_object(
            'id', id,
            'wfId', workflow_id,
            'fileName', file_name,
            'filePath', file_path,
            'nodeId', node_id,
            'source', source,
            'status', status,
            'errorFileName', error_file_name,
            'errorFilePath', error_file_path,
            'comments', comments,
            'uploadedBy', uploaded_by,
            'uploadedOn', TO_CHAR(uploaded_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedBy', updated_by,
            'updatedOn', TO_CHAR(updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedFileName', updated_file_name,
            'validationStatus', validation_status,
            'period', period,
            'restatementVersion', restatement_version
        )
    INTO transformed_row
    FROM data.su_upload_control
    WHERE id = NEW.id; -- Use the ID to locate the updated row

    -- Build the notification payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'UPDATE',
        'row_data', transformed_row
    );

    -- Send the notification
    PERFORM pg_notify('supplementary_upload_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


DROP TRIGGER IF EXISTS trg_supplementary_upload_update ON data.su_upload_control;
-- Trigger for UPDATE
CREATE TRIGGER trg_supplementary_upload_update
AFTER UPDATE ON data.su_upload_control
FOR EACH ROW EXECUTE FUNCTION data.notify_update_supplementary_upload();

DROP TRIGGER IF EXISTS trg_supplementary_upload_insert ON data.su_upload_control;
-- Trigger for INSERT (always fires)
CREATE TRIGGER trg_supplementary_upload_insert
AFTER INSERT ON data.su_upload_control
FOR EACH ROW EXECUTE FUNCTION data.notify_insert_supplementary_upload();

-- Trigger function for adhoc_rpt_run_control
CREATE OR REPLACE FUNCTION data.notify_adhoc_rpt_run_control()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
BEGIN
    -- Build JSON payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', TG_OP,  -- INSERT or UPDATE
        'row_data', json_build_object(
            'clientId', NEW.client_id,
            'execId', NEW.exec_id,
            'tableName', NEW.table_name,
            'columnCount', NEW.column_count,
            'query', NEW.query,
            'recordCount', NEW.record_count,
            'timeTaken', NEW.time_taken,
            'status', NEW.status,
            'errorMsg', NEW.error_msg,
            'createdAt', TO_CHAR(NEW.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedAt', TO_CHAR(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'createdBy', NEW.created_by,
            'updatedBy', NEW.updated_by
        )
    );

    -- Send notification on a dedicated channel
    PERFORM pg_notify('adhoc_rpt_run_control_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Drop existing triggers if any
DROP TRIGGER IF EXISTS trg_adhoc_rpt_run_control ON data.adhoc_rpt_run_control;

-- Create trigger for INSERT or UPDATE
CREATE TRIGGER trg_adhoc_rpt_run_control
AFTER INSERT OR UPDATE ON data.adhoc_rpt_run_control
FOR EACH ROW
EXECUTE FUNCTION data.notify_adhoc_rpt_run_control();


-- TopSide Adjustment - Unified trigger function for INSERT and UPDATE
CREATE OR REPLACE FUNCTION data.notify_topside_adjustments()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
    adj RECORD;
    impacted RECORD;
    adjustment_id BIGINT;
BEGIN
    -- Determine the adjustment_id based on the table
    IF TG_TABLE_NAME = 'rpt_topside_adjustments' THEN
        adjustment_id := NEW.id;
    ELSE
        adjustment_id := NEW.tsa_id;
    END IF;

    -- Fetch topside adjustment row
    SELECT *
    INTO adj
    FROM data.rpt_topside_adjustments
    WHERE id = adjustment_id
    LIMIT 1;

    -- Conditional : only continue if edit_check_break_exec_id is valid
    IF adj.edit_check_break_exec_id IS NULL OR adj.edit_check_break_exec_id = 0 THEN
        RETURN NEW; -- Exit without sending notification
    END IF;

    -- Fetch impacted elements row if exists
    SELECT *
    INTO impacted
    FROM data.tsa_impacted_elements
    WHERE adjustment_id = adjustment_id
    LIMIT 1;

    -- Build JSON payload
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', TG_OP,  -- INSERT or UPDATE
        'row_data', json_build_object(
            'id', adj.id,
            'adjustmentId', adj.id,
            'clientId', adj.client_id,
            'nodeId', adj.node_id,
            'taxonomyId', adj.taxonomy_id,
            'period', TO_CHAR(adj.period, 'YYYY-MM-DD'),
            'restatementVersion', adj.restatement_version,
            'tsaValNum', adj.tsa_val_num,
            'tsaValStr', adj.tsa_val_str,
            'status', adj.status,
            'description', adj.description,
            'reason', adj.reason,
            'comments', adj.comments,
            'workflowId', adj.workflow_id,
            'createdBy', adj.created_by,
            'updatedBy', adj.updated_by,
            'createdAt', TO_CHAR(adj.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedAt', TO_CHAR(adj.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'impacted_lines', COALESCE(impacted.impacted_lines, '{}'::JSONB),
            'edit_check_break', COALESCE(impacted.edit_check_break, '{}'::JSONB),
            'editCheckBreakId', adj.edit_check_break_exec_id
        )
    );

    -- Send the notification
    PERFORM pg_notify('topside_adjustments_channel', payload::text);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Triggers for rpt_topside_adjustments
DROP TRIGGER IF EXISTS trg_topside_adjustments_insert ON data.rpt_topside_adjustments;
DROP TRIGGER IF EXISTS trg_topside_adjustments_update ON data.rpt_topside_adjustments;
DROP TRIGGER IF EXISTS trg_topside_adjustments ON  data.rpt_topside_adjustments;

CREATE TRIGGER trg_topside_adjustments
AFTER INSERT OR UPDATE ON data.rpt_topside_adjustments
FOR EACH ROW
EXECUTE FUNCTION data.notify_topside_adjustments();

-- Triggers for tsa_impacted_elements
DROP TRIGGER IF EXISTS trg_tsa_impacted_elements_insert ON data.tsa_impacted_elements;
DROP TRIGGER IF EXISTS trg_tsa_impacted_elements_update ON data.tsa_impacted_elements;
DROP TRIGGER IF EXISTS trg_tsa_impacted_elements ON data.tsa_impacted_elements;

-- Function to notify WebSocket clients on INSERT in rule_detail table
CREATE OR REPLACE FUNCTION meta.notify_insert_rule_details()
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
            'ruleJson', '',
            'workflowId', d.workflow_id,
            'createdOn', TO_CHAR(d.created_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'createdBy', d.created_by,
            'updatedOn', TO_CHAR(d.updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedBy', d.updated_by,
            'comments', d.comments,
            'nodeName',d.rule_name,  -- Assuming rule_name represents node_name here
            'nodeId', (m.node_id || '' || LPAD(m.rule_id::text, 6, '0'))::integer,  -- Use node_id from rule_master table
            'period', p.period,
            'restatement_version', p.restatement_version,
            'debugEnabled', d.debug_enabled,
			'ruleTypeId', rt.rule_type_id,
			'ruleTypeName', rt.rule_type_name
        )
    INTO transformed_row
    FROM meta.rule_master m
    JOIN meta.rule_detail d ON m.rule_id = d.rule_id  -- Assuming rule_id is the correct key
    LEFT JOIN meta.rule_period_mapping  p ON d.rule_id = p.rule_id AND d.version = p.version
	LEFT JOIN meta.rule_attribute ra on ra.rule_id = d.rule_id
	LEFT JOIN meta.rule_type rt on ra.rule_type_id = rt.rule_type_id  -- ruleType id and ruleType name
    WHERE d.rule_id = NEW.rule_id and d.version = NEW.version;  -- Use the rule_id and version of the inserted row

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
CREATE OR REPLACE FUNCTION meta.notify_update_rule_details()
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
            'ruleJson', '',
            'workflowId', d.workflow_id,
            'createdOn', TO_CHAR(d.created_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'createdBy', d.created_by,
            'updatedOn', TO_CHAR(d.updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedBy', d.updated_by,
            'comments', d.comments,
            'nodeName',d.rule_name,  -- Assuming rule_name represents node_name here
            'nodeId', (m.node_id || '' || LPAD(m.rule_id::text, 6, '0'))::integer,   -- Use node_id from rule_master table
            'period', p.period,
            'restatement_version', p.restatement_version,
            'debugEnabled', d.debug_enabled,
			'ruleTypeId', rt.rule_type_id,
			'ruleTypeName', rt.rule_type_name
        )
    INTO transformed_row
    FROM meta.rule_master m
    JOIN meta.rule_detail d ON m.rule_id = d.rule_id  -- Assuming rule_id is the correct key
    LEFT JOIN meta.rule_period_mapping  p ON d.rule_id = p.rule_id AND d.version = p.version
    LEFT JOIN meta.rule_attribute ra on ra.rule_id = d.rule_id
    LEFT JOIN meta.rule_type rt on ra.rule_type_id = rt.rule_type_id  -- ruleType id and ruleType name
    WHERE d.rule_id = NEW.rule_id and d.version = NEW.version;  -- Use the rule_id and version to locate the updated row

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
DROP TRIGGER IF EXISTS trg_rule_detail_insert ON meta.rule_detail;
CREATE TRIGGER trg_rule_detail_insert
AFTER INSERT ON meta.rule_detail
FOR EACH ROW EXECUTE FUNCTION meta.notify_insert_rule_details();

-- Drop and create trigger for UPDATE on rule_detail
DROP TRIGGER IF EXISTS trg_rule_detail_update ON meta.rule_detail;
CREATE TRIGGER trg_rule_detail_update
AFTER UPDATE ON meta.rule_detail
FOR EACH ROW EXECUTE FUNCTION meta.notify_update_rule_details();


-- Drop and create trigger for INSERT on rule_period_mapping
DROP TRIGGER IF EXISTS trg_rule_period_mapping_insert ON meta.rule_period_mapping ;
CREATE TRIGGER trg_rule_period_mapping_insert
AFTER INSERT ON meta.rule_period_mapping
FOR EACH ROW EXECUTE FUNCTION meta.notify_insert_rule_details();

-- Drop and create trigger for UPDATE on rule_period_mapping
DROP TRIGGER IF EXISTS trg_rule_period_mapping_update ON meta.rule_period_mapping ;
CREATE TRIGGER trg_rule_period_mapping_update
AFTER UPDATE ON meta.rule_period_mapping
FOR EACH ROW EXECUTE FUNCTION meta.notify_update_rule_details();

-- Drop existing trigger if any, then create trigger on the schema-qualified table
DROP TRIGGER IF EXISTS trg_async_request_tracker_updated_at ON data.async_request_tracker;

CREATE TRIGGER trg_async_request_tracker_updated_at
BEFORE UPDATE ON data.async_request_tracker
FOR EACH ROW
EXECUTE FUNCTION data.trg_update_timestamp();

-- ============================================================
-- START | Report Generation and Recon | 25th March
-- ============================================================

-- Notification triggers for report generation and recon report tables.

-- Builds the child file array used by report_store notifications so websocket
-- payloads match the GET_GENERATED_REPORTS_V2 response shape.
CREATE OR REPLACE FUNCTION data.get_report_store_files_payload(p_report_store_control_id BIGINT)
RETURNS JSON AS $$
BEGIN
RETURN COALESCE(
        (
            SELECT json_agg(
                           json_build_object(
                                   'id', child.id,
                                   'fileType', child.file_type,
                                   'fileName', child.report_generated_name,
                                   'status', child.status,
                                   'reason', child.reason,
                                   'createdBy', child.created_by,
                                   'updatedBy', child.updated_by,
                                   'createdOn', TO_CHAR(child.created_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                                   'updatedOn', TO_CHAR(child.updated_on  AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                           )
                               ORDER BY child.created_on ASC
                   )
            FROM data.report_store_control_child child
            WHERE child.report_store_control_id = p_report_store_control_id
        ),
        '[]'::json
       );
END;
$$ LANGUAGE plpgsql;

-- Builds the child file array used by recon report notifications so websocket
-- payloads match the generated recon reports API response shape.
CREATE OR REPLACE FUNCTION data.get_recon_report_files_payload(p_recon_report_id BIGINT)
RETURNS JSON AS $$
BEGIN
RETURN COALESCE(
        (
            SELECT json_agg(
                           json_build_object(
                                   'id', child.id,
                                   'reportStoreControlChildId', child.report_store_control_child_id,
                                   'fileType', child.file_type,
                                   'status', child.status,
                                   'reason', child.reason,
                                   'createdBy', child.created_by,
                                   'updatedBy', child.updated_by,
                                   'createdAt', TO_CHAR(child.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                                   'updatedAt', TO_CHAR(child.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                           )
                               ORDER BY child.created_at ASC
                   )
            FROM data.rpt_recon_control_child child
            WHERE child.recon_report_id = p_recon_report_id
        ),
        '[]'::json
       );
END;
$$ LANGUAGE plpgsql;

-- Emits websocket-friendly payloads for inserts into data.report_store_control.
-- The row_data object mirrors the parent fields returned by GET_GENERATED_REPORTS_V2
-- and includes the aggregated child file metadata under "files".
CREATE OR REPLACE FUNCTION data.notify_insert_report_store()
RETURNS TRIGGER AS $$
DECLARE
payload JSON;
BEGIN
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'INSERT',
        'row_data', json_build_object(
            'id', NEW.id,
            'formGroup', NEW.form_group,
            'formName', NEW.form_name,
            'scheduleName', NEW.schedule_name,
            'subScheduleName', NEW.sub_schedule_name,
            'reportVersion', NEW.report_version,
            'status', NEW.status,
            'period', NEW.period,
            'restatementVersion', NEW.restatement_version,
            'requestedFileTypes', NEW.requested_file_types,
            'createdBy', NEW.created_by,
            'updatedBy', NEW.updated_by,
            'workflowStatus', NEW.workflow_status,
            'workflowId', NEW.workflow_id,
            'comments', NEW.comments,
            'createdOn', TO_CHAR(NEW.created_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedOn', TO_CHAR(NEW.updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'files', data.get_report_store_files_payload(NEW.id)
        )
    );

    PERFORM pg_notify('report_generation_channel', payload::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_report_store_insert ON data.report_store_control;

CREATE TRIGGER trg_report_store_insert
    AFTER INSERT ON data.report_store_control
    FOR EACH ROW
    EXECUTE FUNCTION data.notify_insert_report_store();

-- Emits websocket-friendly payloads for updates to data.report_store_control.
-- The payload shape stays aligned with GET_GENERATED_REPORTS_V2 so listeners
-- receive the same parent and child structure as the REST API.
CREATE OR REPLACE FUNCTION data.notify_update_report_store()
RETURNS TRIGGER AS $$
DECLARE
payload JSON;
BEGIN
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'UPDATE',
        'row_data', json_build_object(
            'id', NEW.id,
            'formGroup', NEW.form_group,
            'formName', NEW.form_name,
            'scheduleName', NEW.schedule_name,
            'subScheduleName', NEW.sub_schedule_name,
            'reportVersion', NEW.report_version,
            'status', NEW.status,
            'period', NEW.period,
            'restatementVersion', NEW.restatement_version,
            'requestedFileTypes', NEW.requested_file_types,
            'createdBy', NEW.created_by,
            'updatedBy', NEW.updated_by,
            'workflowStatus', NEW.workflow_status,
            'workflowId', NEW.workflow_id,
            'comments', NEW.comments,
            'createdOn', TO_CHAR(NEW.created_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedOn', TO_CHAR(NEW.updated_on AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'files', data.get_report_store_files_payload(NEW.id)
        )
    );

    PERFORM pg_notify('report_generation_channel', payload::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_report_store_update ON data.report_store_control;

CREATE TRIGGER trg_report_store_update
    AFTER UPDATE ON data.report_store_control
    FOR EACH ROW
    EXECUTE FUNCTION data.notify_update_report_store();

-- Emits recon report notification payloads after control row inserts.
CREATE OR REPLACE FUNCTION data.notify_insert_rpt_recon_control()
RETURNS TRIGGER AS $$
DECLARE
payload JSON;
BEGIN
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'INSERT',
        'row_data', json_build_object(
            'id', NEW.id,
            'clientId', NEW.client_id,
            'reportId', NEW.report_id,
            'formName', NEW.form_name,
            'period', NEW.period,
            'status', NEW.status,
            'reason', NEW.reason,
            'createdBy', NEW.created_by,
            'updatedBy', NEW.updated_by,
            'files', data.get_recon_report_files_payload(NEW.id),
            'createdAt', TO_CHAR(NEW.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedAt', TO_CHAR(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
        )
    );

    PERFORM pg_notify('report_generation_channel', payload::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_rpt_recon_control_insert ON data.rpt_recon_control;

CREATE TRIGGER trg_rpt_recon_control_insert
    AFTER INSERT ON data.rpt_recon_control
    FOR EACH ROW
    EXECUTE FUNCTION data.notify_insert_rpt_recon_control();

-- Emits recon report notification payloads after control row updates.
CREATE OR REPLACE FUNCTION data.notify_update_rpt_recon_control()
RETURNS TRIGGER AS $$
DECLARE
payload JSON;
BEGIN
    payload := json_build_object(
        'table_name', TG_TABLE_NAME,
        'action', 'UPDATE',
        'row_data', json_build_object(
            'id', NEW.id,
            'clientId', NEW.client_id,
            'reportId', NEW.report_id,
            'formName', NEW.form_name,
            'period', NEW.period,
            'status', NEW.status,
            'reason', NEW.reason,
            'createdBy', NEW.created_by,
            'updatedBy', NEW.updated_by,
            'files', data.get_recon_report_files_payload(NEW.id),
            'createdAt', TO_CHAR(NEW.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'updatedAt', TO_CHAR(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
        )
    );

    PERFORM pg_notify('report_generation_channel', payload::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_rpt_recon_control_update ON data.rpt_recon_control;

CREATE TRIGGER trg_rpt_recon_control_update
    AFTER UPDATE ON data.rpt_recon_control
    FOR EACH ROW
    EXECUTE FUNCTION data.notify_update_rpt_recon_control();

-- ============================================================
-- END | Report Generation and Recon | 25th March
-- ============================================================