-- Object Inventory grid: add the header-less Audit column after Action (matches the history
-- button column in Lextr_SemanticLayer_UI_Aligned_stable_v5.jsx). Reuses the shared "audit"
-- cell renderer keyed on workflowId, same as the other semantic grids.
-- Rerunnable: only appends when the grid does not already have a workflowId column.
UPDATE meta.ui_elements_config
SET config_json = jsonb_set(
        config_json,
        '{gridConfig,columns}',
        (config_json -> 'gridConfig' -> 'columns')
            || '[{"field": "workflowId", "headerName": "", "width": 70, "cellRenderer": "audit", "sortable": false, "filter": false}]'::jsonb
    ),
    updated_at = NOW(),
    updated_by = 'system'
WHERE client_id = 1
  AND module_name = 'SEMANTIC'
  AND node_code = 'GLOBAL'
  AND group_key = 'SEMANTIC_REGISTER_INVENTORY_GRID'
  AND NOT EXISTS (
        SELECT 1
        FROM jsonb_array_elements(config_json -> 'gridConfig' -> 'columns') AS col
        WHERE col ->> 'field' = 'workflowId'
    );
