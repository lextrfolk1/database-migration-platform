
-- Status metadata queries

-- Insert DRAFT status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('DRAFT', 'Draft', 'Initial editable state',
   '{"color": "#cccccc", "is_terminal": false, "tooltip": "Can be edited by user"}');

-- Insert PROCESSING status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('PROCESSING', 'Processing', 'Workflow is being processed',
   '{"color": "#ffcc00", "is_terminal": false, "tooltip": "Workflow is in progress"}');


-- Insert PENDING_APPROVAL status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('PENDING_APPROVAL', 'Pending Approval', 'Workflow is awaiting approval',
   '{"color": "#ff6600", "is_terminal": false, "tooltip": "Awaiting approval from the approver"}');

-- Insert APPROVED status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('APPROVED', 'Approved', 'Workflow has been approved',
   '{"color": "#33cc33", "is_terminal": true, "tooltip": "Workflow has been successfully approved"}');

-- Insert REJECTED status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('REJECTED', 'Rejected', 'Workflow has been rejected',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Workflow has been rejected"}');

-- Insert DISCARD status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('DISCARD', 'Discarded', 'Workflow has been discarded',
   '{"color": "#666666", "is_terminal": true, "tooltip": "Workflow has been discarded"}');

-- Insert SUCCESS status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('SUCCESS', 'Success', 'Successful',
   '{"color": "#33cc33", "is_terminal": true, "tooltip": "Successful"}');

-- Insert FAILED status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('FAILED', 'Failed', 'Failed',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Failed"}');

-- Insert WARNING status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('WARNING', 'Warning', 'Warnings',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Warnings"}');

-- Insert for stage_approval_workflow
INSERT INTO meta.workflow_metadata (workflow_name, workflow_json, created_by, status)
VALUES
(
  'single_stage_approval_workflow',
  '{
     "endStates": [
       "APPROVED",
       "REJECTED"
	 ],
     "transitions": {
       "PENDING_APPROVAL": {
         "actions": {
           "reject": "REJECTED",
           "approve": "APPROVED"
         }
       }
     },
     "initialStage": "PENDING_APPROVAL"
   }'::jsonb,
  current_user,
  'active'
);

INSERT INTO meta.workflow_metadata (workflow_name, workflow_json, created_by, status)
VALUES
(
  'two_stage_approval_workflow',
  '{
     "endStates": [
       "APPROVED",
       "REJECTED",
       "DISCARD"
     ],
     "transitions": {
       "DRAFT": {
         "actions": {
           "discard": "DISCARD",
           "submit": "PENDING_APPROVAL"
         }
       },
       "PENDING_APPROVAL": {
         "actions": {
           "reject": "REJECTED",
           "approve": "APPROVED"
         }
       }
     },
     "initialStage": "DRAFT"
   }'::jsonb,
  current_user,
  'active'
);

-- Insert for iterative_two_stage_approval_workflow
INSERT INTO meta.workflow_metadata (workflow_name, workflow_json, created_by, status)
VALUES
(
  'iterative_two_stage_approval_workflow',
  '{
     "endStates": [
       "APPROVED",
       "REJECTED",
       "DISCARD"
     ],
     "transitions": {
       "DRAFT": {
         "actions": {
           "discard": "DISCARD",
           "submit": "PENDING_APPROVAL"
         }
       },
       "PENDING_APPROVAL": {
         "actions": {
           "reject": "REJECTED",
           "approve": "APPROVED",
           "sendback": "DRAFT",
           "recall": "DRAFT"
         }
       }
     },
     "initialStage": "DRAFT"
   }'::jsonb,
  current_user,
  'active'
);

-- Insert into workflow_master
INSERT INTO meta.workflow_master (id, workflow_code, workflow_name, workflow_description, created_on, created_by, updated_on, updated_by)
VALUES (
  1,
  'supp',
  'supp_workflow',
  'Workflow for supplemental upload',
  now(),
  'system',
  now(),
  'system'
);

INSERT INTO meta.workflow_master (id, workflow_code, workflow_name, workflow_description, created_on, created_by, updated_on, updated_by)
VALUES (
  3,
  'workbench',
  'single_stage_approval_workflow',
  'Workflow for AFT close with memo',
  now(),
  'system',
  now(),
  'system'
);

-- Insert into module_master
INSERT INTO meta.module_master (id, module_name)
VALUES (1, 'supplemental_upload');

INSERT INTO meta.module_master (id, module_name)
VALUES (3, 'workbench');

-- Insert into workflow_module_map
INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
VALUES (1, 1);

INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
VALUES (3, 3);

insert into meta.datasets_lookup(dataset_name, load_type, file_location) values('ds.deposit_ds', 'file', 'app/data/ai/sample_ds/DEPOSIT_DS_SAMPLE.csv');
insert into meta.datasets_lookup(dataset_name, load_type, file_location) values('ds.financial_ledger_ds', 'file', 'app/data/ai/sample_ds/FINANCIAL_LEDGER_DS_SAMPLE.csv');
insert into meta.datasets_lookup(dataset_name, load_type, file_location) values('ds.regulatory_ledger_ds', 'file', 'app/data/ai/sample_ds/REGULATORY_LEDGER_DS_SAMPLE.csv');


    INSERT INTO meta.rule_component (name, properties, created_by)
    VALUES (
        'aggregate',  -- component name
        '{
            "comp_typ": "aggregate",
            "inputs": [
                {
                    "input": "in",
                    "input_seq": "0",
                    "optional": "false"
                }
            ],
            "outputs": [
                {
                    "output": "out",
                    "output_seq": "0",
                    "optional": "false"
                }
            ],
            "properties": [
                {
                    "prop_name": "aggregate_key",
                    "prop_display_name": "Key",
                    "prop_datatype": "string",
                    "validate_syntax": "false"
                },
                {
                    "prop_name": "measures",
                    "prop_display_name": "Measure",
                    "prop_datatype": "nvp",
                    "validate_syntax": "false",
                    "nvp_maps": [
                        {
                            "name": "Column",
                            "datatype": "string",
                            "validate_syntax": "false"
                        },
                        {
                            "name": "Expression",
                            "datatype": "string",
                            "validate_syntax": "true"
                        }
                    ]
                }
            ]
        }'::jsonb,
        'system'  -- created_by
    );


    INSERT INTO meta.rule_component (name, properties, created_by)
    VALUES (
        'filter',
        '{
            "comp_typ": "filter",
            "inputs": [
                {
                    "input": "in",
                    "input_seq": "0",
                    "optional": "false"
                }
            ],
            "outputs": [
                {
                    "output": "out",
                    "output_seq": "0",
                    "optional": "false"
                },
                {
                    "output": "exclude",
                    "output_seq": "1",
                    "optional": "true"
                }
            ],
            "properties": [
                {
                    "prop_name": "filter_expression",
                    "prop_display_name": "Filter Expression",
                    "prop_datatype": "string",
                    "validate_syntax": "true"
                }
            ]
        }'::jsonb,
        'system'
    );


    INSERT INTO meta.rule_component (name, properties, created_by)
    VALUES (
        'join',
        '{
            "comp_typ": "join",
            "inputs": [
                {
                    "input": "in0",
                    "input_seq": "0",
                    "optional": "false"
                },
                {
                    "input": "in1",
                    "input_seq": "1",
                    "optional": "false"
                }
            ],
            "outputs": [
                {
                    "output": "out",
                    "output_seq": "0",
                    "optional": "false"
                }
            ],
            "properties": [
                {
                    "prop_name": "join_key",
                    "prop_display_name": "Key",
                    "prop_datatype": "string",
                    "validate_syntax": "false"
                },
                {
                    "prop_name": "enable_mappings",
                    "prop_display_name": "Enable Mapping",
                    "prop_datatype": "bool",
                    "validate_syntax": "false"
                },
                {
                    "prop_name": "mappings",
                    "prop_display_name": "Mappings",
                    "prop_datatype": "nvp",
                    "validate_syntax": "false",
                    "nvp_maps": [
                        {
                            "name": "Column",
                            "datatype": "string",
                            "validate_syntax": "false"
                        },
                        {
                            "name": "Mapping Logic",
                            "datatype": "string",
                            "validate_syntax": "true"
                        }
                    ]
                }
            ]
        }'::jsonb,
        'system'
    );


    -------------------------------------------------------------------------


    INSERT INTO meta.rule_component (name, properties, created_by)
    VALUES (
        'map',
        '{
            "comp_typ": "Map",
            "inputs": [
                {
                    "input": "in",
                    "input_seq": "0",
                    "optional": "false"
                }
            ],
            "outputs": [
                {
                    "output": "out",
                    "output_seq": "0",
                    "optional": "false"
                }
            ],
            "properties": [
                {
                    "prop_name": "mappings",
                    "prop_display_name": "Mappings",
                    "prop_datatype": "nvp",
                    "validate_syntax": "false",
                    "nvp_maps": [
                        {
                            "name": "Column",
                            "datatype": "string",
                            "validate_syntax": "false"
                        },
                        {
                            "name": "Mapping Logic",
                            "datatype": "string",
                            "validate_syntax": "true"
                        }
                    ]
                }
            ]
        }'::jsonb,
        'system'
    );


INSERT INTO meta.rule_type (rule_type_id, rule_type_name, created_on, created_by, updated_on, updated_by)
VALUES (1, 'R1', now(), 'system', now(), 'system');


-- Workflow Metadata

INSERT INTO meta.module_master (id, module_name) VALUES (2, 'rules_service');
INSERT INTO meta.workflow_master (id, workflow_code, workflow_name, workflow_description, created_on, created_by, updated_on, updated_by)
VALUES (2, 'rules', 'two_stage_approval_workflow', 'Workflow for Rules', now(), 'SYSTEM', now(), 'SYSTEM');

INSERT INTO meta.workflow_module_map (workflow_master_id, module_master_id)
VALUES (2, 2);

--Rule Type
UPDATE meta.rule_type SET rule_type_name = 'REPORT' WHERE rule_type_id=1;

INSERT INTO meta.rule_type(rule_type_id, rule_type_name, created_on, created_by, updated_on, updated_by)
	VALUES (2, 'DQ', now(), 'system', now(),'system');

INSERT INTO meta.rule_type(rule_type_id, rule_type_name, created_on, created_by, updated_on, updated_by)
	VALUES (3, 'EC', now(), 'system', now(),'system');


UPDATE meta.rule_type SET rule_type_name = 'Report' WHERE rule_type_id=1;

UPDATE meta.rule_type SET rule_type_name = 'Data Quality' WHERE rule_type_id=2;

UPDATE meta.rule_type SET rule_type_name = 'Edit Check' WHERE rule_type_id=3;


-- Root Node
INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (1, 'Root', 'root', '2024-06-30', 'A', NULL,
    '{"period": "20240630", "isRuleWritingAllowed": false, "region": "global"}');

-- Insert REPORTS node
INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (2, 'Reports', 'reports', '2024-06-30', 'A', 1,
    '{"period": "20240630", "isRuleWritingAllowed": false, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

-- Insert PRODUCTS node under ROOT
INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (3, 'Products', 'products', '2024-06-30', 'A', 1,
    '{"period": "20240630", "isRuleWritingAllowed": false, "region": "nam","applicable_hierarchies": ["SU","RULES"]}');

-- Insert FR Y-9C node under REPORTS
INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (4, 'FR Y-9C', 'fry9c', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (5, 'FR5300-Call Report', 'fr5300', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (6, 'FR Y-14A', 'fry14a', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (7, 'FR Y-14Q', 'fry14q', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (8, 'FR Y-14M', 'fry14m', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

-- Insert PRODUCTS Deposits node under PRODUCTS (with rule writing allowed)
INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (9, 'Deposits', 'deposits', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (10, 'Financial Ledger', 'financial_ledger', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (11, 'Regulatory Ledger', 'regulatory_ledger', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');


INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (12, 'Derivatives', 'derivatives', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (13, 'Securities', 'securities', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (14, 'Loans', 'loans', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": false, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (15, 'Mortgages', 'mortgages', '2024-06-30', 'A', 14,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (16, 'Credit Card', 'credit_card', '2024-06-30', 'A',14,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (17, 'Personal Loan', 'personal_loan', '2024-06-30', 'A', 14,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (18, 'Trade Product', 'trade_product', '2024-06-30', 'A', 14,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (19, 'Corp Loan', 'corp_loan', '2024-06-30', 'A', 14,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (20, 'General Ledger (GL)', 'general_ledger', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (21, 'Cash And Due', 'cash_and_due', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (22, 'Journal Transaction', 'journal_transaction', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (23, 'SFT', 'sft', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (24, 'Collateral', 'collateral', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (25, 'Credit Facility', 'credit_facility', '2024-06-30', 'A', 3,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (26, 'Series R01 Report A-0111', 'MEXICO', '2024-06-30', 'A', 2,
    '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (27, 'FR2900', 'FR2900', '2024-06-30', 'A', 2,
     '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (28, 'FRY9CSP', 'FRY9CSP', '2024-06-30', 'A', 2,
     '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

INSERT INTO meta.node_hierarchy (
    node_id, node_name, node_code, as_of_date, eff_status, parent_node_id, node_properties)
VALUES
    (29, 'FFIEC041', 'FFIEC041', '2024-06-30', 'A', 2,
     '{"period": "20240630", "isRuleWritingAllowed": true, "region": "global","applicable_hierarchies": ["SU","RULES"]}');

-- Report metadata
INSERT INTO meta.report_template_metadata(
	node_id,form_name, form_group, schedule_name, sub_schedule_name, file_name, file_path, uploaded_by, uploaded_on, updated_by, updated_on)
	VALUES (9,'NA', 'NA', 'NA', 'NA', 'Deposit_Template.csv', 'app/data/su/templates/', 'SYSTEM', now(), 'SYSTEM', now());

INSERT INTO meta.report_template_metadata(
	node_id,form_name, form_group, schedule_name, sub_schedule_name, file_name, file_path, uploaded_by, uploaded_on, updated_by, updated_on)
	VALUES (10,'NA', 'NA', 'NA', 'NA', 'Financial_Ledger_Template.csv', 'app/data/su/templates/', 'SYSTEM', now(), 'SYSTEM', now());

INSERT INTO meta.report_template_metadata(
	node_id,form_name, form_group, schedule_name, sub_schedule_name, file_name, file_path, uploaded_by, uploaded_on, updated_by, updated_on)
	VALUES (11,'NA', 'NA', 'NA', 'NA', 'Regulatory_Ledger_Template.csv', 'app/data/su/templates/', 'SYSTEM', now(), 'SYSTEM', now());

-- REPORT GENERATION
-- Insert sample data into report_store_metadata
delete from meta.report_store_metadata where id in (1,2,3);
INSERT INTO meta.report_store_metadata(
	client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
	VALUES (1, 1, 'US Regulatory Reporting', 'FRY9C', null, null, 'FRY9C', 'XML,XBRL,RCP,PDF', null);

INSERT INTO meta.report_store_metadata(
	client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
	VALUES (1, 2, 'US Regulatory Reporting', 'FR5300', null, null, 'FR5300', 'XML,XBRL,RCP,PDF', 'app/data/reportgeneration/xsd/5300_XML_Schema_nfiscu_Q2_2025_Submission.xsd');

INSERT INTO meta.report_store_metadata(
	client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
	VALUES (1, 3, 'Mexico Finance', 'R01A', null, null, 'R01A', 'XML,XBRL,RCP,PDF', null);

--Report Generation Updates
UPDATE meta.node_hierarchy
SET node_properties = '{
  "period": "20240630",
  "region": "global",
  "isRuleWritingAllowed": false,
  "applicable_hierarchies": ["SU", "RULES", "RG"]
}'::jsonb
WHERE node_id = 2;

UPDATE meta.node_hierarchy
SET node_properties = '{
  "period": "20240630",
  "region": "global",
  "isRuleWritingAllowed": true,
  "applicable_hierarchies": ["SU", "RULES", "RG"]
}'::jsonb
WHERE parent_node_id = 2;

UPDATE meta.node_hierarchy set node_code='FRY9C' where node_id=4;

UPDATE  meta.node_hierarchy set node_code='FR5300' where node_id=5;

insert into meta.datasets_lookup(client_id, id, dataset_name, load_type, file_location) values(1, 4, 'default_ds', 'file', 'app/data/ai/sample_ds/DEPOSIT_DS_SAMPLE.csv');

UPDATE meta.node_hierarchy set node_name='R01-A', node_code='R01A'  where node_id=26;

-- Ui Elements config for su upload --

-- AUTO-GENERATED UI ELEMENT SQL CONFIG

-- DELETE existing config for node deposits
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'deposits';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1000, 1, 'SU', 'deposits', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1001, 1, 'SU', 'deposits', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1002, 1, 'SU', 'deposits', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1003, 1, 'SU', 'deposits', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1004, 1, 'SU', 'deposits', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node financial_ledger
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'financial_ledger';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1005, 1, 'SU', 'financial_ledger', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1006, 1, 'SU', 'financial_ledger', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1007, 1, 'SU', 'financial_ledger', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1008, 1, 'SU', 'financial_ledger', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1009, 1, 'SU', 'financial_ledger', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node regulatory_ledger
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'regulatory_ledger';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1010, 1, 'SU', 'regulatory_ledger', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1011, 1, 'SU', 'regulatory_ledger', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1012, 1, 'SU', 'regulatory_ledger', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1013, 1, 'SU', 'regulatory_ledger', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1014, 1, 'SU', 'regulatory_ledger', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node derivatives
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'derivatives';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1015, 1, 'SU', 'derivatives', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1016, 1, 'SU', 'derivatives', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1017, 1, 'SU', 'derivatives', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1018, 1, 'SU', 'derivatives', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1019, 1, 'SU', 'derivatives', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node securities
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'securities';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1020, 1, 'SU', 'securities', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1021, 1, 'SU', 'securities', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1022, 1, 'SU', 'securities', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1023, 1, 'SU', 'securities', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1024, 1, 'SU', 'securities', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node mortgages
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'mortgages';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1025, 1, 'SU', 'mortgages', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1026, 1, 'SU', 'mortgages', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1027, 1, 'SU', 'mortgages', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1028, 1, 'SU', 'mortgages', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1029, 1, 'SU', 'mortgages', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node credit_card
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'credit_card';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1030, 1, 'SU', 'credit_card', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1031, 1, 'SU', 'credit_card', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1032, 1, 'SU', 'credit_card', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1033, 1, 'SU', 'credit_card', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1034, 1, 'SU', 'credit_card', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node personal_loan
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'personal_loan';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1035, 1, 'SU', 'personal_loan', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1036, 1, 'SU', 'personal_loan', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1037, 1, 'SU', 'personal_loan', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1038, 1, 'SU', 'personal_loan', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1039, 1, 'SU', 'personal_loan', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node trade_product
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'trade_product';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1040, 1, 'SU', 'trade_product', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1041, 1, 'SU', 'trade_product', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1042, 1, 'SU', 'trade_product', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1043, 1, 'SU', 'trade_product', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1044, 1, 'SU', 'trade_product', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node corp_loan
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'corp_loan';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1045, 1, 'SU', 'corp_loan', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1046, 1, 'SU', 'corp_loan', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1047, 1, 'SU', 'corp_loan', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1048, 1, 'SU', 'corp_loan', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1049, 1, 'SU', 'corp_loan', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node general_ledger
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'general_ledger';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1050, 1, 'SU', 'general_ledger', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1051, 1, 'SU', 'general_ledger', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1052, 1, 'SU', 'general_ledger', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1053, 1, 'SU', 'general_ledger', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1054, 1, 'SU', 'general_ledger', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node cash_and_due
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'cash_and_due';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1055, 1, 'SU', 'cash_and_due', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1056, 1, 'SU', 'cash_and_due', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1057, 1, 'SU', 'cash_and_due', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1058, 1, 'SU', 'cash_and_due', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1059, 1, 'SU', 'cash_and_due', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node journal_transaction
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'journal_transaction';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1060, 1, 'SU', 'journal_transaction', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1061, 1, 'SU', 'journal_transaction', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1062, 1, 'SU', 'journal_transaction', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1063, 1, 'SU', 'journal_transaction', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1064, 1, 'SU', 'journal_transaction', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node sft
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'sft';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1065, 1, 'SU', 'sft', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1066, 1, 'SU', 'sft', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1067, 1, 'SU', 'sft', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1068, 1, 'SU', 'sft', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1069, 1, 'SU', 'sft', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node collateral
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'collateral';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1070, 1, 'SU', 'collateral', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1071, 1, 'SU', 'collateral', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1072, 1, 'SU', 'collateral', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1073, 1, 'SU', 'collateral', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1074, 1, 'SU', 'collateral', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node credit_facility
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'credit_facility';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1075, 1, 'SU', 'credit_facility', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1076, 1, 'SU', 'credit_facility', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1077, 1, 'SU', 'credit_facility', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1078, 1, 'SU', 'credit_facility', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1079, 1, 'SU', 'credit_facility', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node fry14a
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'fry14a';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1080, 1, 'SU', 'fry14a', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1081, 1, 'SU', 'fry14a', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1082, 1, 'SU', 'fry14a', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1083, 1, 'SU', 'fry14a', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1084, 1, 'SU', 'fry14a', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node fry14q
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'fry14q';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1085, 1, 'SU', 'fry14q', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1086, 1, 'SU', 'fry14q', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1087, 1, 'SU', 'fry14q', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1088, 1, 'SU', 'fry14q', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1089, 1, 'SU', 'fry14q', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node fry14m
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'fry14m';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1090, 1, 'SU', 'fry14m', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1091, 1, 'SU', 'fry14m', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1092, 1, 'SU', 'fry14m', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1093, 1, 'SU', 'fry14m', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1094, 1, 'SU', 'fry14m', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node FRY9C
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'FRY9C';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1095, 1, 'SU', 'FRY9C', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1096, 1, 'SU', 'FRY9C', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1097, 1, 'SU', 'FRY9C', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1098, 1, 'SU', 'FRY9C', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1099, 1, 'SU', 'FRY9C', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node FR5300
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'FR5300';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1100, 1, 'SU', 'FR5300', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1101, 1, 'SU', 'FR5300', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1102, 1, 'SU', 'FR5300', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1103, 1, 'SU', 'FR5300', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1104, 1, 'SU', 'FR5300', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');

-- DELETE existing config for node R01A
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND group_key = 'UPLOAD_FORM' AND node_code = 'R01A';

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1105, 1, 'SU', 'R01A', 'UPLOAD_FORM',  null, 'reporting_period', 'reporting_period_key', 'DROPDOWN',  'INLINE', 1, TRUE,  '{"options": [{"value": "2025Q1", "label": "2025-Q1: Regular"}, {"value": "2025Q2", "label": "2025-Q2: Regular"}]}',  NULL, '{"placeholder": "reporting period"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1106, 1, 'SU', 'R01A', 'UPLOAD_FORM',  null, 'legal_entity', 'legal_entity_key', 'DROPDOWN',  'INLINE', 2, TRUE,  '{"options": [{"value": "MEXICO", "label": "Mexico"}]}',  NULL, '{"placeholder": "legal entity"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1107, 1, 'SU', 'R01A', 'UPLOAD_FORM',  null, 'schedule', 'schedule_key', 'DROPDOWN',  'INLINE', 3, TRUE,  '{"options": [{"value": "ACTIVE", "label": "Active"}, {"value": "PASSIVE", "label": "Passive"}]}',  NULL, '{"placeholder": "schedule type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1108, 1, 'SU', 'R01A', 'UPLOAD_FORM',  null, 'data_type', 'data_type_key', 'BOOLEAN',  'INLINE', 4, TRUE,  '{"options": [{"value": "ACTUAL", "label": "Actual"}, {"value": "PROJECTION", "label": "Projection"}]}',  NULL, '{"placeholder": "data type"}', TRUE,  now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by ) VALUES
(1109, 1, 'SU', 'R01A', 'UPLOAD_FORM',  null, 'load_mode', 'load_mode_key', 'RADIO',  'INLINE', 5, TRUE,  '{"options": [{"value": "FULL", "label": "Full Replacement"}, {"value": "INCREMENTAL", "label": "Incremental"}]}',  NULL, '{"orientation": "horizontal"}', TRUE,  now(), 'admin', now(), 'admin');


--DELETE existing config for node R01A grids
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'WORKBENCH' AND node_code in ('R01A','FRY9C','FR2900','FFIEC041', 'FR5300');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1110, 1, 'WORKBENCH', 'R01A', 'TSA_TABLE_GRID', NULL, 'table', 'tsa_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"top_side_adjustments","title":"Top Side Adjustments","rowIdKey":"adjustmentId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"adjustmentId","headerName":"Adj ID","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"recurranceCount","headerName":"Adj Occurrence","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agNumberColumnFilter"},{"field":"preAdjustmentValue","headerName":"Pre Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentAdjustmentValue","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"postAdjustmentValue","headerName":"Post Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"totalAdjustmentValue","headerName":"Total Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"originalValue","headerName":"Original Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","width":235,"suppressSizeToFit":true,"displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"view_impacts","headerName":"Impacts","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_IMPACT","tooltip":"View Impact Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Recurring","Once"]}},{"field":"tsaCode","headerName":"Adjustment Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Plan","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1111, 1, 'WORKBENCH', 'R01A', 'REPORT_OUTLINE_TABLE_GRID', NULL, 'table', 'report_outline_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_outline","title":"Report Outline","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1112, 1, 'WORKBENCH', 'R01A', 'EDITCHECK_TABLE_GRID', NULL, 'table', 'editcheck_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck","title":"Editcheck","rowIdKey":"aftId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ecType","headerName":"Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckName","headerName":"Editcheck Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Current State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":180,"suppressSizeToFit":true,"sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"workflowStatus","headerName":"Action","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":240,"suppressSizeToFit":true,"sortable":true,"filter":"agTextColumnFilter"},{"field":"view_details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"priority","headerName":"Priority","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["HIGH","MEDIUM","LOW"]}},{"field":"isHard","headerName":"Criticality","dataType":"STRING","cellDataType":"text","formatter":"EDITCHECK_CRITICALITY","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Hard Check","Soft Check"]}},{"field":"ecSource","headerName":"Source","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"recourrenceCount","headerName":"Recurrence Count","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1113, 1, 'WORKBENCH', 'R01A', 'CONFIGURATION_TABLE_GRID', NULL, 'table', 'configuration_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"configuration","title":"Configuration","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1161, 1, 'WORKBENCH', 'R01A', 'COMPLETENESS_SCORE_TABLE_GRID', NULL, 'table', 'completeness_score_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"completeness_score","title":"Completeness Score","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"completenessScore","headerName":"Completeness","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1114, 1, 'WORKBENCH', 'R01A', 'VARIANCE_TABLE_GRID', NULL, 'table', 'variance_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"change","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"trends","headerName":"Trends","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"narrative","headerName":"Narrative","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1115, 1, 'WORKBENCH', 'R01A', 'TSA_DETAILS_GRID', NULL, 'table', 'tsa_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"tsa_details","title":"TSA Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentAmount","headerName":"Adjustment Amount","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"tsaType","headerName":"TSA Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaCode","headerName":"TSA Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Date","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1116, 1, 'WORKBENCH', 'R01A', 'CONFIG_DETAILS_GRID', NULL, 'table', 'config_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"config_details","title":"Configuration Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updated_by","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updateAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"commentsReportable","headerName":"Reportable Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"commentsConfidential","headerName":"Confidential Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1117, 1, 'WORKBENCH', 'R01A', 'EDITCHECK_AUDIT_GRID', NULL, 'table', 'editcheck_audit_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_audit","title":"Editcheck Audit","rowIdKey":"aftId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Editcheck Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"actionStatus","headerName":"State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["OPEN","ON HOLD","CLOSED WITH MEMO","CLOSED","RE OPEN"]}},{"field":"workflowStatus","headerName":"Workflow Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1118, 1, 'WORKBENCH', 'FRY9C', 'TSA_TABLE_GRID', NULL, 'table', 'tsa_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"top_side_adjustments","title":"Top Side Adjustments","rowIdKey":"adjustmentId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"adjustmentId","headerName":"Adj ID","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"recurranceCount","headerName":"Adj Occurrence","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agNumberColumnFilter"},{"field":"preAdjustmentValue","headerName":"Pre Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentAdjustmentValue","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"postAdjustmentValue","headerName":"Post Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"totalAdjustmentValue","headerName":"Total Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"originalValue","headerName":"Original Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","width":235,"suppressSizeToFit":true,"displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"view_impacts","headerName":"Impacts","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_IMPACT","tooltip":"View Impact Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Recurring","Once"]}},{"field":"tsaCode","headerName":"Adjustment Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Plan","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1119, 1, 'WORKBENCH', 'FRY9C', 'REPORT_OUTLINE_TABLE_GRID', NULL, 'table', 'report_outline_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_outline","title":"Report Outline","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1120, 1, 'WORKBENCH', 'FRY9C', 'EDITCHECK_TABLE_GRID', NULL, 'table', 'editcheck_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck","title":"Editcheck","rowIdKey":"aftId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ecType","headerName":"Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckName","headerName":"Editcheck Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Current State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":180,"suppressSizeToFit":true,"sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"workflowStatus","headerName":"Action","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":240,"suppressSizeToFit":true,"sortable":true,"filter":"agTextColumnFilter"},{"field":"view_details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"priority","headerName":"Priority","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["HIGH","MEDIUM","LOW"]}},{"field":"isHard","headerName":"Criticality","dataType":"STRING","cellDataType":"text","formatter":"EDITCHECK_CRITICALITY","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Hard Check","Soft Check"]}},{"field":"ecSource","headerName":"Source","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"recourrenceCount","headerName":"Recurrence Count","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1121, 1, 'WORKBENCH', 'FRY9C', 'CONFIGURATION_TABLE_GRID', NULL, 'table', 'configuration_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"configuration","title":"Configuration","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1162, 1, 'WORKBENCH', 'FRY9C', 'COMPLETENESS_SCORE_TABLE_GRID', NULL, 'table', 'completeness_score_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"completeness_score","title":"Completeness Score","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"completenessScore","headerName":"Completeness","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1122, 1, 'WORKBENCH', 'FRY9C', 'VARIANCE_TABLE_GRID', NULL, 'table', 'variance_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"change","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"trends","headerName":"Trends","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"narrative","headerName":"Narrative","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1123, 1, 'WORKBENCH', 'FRY9C', 'TSA_DETAILS_GRID', NULL, 'table', 'tsa_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"tsa_details","title":"TSA Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentAmount","headerName":"Adjustment Amount","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"tsaType","headerName":"TSA Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaCode","headerName":"TSA Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Date","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1124, 1, 'WORKBENCH', 'FRY9C', 'CONFIG_DETAILS_GRID', NULL, 'table', 'config_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"config_details","title":"Configuration Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updated_by","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updateAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"commentsReportable","headerName":"Reportable Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"commentsConfidential","headerName":"Confidential Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1125, 1, 'WORKBENCH', 'FRY9C', 'EDITCHECK_AUDIT_GRID', NULL, 'table', 'editcheck_audit_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_audit","title":"Editcheck Audit","rowIdKey":"aftId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Editcheck Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"actionStatus","headerName":"State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["OPEN","ON HOLD","CLOSED WITH MEMO","CLOSED","RE OPEN"]}},{"field":"workflowStatus","headerName":"Workflow Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1126, 1, 'WORKBENCH', 'FR2900', 'TSA_TABLE_GRID', NULL, 'table', 'tsa_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"top_side_adjustments","title":"Top Side Adjustments","rowIdKey":"adjustmentId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"adjustmentId","headerName":"Adj ID","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"recurranceCount","headerName":"Adj Occurrence","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agNumberColumnFilter"},{"field":"preAdjustmentValue","headerName":"Pre Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentAdjustmentValue","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"postAdjustmentValue","headerName":"Post Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"totalAdjustmentValue","headerName":"Total Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"originalValue","headerName":"Original Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","width":235,"suppressSizeToFit":true,"displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"view_impacts","headerName":"Impacts","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_IMPACT","tooltip":"View Impact Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Recurring","Once"]}},{"field":"tsaCode","headerName":"Adjustment Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Plan","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1127, 1, 'WORKBENCH', 'FR2900', 'REPORT_OUTLINE_TABLE_GRID', NULL, 'table', 'report_outline_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_outline","title":"Report Outline","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1128, 1, 'WORKBENCH', 'FR2900', 'EDITCHECK_TABLE_GRID', NULL, 'table', 'editcheck_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck","title":"Editcheck","rowIdKey":"aftId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ecType","headerName":"Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckName","headerName":"Editcheck Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Current State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":180,"suppressSizeToFit":true,"sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"workflowStatus","headerName":"Action","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":240,"suppressSizeToFit":true,"sortable":true,"filter":"agTextColumnFilter"},{"field":"view_details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"priority","headerName":"Priority","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["HIGH","MEDIUM","LOW"]}},{"field":"isHard","headerName":"Criticality","dataType":"STRING","cellDataType":"text","formatter":"EDITCHECK_CRITICALITY","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Hard Check","Soft Check"]}},{"field":"ecSource","headerName":"Source","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"recourrenceCount","headerName":"Recurrence Count","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1129, 1, 'WORKBENCH', 'FR2900', 'CONFIGURATION_TABLE_GRID', NULL, 'table', 'configuration_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"configuration","title":"Configuration","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1163, 1, 'WORKBENCH', 'FR2900', 'COMPLETENESS_SCORE_TABLE_GRID', NULL, 'table', 'completeness_score_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"completeness_score","title":"Completeness Score","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"completenessScore","headerName":"Completeness","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1130, 1, 'WORKBENCH', 'FR2900', 'VARIANCE_TABLE_GRID', NULL, 'table', 'variance_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"change","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"trends","headerName":"Trends","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"narrative","headerName":"Narrative","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1131, 1, 'WORKBENCH', 'FR2900', 'TSA_DETAILS_GRID', NULL, 'table', 'tsa_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"tsa_details","title":"TSA Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentAmount","headerName":"Adjustment Amount","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"tsaType","headerName":"TSA Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaCode","headerName":"TSA Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Date","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1132, 1, 'WORKBENCH', 'FR2900', 'CONFIG_DETAILS_GRID', NULL, 'table', 'config_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"config_details","title":"Configuration Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updated_by","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updateAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"commentsReportable","headerName":"Reportable Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"commentsConfidential","headerName":"Confidential Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1133, 1, 'WORKBENCH', 'FR2900', 'EDITCHECK_AUDIT_GRID', NULL, 'table', 'editcheck_audit_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_audit","title":"Editcheck Audit","rowIdKey":"aftId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Editcheck Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"actionStatus","headerName":"State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["OPEN","ON HOLD","CLOSED WITH MEMO","CLOSED","RE OPEN"]}},{"field":"workflowStatus","headerName":"Workflow Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1134, 1, 'WORKBENCH', 'FFIEC041', 'TSA_TABLE_GRID', NULL, 'table', 'tsa_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"top_side_adjustments","title":"Top Side Adjustments","rowIdKey":"adjustmentId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"adjustmentId","headerName":"Adj ID","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"recurranceCount","headerName":"Adj Occurrence","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agNumberColumnFilter"},{"field":"preAdjustmentValue","headerName":"Pre Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentAdjustmentValue","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"postAdjustmentValue","headerName":"Post Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"totalAdjustmentValue","headerName":"Total Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"originalValue","headerName":"Original Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","width":235,"suppressSizeToFit":true,"displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"view_impacts","headerName":"Impacts","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_IMPACT","tooltip":"View Impact Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Recurring","Once"]}},{"field":"tsaCode","headerName":"Adjustment Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Plan","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1135, 1, 'WORKBENCH', 'FFIEC041', 'REPORT_OUTLINE_TABLE_GRID', NULL, 'table', 'report_outline_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_outline","title":"Report Outline","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1136, 1, 'WORKBENCH', 'FFIEC041', 'EDITCHECK_TABLE_GRID', NULL, 'table', 'editcheck_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck","title":"Editcheck","rowIdKey":"aftId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ecType","headerName":"Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckName","headerName":"Editcheck Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Current State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":180,"suppressSizeToFit":true,"sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"workflowStatus","headerName":"Action","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":240,"suppressSizeToFit":true,"sortable":true,"filter":"agTextColumnFilter"},{"field":"view_details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"priority","headerName":"Priority","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["HIGH","MEDIUM","LOW"]}},{"field":"isHard","headerName":"Criticality","dataType":"STRING","cellDataType":"text","formatter":"EDITCHECK_CRITICALITY","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Hard Check","Soft Check"]}},{"field":"ecSource","headerName":"Source","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"recourrenceCount","headerName":"Recurrence Count","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1137, 1, 'WORKBENCH', 'FFIEC041', 'CONFIGURATION_TABLE_GRID', NULL, 'table', 'configuration_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"configuration","title":"Configuration","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1164, 1, 'WORKBENCH', 'FFIEC041', 'COMPLETENESS_SCORE_TABLE_GRID', NULL, 'table', 'completeness_score_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"completeness_score","title":"Completeness Score","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"completenessScore","headerName":"Completeness","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1138, 1, 'WORKBENCH', 'FFIEC041', 'VARIANCE_TABLE_GRID', NULL, 'table', 'variance_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"change","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"trends","headerName":"Trends","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"narrative","headerName":"Narrative","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1139, 1, 'WORKBENCH', 'FFIEC041', 'TSA_DETAILS_GRID', NULL, 'table', 'tsa_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"tsa_details","title":"TSA Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentAmount","headerName":"Adjustment Amount","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"tsaType","headerName":"TSA Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaCode","headerName":"TSA Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Date","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1140, 1, 'WORKBENCH', 'FFIEC041', 'CONFIG_DETAILS_GRID', NULL, 'table', 'config_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"config_details","title":"Configuration Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updated_by","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updateAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"commentsReportable","headerName":"Reportable Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"commentsConfidential","headerName":"Confidential Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1141, 1, 'WORKBENCH', 'FFIEC041', 'EDITCHECK_AUDIT_GRID', NULL, 'table', 'editcheck_audit_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_audit","title":"Editcheck Audit","rowIdKey":"aftId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Editcheck Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"actionStatus","headerName":"State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["OPEN","ON HOLD","CLOSED WITH MEMO","CLOSED","RE OPEN"]}},{"field":"workflowStatus","headerName":"Workflow Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1142, 1, 'WORKBENCH', 'FR5300', 'TSA_TABLE_GRID', NULL, 'table', 'tsa_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"top_side_adjustments","title":"Top Side Adjustments","rowIdKey":"adjustmentId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"adjustmentId","headerName":"Adj ID","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"recurranceCount","headerName":"Adj Occurrence","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agNumberColumnFilter"},{"field":"preAdjustmentValue","headerName":"Pre Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentAdjustmentValue","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"postAdjustmentValue","headerName":"Post Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"totalAdjustmentValue","headerName":"Total Adjustment","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"originalValue","headerName":"Original Value","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","width":235,"suppressSizeToFit":true,"displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"view_impacts","headerName":"Impacts","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_IMPACT","tooltip":"View Impact Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Recurring","Once"]}},{"field":"tsaCode","headerName":"Adjustment Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Plan","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1143, 1, 'WORKBENCH', 'FR5300', 'REPORT_OUTLINE_TABLE_GRID', NULL, 'table', 'report_outline_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_outline","title":"Report Outline","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1144, 1, 'WORKBENCH', 'FR5300', 'EDITCHECK_TABLE_GRID', NULL, 'table', 'editcheck_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck","title":"Editcheck","rowIdKey":"aftId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"ecType","headerName":"Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckName","headerName":"Editcheck Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Current State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":180,"suppressSizeToFit":true,"sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"workflowStatus","headerName":"Action","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","width":240,"suppressSizeToFit":true,"sortable":true,"filter":"agTextColumnFilter"},{"field":"view_details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"priority","headerName":"Priority","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["HIGH","MEDIUM","LOW"]}},{"field":"isHard","headerName":"Criticality","dataType":"STRING","cellDataType":"text","formatter":"EDITCHECK_CRITICALITY","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Hard Check","Soft Check"]}},{"field":"ecSource","headerName":"Source","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"recourrenceCount","headerName":"Recurrence Count","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1145, 1, 'WORKBENCH', 'FR5300', 'CONFIGURATION_TABLE_GRID', NULL, 'table', 'configuration_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"configuration","title":"Configuration","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"details","headerName":"Details","displayType":"ICON_BUTTON","params":{"icon":"EYE","actionCode":"VIEW_DETAILS","tooltip":"View Details"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1165, 1, 'WORKBENCH', 'FR5300', 'COMPLETENESS_SCORE_TABLE_GRID', NULL, 'table', 'completeness_score_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"completeness_score","title":"Completeness Score","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"amount","headerName":"Amount","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"completenessScore","headerName":"Completeness","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1146, 1, 'WORKBENCH', 'FR5300', 'VARIANCE_TABLE_GRID', NULL, 'table', 'variance_table_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"change","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"trends","headerName":"Trends","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"narrative","headerName":"Narrative","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1147, 1, 'WORKBENCH', 'FR5300', 'TSA_DETAILS_GRID', NULL, 'table', 'tsa_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"tsa_details","title":"TSA Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentAmount","headerName":"Adjustment Amount","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"tsaType","headerName":"TSA Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"tsaCode","headerName":"TSA Code","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"adjustmentComputation","headerName":"Adjustment Computation","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"remediationPlan","headerName":"Remediation Date","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"reason","headerName":"Reason","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"audit_log","headerName":"Audit","displayType":"ICON_BUTTON","params":{"icon":"ARTICLE","actionCode":"VIEW_AUDIT","tooltip":"View Audit"}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1148, 1, 'WORKBENCH', 'FR5300', 'CONFIG_DETAILS_GRID', NULL, 'table', 'config_details_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"config_details","title":"Configuration Details","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"reportable","headerName":"Reportable","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"confidential","headerName":"Confidential","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["Yes","No"]}},{"field":"adjType","headerName":"Adjustment Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updated_by","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updateAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"commentsReportable","headerName":"Reportable Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"commentsConfidential","headerName":"Confidential Comments","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1149, 1, 'WORKBENCH', 'FR5300', 'EDITCHECK_AUDIT_GRID', NULL, 'table', 'editcheck_audit_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_audit","title":"Editcheck Audit","rowIdKey":"aftId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"aftId","headerName":"AFT ID","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"editCheckStatus","headerName":"Editcheck Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]}},{"field":"actionStatus","headerName":"State","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["OPEN","ON HOLD","CLOSED WITH MEMO","CLOSED","RE OPEN"]}},{"field":"workflowStatus","headerName":"Workflow Status","dataType":"STRING","cellDataType":"text","displayType":"STATUS_CHIP","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["APPROVED","REJECTED","PENDING_APPROVAL"]}},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated At","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SU' AND node_code = 'GLOBAL' AND group_key = 'SUPPLEMENTAL_UPLOAD_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) values
    (1150, 1, 'SU', 'GLOBAL', 'SUPPLEMENTAL_UPLOAD_GRID', NULL, 'table', 'supplemental_upload_grid_key', 'GRID', 'INLINE', 1, TRUE,'{"gridConfig":{"gridId":"supplemental_upload","title":"Supplemental Upload","rowIdKey":"id","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"id","headerName":"ID","dataType":"NUMBER","cellDataType":"number","sortable":false,"filter":"agNumberColumnFilter","suppressMenuButton":true},{"field":"fileName","headerName":"File Name","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter","flex":1},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"restatementVersion","headerName":"Restatement Version","dataType":"NUMBER","cellDataType":"number","sortable":false,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"File Status","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agSetColumnFilter","suppressContextMenu":true,"cellRenderer":"StatusRenderer","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL","FAILED","DISCARD"]}},{"field":"validationStatus","headerName":"Validation Status","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agSetColumnFilter","cellRenderer":"StatusRenderer","filterParams":{"values":["PROCESSING","WARNING","FAILED","SUCCESS"]}},{"field":"view","headerName":"View","sortable":false,"filter":false,"cellRenderer":"ViewActionRenderer"},{"field":"audit_log","headerName":"Audit","sortable":false,"filter":false,"cellRenderer":"AuditActionRenderer"},{"field":"download","headerName":"Download","sortable":false,"filter":false,"suppressContextMenu":true,"cellRenderer":"DownloadActionRenderer"},{"field":"errorFileName","headerName":"Error File","sortable":false,"filter":false,"cellRenderer":"ErrorFileRenderer"},{"field":"uploadedBy","headerName":"Uploaded By","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"uploadedOn","headerName":"Uploaded On","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'REPORT_STORE' AND node_code = 'GLOBAL' AND group_key = 'REPORT_STORE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1151, 1, 'REPORT_STORE', 'GLOBAL', 'REPORT_STORE_GRID', NULL, 'table', 'report_store_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"report_store","title":"Report Store","rowIdKey":"id","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"id","headerName":"ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"fileName","headerName":"File Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1},{"field":"formGroup","headerName":"Form Group","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"formName","headerName":"Form Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"reportVersion","headerName":"Version","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","filterParams":{"values":["COMPLETED","FAILED"]},"cellRenderer":"ReportStoreStatusRenderer"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"restatementVersion","headerName":"Restatement Version","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"workflowStatus","headerName":"Action","cellRenderer":"ReportStoreWorkflowRenderer","sortable":false,"filter":false,"minWidth":240,"flex":1},{"field":"download","headerName":"Download","cellRenderer":"MultiDownloadActionRenderer","sortable":false,"filter":false,"minWidth":180,"flex":1},{"field":"regenerate","headerName":"Re-Generate","cellRenderer":"RegenerateActionRenderer","sortable":false,"filter":false,"cellStyle":{"textAlign":"center"}},{"field":"audit_log","headerName":"Audit","sortable":false,"filter":false,"cellRenderer":"AuditActionRenderer"},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"createdOn","headerName":"Created On","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"updatedOn","headerName":"Updated On","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RECON' AND node_code = 'GLOBAL' AND group_key = 'RECON_REPORT_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1152, 1, 'RECON', 'GLOBAL', 'RECON_REPORT_GRID', NULL, 'table', 'recon_report_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"recon_report","title":"Recon Report","rowIdKey":"id","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"id","headerName":"ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"formName","headerName":"Form Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"reportId","headerName":"Report ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","filterParams":{"values":["COMPLETED","FAILED"]},"cellRenderer":"ReportStoreStatusRenderer"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"download","headerName":"Download","cellRenderer":"MultiDownloadActionRenderer","sortable":false,"filter":false,"minWidth":180,"flex":1},{"field":"createdBy","headerName":"Created By","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"updatedBy","headerName":"Updated By","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"createdAt","headerName":"Created On","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"updatedAt","headerName":"Updated On","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RULES' AND node_code = 'GLOBAL' AND group_key = 'RULE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1153, 1, 'RULES', 'GLOBAL', 'RULE_GRID', NULL, 'table', 'rule_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"rule_grid","title":"Rule Grid","rowIdKey":"nodeid","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"rulename","headerName":"Rule","dataType":"STRING","cellDataType":"text","flex":1.4},{"field":"version","headerName":"Version","dataType":"NUMBER","cellDataType":"number"},{"field":"status","headerName":"Status","dataType":"STRING","cellDataType":"text","cellRenderer":"StatusRenderer","cellRendererParams":{"variant":"text"}},{"field":"effectiveperiod","headerName":"Effective Date","dataType":"STRING","cellDataType":"text"},{"field":"createdby","headerName":"Created By","dataType":"STRING","cellDataType":"text"},{"field":"createdon","headerName":"Created Date","dataType":"STRING","cellDataType":"text"},{"field":"updatedby","headerName":"Updated By","dataType":"STRING","cellDataType":"text"},{"field":"updatedon","headerName":"Updated Date","dataType":"STRING","cellDataType":"text"},{"field":"comments","headerName":"Comments","dataType":"STRING","cellDataType":"text"},{"field":"ruletypename","headerName":"Rule Type","dataType":"STRING","cellDataType":"text"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'DATASET' AND node_code = 'GLOBAL' AND group_key = 'DATASET_ATTRIBUTE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1154, 1, 'DATASET', 'GLOBAL', 'DATASET_ATTRIBUTE_GRID', NULL, 'table', 'dataset_attribute_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"dataset_attribute_grid","title":"Dataset Attributes","rowIdKey":"columnName","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"columnName","headerName":"Attribute Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1},{"field":"type","headerName":"Attribute Type","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RULES' AND node_code = 'GLOBAL' AND group_key = 'EXECUTION_HISTORY_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1155, 1, 'RULES', 'GLOBAL', 'EXECUTION_HISTORY_GRID', NULL, 'table', 'execution_history_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"execution_history_grid","title":"Execution History","rowIdKey":"exec_id","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"exec_id","headerName":"ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","cellClass":"ag-right-aligned-cell","cellRenderer":"ExecutionIdRenderer"},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"rule_name","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"rule_version","headerName":"Rule Version","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","cellClass":"ag-right-aligned-cell"},{"field":"exec_status","headerName":"Execution Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","cellRenderer":"StatusRenderer","cellRendererParams":{"variant":"text"}},{"field":"exec_msg","headerName":"Execution Message","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","tooltipField":"exec_msg"},{"field":"status_latest","headerName":"Latest Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter"},{"field":"created_at","headerName":"Created At","dataType":"DATE","cellDataType":"dateString","filter":"agDateColumnFilter"},{"field":"updated_at","headerName":"Updated At","dataType":"DATE","cellDataType":"dateString","filter":"agDateColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RULES' AND node_code = 'GLOBAL' AND group_key = 'EXECUTION_RESULTS_POPUP_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1156, 1, 'RULES', 'GLOBAL', 'EXECUTION_RESULTS_POPUP_GRID', NULL, 'table', 'execution_results_popup_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"execution_results_popup","title":"Execution Results","rowIdKey":"execId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"ruleNm","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1},{"field":"message","headerName":"Message","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":2},{"field":"status","headerName":"Execution Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","cellRenderer":"StatusRenderer","cellRendererParams":{"variant":"text"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RULES' AND node_code = 'GLOBAL' AND group_key IN ('IMPACTED_LINES_SUMMARY_GRID', 'IMPACTED_LINES_DETAIL_GRID');
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1157, 1, 'RULES', 'GLOBAL', 'IMPACTED_LINES_SUMMARY_GRID', NULL, 'table', 'impacted_lines_summary_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"impacted_lines_summary","title":"Impacted Lines Summary","rowIdKey":"taxonomyId","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyId","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1.1},{"field":"line","headerName":"Line","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1.8},{"field":"currentValue","headerName":"Current Value","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"ecCount","headerName":"Impacted ECs","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"ecStatus","headerName":"EC Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]},"flex":0.9,"cellRenderer":"StatusRenderer","cellRendererParams":{"variant":"text"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin'),
    (1158, 1, 'RULES', 'GLOBAL', 'IMPACTED_LINES_DETAIL_GRID', NULL, 'table', 'impacted_lines_detail_grid_key', 'GRID', 'INLINE', 2, TRUE, '{"gridConfig":{"gridId":"impacted_lines_detail","title":"Impacted Lines Detail","rowIdKey":"editCheck","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"expand","headerName":"","cellRenderer":"agGroupCellRenderer","cellRendererParams":{"suppressCount":true},"width":40},{"field":"editCheck","headerName":"Edit Check","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1.4},{"field":"ruleName","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":1.6},{"field":"ecType","headerName":"EC Type","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","flex":0.9},{"field":"ecStatus","headerName":"EC Status","dataType":"STRING","cellDataType":"text","filter":"agSetColumnFilter","filterParams":{"values":["FAIL","PASS"]},"flex":0.9,"cellRenderer":"StatusRenderer","cellRendererParams":{"variant":"text"}}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'RULES' AND node_code = 'GLOBAL' AND group_key IN ('EDITCHECK_BREAKS_SUMMARY_GRID', 'EDITCHECK_BREAKS_IMPACT_GRID');
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1159, 1, 'RULES', 'GLOBAL', 'EDITCHECK_BREAKS_SUMMARY_GRID', NULL, 'table', 'editcheck_breaks_summary_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"editcheck_breaks_summary","title":"Impacted Lines","rowIdKey":"line","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"line","headerName":"Line","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"pre","headerName":"Original","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"adjustment","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"after","headerName":"After","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"ec_status","headerName":"EC Status","cellRenderer":"EditCheckStatusRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin'),
    (1160, 1, 'RULES', 'GLOBAL', 'EDITCHECK_BREAKS_IMPACT_GRID', NULL, 'table', 'editcheck_breaks_impact_grid_key', 'GRID', 'INLINE', 2, TRUE, '{"gridConfig":{"gridId":"editcheck_breaks_impact","title":"Rule Impact Summary","rowIdKey":"ec_id","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"expand","headerName":"","cellRenderer":"agGroupCellRenderer","cellRendererParams":{"suppressCount":true},"width":30},{"field":"ec_id","headerName":"EC ID","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":0.8},{"field":"description","headerName":"Description","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter","flex":2},{"field":"ec_status","headerName":"EC Status","cellRenderer":"EditCheckStatusRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

UPDATE meta.ui_elements_config SET element_type = 'DROPDOWN' WHERE element_type = 'BOOLEAN' ;

-- =========================================== --


INSERT INTO meta.menu_master values(1,1,'Home','Home',1,true,NOW());
INSERT INTO meta.menu_master values(1,2,'Analytics','Analytics',2,true,NOW());
INSERT INTO meta.menu_master values(1,3,'Lineage','Lineage',3,true,NOW());
INSERT INTO meta.menu_master values(1,4,'Rules Management','Rules Management',4,true,NOW());
INSERT INTO meta.menu_master values(1,5,'Data Management','Data Management',5,true,NOW());
INSERT INTO meta.menu_master values(1,6,'Report Store','Report Store',6,true,NOW());
INSERT INTO meta.menu_master values(1,7,'Dashboard','Dashboard',7,true,NOW());


-- Rules
INSERT INTO meta.menu_component values(1,1,4,'Report Rules','Report Rules',1,true,NOW());
INSERT INTO meta.menu_component values(1,2,4,'Chart of Account','Chart of Account',2,true,NOW());
INSERT INTO meta.menu_component values(1,3,4,'Edit checks','Edit checks',3,true,NOW());
INSERT INTO meta.menu_component values(1,4,4,'Data Quality Rules','Data Quality Rules',4,true,NOW());

-- Analytics
INSERT INTO meta.menu_component values(1,5,2,'Dashboard','Dashboard',1,true,NOW());
INSERT INTO meta.menu_component values(1,6,2,'Canned Reports','Canned Reports',2,true,NOW());
INSERT INTO meta.menu_component values(1,7,2,'Ad-hoc reporting','Ad-hoc reporting',3,true,NOW());

-- SU
INSERT INTO meta.menu_component values(1,8,5,'Report','Report',1,true,NOW());
INSERT INTO meta.menu_component values(1,9,5,'Dataset','Dataset',2,true,NOW());

-- Report Store
INSERT INTO meta.menu_component values(1,10,6,'Report','Report',1,true,NOW());
INSERT INTO meta.menu_component values(1,11,6,'Ad-hoc reporting','Ad-hoc Reports',2,true,NOW());
INSERT INTO meta.menu_component values(1,13,6,'Report','Recon Reports',3,true,NOW());

UPDATE meta.menu_component SET display_name = 'Regulatory Reports' WHERE id = 10;

-- Drilldown metadata ---
INSERT INTO meta.drilldown_stage_metadata
(client_id, stage_key, stage_display_name, stage_order, created_by, updated_by)
VALUES
('1', 'RAW_DATA', 'Raw Data', 1, 'system', 'system'),
('1', 'CURATED_DATA', 'Curated Data', 2, 'system', 'system'),
('1', 'REGULATORY_LEDGER', 'Regulatory Ledger', 3, 'system', 'system'),
('1', 'COMBINED_FACT', 'Combined Fact', 4, 'system', 'system'),
('1', 'REPORT_READY_DATA', 'Report Ready Data', 5, 'system', 'system');


INSERT INTO meta.drilldown_stage_query_registry (client_id, stage_key, query_name, dataset_query, description)
VALUES ( '1', 'RAW_DATA', 'default', 'SELECT client_id, ds_nm as dataset_key, ds_nm as dataset_display_name, null as base_table_name, unload_query as base_query FROM meta.dataset_details WHERE client_id = :clientId ORDER BY ds_nm', 'Raw Data datasets from dataset_details table')
ON CONFLICT (client_id, stage_key, query_name) DO NOTHING;

-- End of drilldown metadata ---

--workflow for report generation
DELETE FROM meta.workflow_module_map
WHERE client_id = 1 AND module_master_id = 4;

DELETE FROM meta.workflow_metadata
WHERE client_id = 1 AND id = 4;

DELETE FROM meta.workflow_master
WHERE client_id = 1 AND id = 4;

DELETE FROM meta.module_master
WHERE client_id = 1 AND id = 4;

INSERT INTO meta.workflow_master
VALUES (
           1,
           4,
           'reportgeneration',
           'rg_custom_workflow',
           'Custom workflow for report generation',
           NOW(),
           'SYSTEM',
           NOW(),
           'SYSTEM'
       );

INSERT INTO meta.workflow_metadata
VALUES (
           1,
           4,
           'rg_custom_workflow',
           '{
               "endStates": ["SUBMIT_TO"],
               "transitions": {
                   "DRAFT": {
                       "actions": {
                           "submit": "PENDING_APPROVAL",
                           "discard": "DISCARD"
                       }
                   },
                   "PENDING_APPROVAL": {
                       "actions": {
                           "reject": "REJECTED",
                           "approve": "APPROVED"
                       }
                   },
                   "APPROVED": {
                       "actions": {
                           "submit_to": "SUBMIT_TO"
                       }
                   }
               },
               "initialStage": "DRAFT"
           }'::jsonb,
           'lextr_user',
           NOW(),
           'active'
       );

INSERT INTO meta.module_master
VALUES (1, 4, 'report_generation');

INSERT INTO meta.workflow_module_map
VALUES (1, 4, 4);
-- =========== END OF SCRIPT FILE ============ --

-- Attestation - question answer
-- Supplemental attestation questions

INSERT INTO meta.attestation_catalog (id, client_id, label, answer_type, options_json, validation_json, ui_json, created_by) VALUES
(1,1,'I confirm the uploaded data is sourced from an authorized and reliable origin.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(2,1,'I confirm the uploaded data has been reviewed for completeness and reconciled where applicable.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(3,1,'I confirm supporting documentation and methodology are retained and available upon request.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(4,1,'I acknowledge this upload is a temporary compensating control and does not replace primary source data.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(5,1,'I confirm the impact of this upload on downstream reporting has been assessed.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(6,1,'Please provide additional comments','TEXTAREA',NULL,'{"required":false,"maxLength":1000}','{"rows":4}','system'),
(7,1,'I confirm this adjustment is supported by documented business rationale and regulatory guidance.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(8,1,'I confirm the adjustment amount and methodology have been verified for accuracy.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(9,1,'I confirm this adjustment does not introduce duplication, omission, or unintended overrides.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(10,1,'I confirm this adjustment meets approval and governance requirements.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system'),
(11,1,'I confirm root cause and remediation actions have been evaluated where applicable.','CHECKBOX',NULL,'{"required":true,"mustBeTrue":true}',NULL,'system')
ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, answer_type = EXCLUDED.answer_type, options_json = EXCLUDED.options_json, validation_json = EXCLUDED.validation_json, ui_json = EXCLUDED.ui_json, updated_by = 'system', updated_on = now();

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=11 AND attestation_id IN (1,2,3,4,5,6);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,1,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,2,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,3,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,4,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,5,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=26 AND attestation_id IN (1,2,3,4,5,6);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,1,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,2,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,3,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,4,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,5,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='APPROVED' AND node_id=11 AND attestation_id IN (6,7,8,9,10,11);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,7,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,8,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,9,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,10,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,11,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',11,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='APPROVED' AND node_id=26 AND attestation_id IN (6,7,8,9,10,11);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,7,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,8,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,9,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,10,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,11,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',26,6,6,false,'system');

-- To deactivate attestations using client_id, module, workflow, stage
-- update meta.attestation_master  set active = false  where client_id = 1 and module = 'supplemental_upload' and node_id = 11 and workflow = 'UPLOAD' and stage = 'APPROVED';

INSERT INTO meta.attestation_catalog (id, client_id, label, answer_type, options_json, validation_json, ui_json, created_by) VALUES
(12,1,'Upload supporting document via Dropbox','DROPBOX',NULL,'{"required":false,"allowedExtensions":["pdf","doc","docx","png","jpg","jpeg"],"maxSizeMB":10}','{"provider":"dropbox","buttonLabel":"Choose from File System"}','system')
ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, answer_type = EXCLUDED.answer_type, options_json = EXCLUDED.options_json, validation_json = EXCLUDED.validation_json, ui_json = EXCLUDED.ui_json, updated_by = 'system', updated_on = now();

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=11 AND attestation_id IN (12);
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',11,12,7,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=26 AND attestation_id IN (12);
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',26,12,7,false,'system');

UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='deposits' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='financial_ledger' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='regulatory_ledger' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='derivatives' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='securities' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='mortgages' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='credit_card' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='personal_loan' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='trade_product' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='corp_loan' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='general_ledger' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='cash_and_due' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='journal_transaction' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='sft' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='collateral' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='credit_facility' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='fry14a' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='fry14q' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='fry14m' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='FRY9C' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='FR5300' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';
UPDATE meta.ui_elements_config SET config_json='{"options":[{"label":"Mexico","value":"MEXICO"},{"label":"Citigroup","value":"Citigroup"},{"label":"CBNA","value":"CBNA"}]}' WHERE client_id=1 AND node_code='R01A' AND module_name='SU' AND group_key='UPLOAD_FORM' AND element_key='legal_entity';

-- Report Generation for FR2900 & FRY9CSP
DELETE from meta.report_store_metadata where id in (4,5,6);

INSERT INTO meta.report_store_metadata(
    client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
VALUES (1, 4, 'US Regulatory Reporting', 'FR2900', null, null, 'FR2900', 'XML,XBRL,RCP,PDF', null);

INSERT INTO meta.report_store_metadata(
    client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
VALUES (1, 5, 'US Regulatory Reporting', 'FRY9CSP', null, null, 'FRY9CSP', 'XML,XBRL,RCP,PDF', null);

INSERT INTO meta.report_store_metadata(
    client_id, id, form_group, form_name, schedule_name, sub_schedule_name, actual_report_name, report_type, xsd_path)
VALUES (1, 6, 'US Regulatory Reporting', 'FFIEC041', null, null, 'FFIEC041', 'XML,XBRL,RCP,PDF', null);

-- Insert rejection-specific attestation questions
INSERT INTO meta.attestation_catalog (id, client_id, label, answer_type, options_json, validation_json, ui_json, created_by) VALUES
(13,1,'Please specify the reason(s) for rejection','TEXTAREA',NULL,'{"required":true,"maxLength":500}','{"rows":4}','system'),
(14,1,'What remediation actions are required before resubmission?','TEXTAREA',NULL,'{"required":true,"maxLength":500}','{"rows":4}','system'),
(15,1,'Provide a recommended timeline for resubmission','TEXTAREA',NULL,'{"required":true,"maxLength":500}','{"rows":3}','system')
ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, answer_type = EXCLUDED.answer_type, options_json = EXCLUDED.options_json, validation_json = EXCLUDED.validation_json, ui_json = EXCLUDED.ui_json, updated_by = 'system', updated_on = now();

-- Rejection attestations for SU module (UPLOAD workflow, REJECTED stage) - Node 11 (Regulatory Ledger)
DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='REJECTED' AND node_id=11 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',11,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',11,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',11,15,3,true,'system');

-- Rejection attestations for SU module (UPLOAD workflow, REJECTED stage) - Node 26 (R01A)
DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='REJECTED' AND node_id=26 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',26,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',26,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',26,15,3,true,'system');

-- Rejection attestations for TSA module (TSA workflow, REJECTED stage) - Node 11 (Regulatory Ledger)
DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='REJECTED' AND node_id=11 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',11,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',11,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',11,15,3,true,'system');

-- Rejection attestations for TSA module (TSA workflow, REJECTED stage) - Node 26 (R01A)
DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='REJECTED' AND node_id=26 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',26,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',26,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',26,15,3,true,'system');

DELETE FROM meta.menu_component where menu_id = 4;
INSERT INTO meta.menu_component values(1,12,4,'All Rules','All Rules',1,true,NOW());
INSERT INTO meta.menu_component values(1,1,4,'Report Rules','Report Rules',2,true,NOW());
INSERT INTO meta.menu_component values(1,2,4,'Chart of Account','Chart of Account',3,true,NOW());
INSERT INTO meta.menu_component values(1,3,4,'Edit checks','Edit checks',4,true,NOW());
INSERT INTO meta.menu_component values(1,4,4,'Data Quality Rules','Data Quality Rules',5,true,NOW());


INSERT INTO meta.rule_type (rule_type_id, rule_type_name, created_on, created_by, updated_on, updated_by)
VALUES (4, 'Ledger', now(), 'system', now(), 'system');

-- Add Attestation for Financial Ledger and Mortgage for SU module
DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=10 AND attestation_id IN (1,2,3,4,5,6);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,1,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,2,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,3,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,4,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,5,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='APPROVED' AND node_id=10 AND attestation_id IN (6,7,8,9,10,11);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,7,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,8,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,9,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,10,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,11,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',10,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='REJECTED' AND node_id=10 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',10,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',10,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',10,15,3,true,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='REJECTED' AND node_id=10 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',10,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',10,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',10,15,3,true,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=15 AND attestation_id IN (1,2,3,4,5,6);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,1,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,2,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,3,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,4,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,5,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='APPROVED' AND node_id=15 AND attestation_id IN (6,7,8,9,10,11);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,7,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,8,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,9,3,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,10,4,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,11,5,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','APPROVED',15,6,6,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='REJECTED' AND node_id=15 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',15,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',15,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','REJECTED',15,15,3,true,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=2 AND workflow='TSA' AND stage='REJECTED' AND node_id=15 AND attestation_id IN (13,14,15);

INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',15,13,1,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',15,14,2,true,'system');
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,2,'TSA','REJECTED',15,15,3,true,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=10 AND attestation_id IN (12);
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',10,12,7,false,'system');

DELETE FROM meta.attestation_master WHERE client_id=1 AND module_id=1 AND workflow='UPLOAD' AND stage='APPROVED' AND node_id=15 AND attestation_id IN (12);
INSERT INTO meta.attestation_master (client_id,module_id,workflow,stage,node_id,attestation_id,display_order,required,created_by) VALUES (1,1,'UPLOAD','APPROVED',15,12,7,false,'system');

UPDATE meta.ui_elements_config
SET config_json = '{"gridConfig":{"gridId":"supplemental_upload","title":"Supplemental Upload","rowIdKey":"id","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"id","headerName":"ID","dataType":"NUMBER","cellDataType":"number","sortable":false,"filter":"agNumberColumnFilter","suppressMenuButton":false},{"field":"fileName","headerName":"File Name","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter","flex":1},{"field":"period","headerName":"Period","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"restatementVersion","headerName":"Restatement Version","dataType":"NUMBER","cellDataType":"number","sortable":false,"filter":"agNumberColumnFilter"},{"field":"status","headerName":"File Status","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agSetColumnFilter","suppressContextMenu":true,"cellRenderer":"StatusRenderer","filterParams":{"values":["DRAFT","APPROVED","REJECTED","PENDING_APPROVAL","FAILED","DISCARD"]}},{"field":"validationStatus","headerName":"Validation Status","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agSetColumnFilter","cellRenderer":"StatusRenderer","filterParams":{"values":["PROCESSING","WARNING","FAILED","SUCCESS"]}},{"field":"view","headerName":"View","sortable":false,"filter":false,"cellRenderer":"ViewActionRenderer"},{"field":"audit_log","headerName":"Audit","sortable":false,"filter":false,"cellRenderer":"AuditActionRenderer"},{"field":"download","headerName":"Download","sortable":false,"filter":false,"suppressContextMenu":true,"cellRenderer":"DownloadActionRenderer"},{"field":"errorFileName","headerName":"Error File","sortable":false,"filter":false,"cellRenderer":"ErrorFileRenderer"},{"field":"uploadedBy","headerName":"Uploaded By","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"},{"field":"uploadedOn","headerName":"Uploaded On","dataType":"STRING","cellDataType":"text","sortable":false,"filter":"agTextColumnFilter"}]}}'
WHERE element_id = 1150;

update meta.ui_elements_config set config_json =
'{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"variancePercentage","headerName":"Δ / Change","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"aiexplanation","headerName":"","dataType":"STRING","cellDataType":"text"}]}}'
where element_id = 1122;
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'OBSERVABILITY_SIGNALS_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1200, 1, 'SEMANTIC', 'GLOBAL', 'OBSERVABILITY_SIGNALS_GRID', NULL, 'table', 'observability_signals_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "observability_signals", "title": "Observability Signals", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "objectName", "headerName": "OBJECT (LOGICAL)", "width": 250, "cellRenderer": "ObservabilityObjectNameRenderer"}, {"field": "signalType", "headerName": "SIGNAL", "width": 180}, {"field": "severity", "headerName": "SEVERITY", "width": 120, "cellRenderer": "ObservabilitySeverityRenderer"}, {"field": "message", "headerName": "DETAIL", "flex": 1}, {"field": "detectedTs", "headerName": "DETECTED", "width": 180, "cellRenderer": "SemanticDateRenderer"}, {"field": "status", "headerName": "STATUS", "width": 130, "cellRenderer": "ObservabilityStatusRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'PROFILING_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1201, 1, 'SEMANTIC', 'GLOBAL', 'PROFILING_GRID', NULL, 'table', 'profiling_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "profiling", "title": "Data Profiling", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "objectName", "headerName": "OBJECT", "width": 150}, {"field": "attributeName", "headerName": "LOGICAL ATTRIBUTE", "width": 220, "cellRenderer": "ProfilingAttributeRenderer"}, {"field": "inferredRole", "headerName": "ROLE", "width": 150, "cellRenderer": "ProfilingRoleRenderer"}, {"field": "nullPercentage", "headerName": "NULL %", "width": 110, "cellRenderer": "ProfilingNullPercentageRenderer"}, {"field": "distinctPercentage", "headerName": "DISTINCT %", "width": 130, "cellRenderer": "ProfilingDistinctPercentageRenderer"}, {"field": "profilingStatus", "headerName": "STATUS", "flex": 1, "cellRenderer": "ProfilingStatusRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'DQ_MATRIX_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1202, 1, 'SEMANTIC', 'GLOBAL', 'DQ_MATRIX_GRID', NULL, 'table', 'dq_matrix_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "dq_matrix", "title": "Data Quality Matrix", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "objectName", "headerName": "Object", "flex": 1.5}, {"field": "attributeName", "headerName": "Attribute", "flex": 1.5}, {"field": "completeness", "headerName": "Completeness %", "flex": 1}, {"field": "validity", "headerName": "Validity %", "flex": 1}, {"field": "uniqueness", "headerName": "Uniqueness %", "flex": 1}, {"field": "accuracy", "headerName": "Accuracy %", "flex": 1}, {"field": "consistency", "headerName": "Consistency %", "flex": 1}, {"field": "actions", "headerName": "Action", "flex": 1, "sortable": false, "filter": false, "cellRenderer": "DQMatrixActionRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'DQ_RULES_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1203, 1, 'SEMANTIC', 'GLOBAL', 'DQ_RULES_GRID', NULL, 'table', 'dq_rules_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "dq_rules", "title": "Data Quality Rules", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "id", "headerName": "RULE ID", "flex": 0.8}, {"field": "name", "headerName": "RULE", "flex": 1.5, "autoHeight": true}, {"field": "type", "headerName": "TYPE", "flex": 0.8}, {"field": "dimension", "headerName": "DIMENSION", "flex": 0.8}, {"field": "description", "headerName": "DEFINITION (PLAIN ENGLISH)", "flex": 1, "autoHeight": true}, {"field": "status", "headerName": "STATUS", "flex": 0.8}, {"field": "lastExecutedAt", "headerName": "LAST EXECUTION", "flex": 1}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'DQ_RULE_MATRIX_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1204, 1, 'SEMANTIC', 'GLOBAL', 'DQ_RULE_MATRIX_GRID', NULL, 'table', 'dq_rule_matrix_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "dq_rule_matrix", "title": "DQ Rule Matrix", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "id", "headerName": "ID", "flex": 0.5}, {"field": "name", "headerName": "RULE", "flex": 1.5, "autoHeight": true}, {"field": "Completeness", "headerName": "COMPLETENESS", "flex": 0.8}, {"field": "Validity", "headerName": "VALIDITY", "flex": 0.8}, {"field": "Uniqueness", "headerName": "UNIQUENESS", "flex": 0.8}, {"field": "Accuracy", "headerName": "ACCURACY", "flex": 0.8}, {"field": "Consistency", "headerName": "CONSISTENCY", "flex": 0.8}, {"field": "Timeliness", "headerName": "TIMELINESS", "flex": 0.8}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_RULE_CATALOG_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1205, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_RULE_CATALOG_GRID', NULL, 'table', 'semantic_rule_catalog_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_rule_catalog", "title": "Rule Catalog", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "id", "headerName": "ID", "width": 90}, {"field": "ruleSetId", "headerName": "RS ID", "width": 80}, {"field": "name", "headerName": "RULE", "flex": 1.5, "cellRenderer": "CatalogRuleNameRenderer"}, {"field": "dimension", "headerName": "DIMENSION", "width": 130}, {"field": "targetObj", "headerName": "TARGET OBJECT", "width": 180, "cellRenderer": "CatalogRuleTargetObjRenderer"}, {"field": "targetAttr", "headerName": "TARGET ATTR", "width": 150, "cellRenderer": "CatalogRuleTargetAttrRenderer"}, {"field": "status", "headerName": "STATUS", "width": 120, "cellRenderer": "CatalogRuleStatusRenderer"}, {"field": "actions", "headerName": "ACTION", "width": 80, "sortable": false, "filter": false, "cellRenderer": "CatalogRuleActionRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_RULE_MATRIX_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1206, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_RULE_MATRIX_GRID', NULL, 'table', 'semantic_rule_matrix_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_rule_matrix", "title": "Rule Matrix", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "id", "headerName": "ID", "flex": 0.5}, {"field": "name", "headerName": "RULE", "flex": 1.5, "autoHeight": true}, {"field": "dimension", "headerName": "COMPLETENESS", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}, {"field": "dimension", "headerName": "VALIDITY", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}, {"field": "dimension", "headerName": "UNIQUENESS", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}, {"field": "dimension", "headerName": "ACCURACY", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}, {"field": "dimension", "headerName": "CONSISTENCY", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}, {"field": "dimension", "headerName": "TIMELINESS", "flex": 0.8, "cellRenderer": "DQRuleMatrixDimensionRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_CATALOG_ATTR_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1207, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_CATALOG_ATTR_GRID', NULL, 'table', 'semantic_catalog_attr_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_catalog_attr", "title": "Catalog Attributes", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "attrId", "headerName": "ID", "flex": 0.8}, {"field": "cd", "headerName": "Physical", "flex": 1.2}, {"field": "ln", "headerName": "Logical", "flex": 1.4}, {"field": "type", "headerName": "Type", "flex": 1}, {"field": "semantic", "headerName": "Semantic", "flex": 1}, {"field": "pk", "headerName": "PK", "flex": 0.5}, {"field": "indexed", "headerName": "IDX", "flex": 0.5}, {"field": "domain", "headerName": "Domain", "flex": 0.8}, {"field": "cde", "headerName": "CDE", "flex": 0.8}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_QUERY_STUDIO_WORKSPACE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1208, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_QUERY_STUDIO_WORKSPACE_GRID', NULL, 'table', 'semantic_query_studio_workspace_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_query_studio_workspace", "title": "Workspace", "rowIdKey": "key", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "attrId", "headerName": "ID", "width": 64}, {"field": "ln", "headerName": "Logical Name", "flex": 1.5}, {"field": "qualified", "headerName": "Attribute Path", "flex": 1.5}, {"field": "cd", "headerName": "Physical (SQL)", "flex": 1}, {"field": "objKey", "headerName": "Object", "flex": 1}, {"field": "semantic", "headerName": "Role", "flex": 0.8}, {"field": "filterLookup", "headerName": "Filter Lookup", "flex": 1, "cellRenderer": "WorkspaceFilterLookupRenderer"}, {"field": "action", "headerName": "Action", "width": 70, "cellRenderer": "WorkspaceActionRenderer", "sortable": false, "filter": false}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_WORKFLOW_QUEUE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1209, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_WORKFLOW_QUEUE_GRID', NULL, 'table', 'semantic_workflow_queue_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_workflow_queue", "title": "Workflow Queue", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"headerName": "Request", "field": "desc", "flex": 1.8}, {"headerName": "Status", "field": "status", "flex": 1, "cellRenderer": "WorkflowStatusRenderer"}, {"headerName": "Type", "field": "type", "flex": 1.4}, {"headerName": "Submitted By", "field": "createdBy", "flex": 1}, {"headerName": "Created On", "field": "createdAt", "flex": 1, "cellRenderer": "SemanticDateRenderer"}, {"headerName": "Priority", "field": "priority", "flex": 0.8, "cellRenderer": "WorkflowPriorityRenderer"}, {"headerName": "Audit", "field": "workflowId", "width": 70, "cellRenderer": "audit", "sortable": false, "filter": false}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_PAIRINGS_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1210, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_PAIRINGS_GRID', NULL, 'table', 'semantic_pairings_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_pairings", "title": "Attribute Pairings", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "cd", "headerName": "Pairing Code", "flex": 1.8}, {"field": "strategy", "headerName": "Strategy", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "dispAttr", "headerName": "Display Attr", "flex": 1.2}, {"field": "filtAttr", "headerName": "Filter Attr", "flex": 1.2}, {"field": "srcObj", "headerName": "Source Object", "flex": 1.3}, {"field": "bidir", "headerName": "Bidir", "flex": 0.8, "cellRenderer": "PairingBidirRenderer"}, {"field": "st", "headerName": "Status", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "cardinality", "headerName": "Cardinality", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "action", "headerName": "ACTION", "width": 90, "cellRenderer": "PairingActionRenderer"}, {"field": "workflowId", "headerName": "Audit", "width": 70, "cellRenderer": "audit"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_REGISTER_OBJECT_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1211, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_REGISTER_OBJECT_GRID', NULL, 'table', 'semantic_register_object_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_register_object", "title": "Register Object Attributes", "rowIdKey": "name", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "expand", "headerName": "", "width": 50}, {"field": "name", "headerName": "Attribute", "flex": 1.5}, {"field": "logicalShortNm", "headerName": "Short Name", "flex": 1}, {"field": "logicalLongNm", "headerName": "Long Name", "flex": 1.5}, {"field": "dbType", "headerName": "DB Type", "width": 130}, {"field": "role", "headerName": "Role", "flex": 1}, {"field": "semantic", "headerName": "Semantic", "width": 110}, {"field": "aiExposed", "headerName": "AI", "width": 80}, {"field": "domain", "headerName": "Domain", "flex": 1}, {"field": "effectiveFrom", "headerName": "Eff. From", "width": 140}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_REGISTER_INVENTORY_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1212, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_REGISTER_INVENTORY_GRID', NULL, 'table', 'semantic_register_inventory_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_register_inventory", "title": "Object Inventory", "rowIdKey": "obj", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "schema", "headerName": "Schema", "width": 120}, {"field": "obj", "headerName": "Object", "flex": 1.4, "minWidth": 150}, {"field": "engine", "headerName": "Engine", "width": 100, "valueGetter": "InventoryEngineGetter"}, {"field": "type", "headerName": "Type", "width": 100}, {"field": "st", "headerName": "Status", "flex": 1.3, "minWidth": 130, "cellRenderer": "status"}, {"field": "sem", "headerName": "Sem", "width": 70}, {"field": "ai", "headerName": "AI", "width": 70}, {"field": "cat", "headerName": "Catalog", "width": 80}, {"field": "attrReg", "headerName": "Attrs", "flex": 1, "minWidth": 90, "valueGetter": "InventoryAttrRegGetter"}, {"field": "regBy", "headerName": "Registered By", "flex": 0.8, "minWidth": 100}, {"field": "regAt", "headerName": "Registered At", "flex": 1.2, "minWidth": 100, "valueFormatter": "InventoryRegAtFormatter"}, {"field": "action", "headerName": "Action", "width": 120, "cellRenderer": "status", "valueGetter": "InventoryActionGetter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'CATALOG_RULES_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1213, 1, 'SEMANTIC', 'GLOBAL', 'CATALOG_RULES_GRID', NULL, 'table', 'catalog_rules_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "catalog_rules", "title": "Catalog DQ Rules", "rowIdKey": "id", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "id", "headerName": "Rule ID", "flex": 0.7}, {"field": "name", "headerName": "Rule", "flex": 1.7}, {"field": "type", "headerName": "Type", "flex": 0.8}, {"field": "dimension", "headerName": "Dimension", "flex": 0.8}, {"field": "status", "headerName": "Status", "flex": 0.8}, {"field": "lastRun", "headerName": "Last execution", "flex": 1}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'CATALOG_RULE_MATRIX_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1214, 1, 'SEMANTIC', 'GLOBAL', 'CATALOG_RULE_MATRIX_GRID', NULL, 'table', 'catalog_rule_matrix_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "catalog_rule_matrix", "title": "Catalog DQ Matrix", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "cd", "headerName": "Attribute", "flex": 1.5}, {"field": "Completeness", "headerName": "Completeness", "flex": 1}, {"field": "Validity", "headerName": "Validity", "flex": 1}, {"field": "Uniqueness", "headerName": "Uniqueness", "flex": 1}, {"field": "Accuracy", "headerName": "Accuracy", "flex": 1}, {"field": "Consistency", "headerName": "Consistency", "flex": 1}, {"field": "Timeliness", "headerName": "Timeliness", "flex": 1}, {"field": "lastRun", "headerName": "Last run", "flex": 1}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_RELATIONSHIPS_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1215, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_RELATIONSHIPS_GRID', NULL, 'table', 'semantic_relationships_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_relationships", "title": "Relationships", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "cd", "headerName": "Relationship", "flex": 1, "cellRenderer": "RelationshipNameRenderer"}, {"field": "from", "headerName": "From Object", "flex": 1, "cellRenderer": "RelationshipFromObjRenderer"}, {"field": "from_col", "headerName": "FK Column", "flex": 1}, {"field": "to", "headerName": "To Object", "flex": 1, "cellRenderer": "RelationshipToObjRenderer"}, {"field": "to_col", "headerName": "PK Column", "flex": 1}, {"field": "type", "headerName": "Type", "width": 120}, {"field": "st", "headerName": "Status", "width": 100}, {"field": "action", "headerName": "Action", "width": 80, "cellRenderer": "RelationshipActionRenderer"}, {"field": "workflowId", "headerName": "Audit", "width": 70}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_FILTER_LOOKUP_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1216, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_FILTER_LOOKUP_GRID', NULL, 'table', 'semantic_filter_lookup_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_filter_lookups", "title": "Filter Lookups", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "cd", "headerName": "Lookup Code", "flex": 1.5}, {"field": "health.overallStatus", "headerName": "Health", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "constructionType", "headerName": "Type", "flex": 0.8, "cellRenderer": "FilterLookupTypeRenderer"}, {"field": "tenantCd", "headerName": "Tenant", "flex": 0.8, "cellRenderer": "FilterLookupTenantRenderer"}, {"field": "filterObj", "headerName": "Filter Object \u00b7 Condition", "flex": 2, "cellRenderer": "FilterLookupObjRenderer"}, {"field": "filterAttr", "headerName": "Filter Attr", "flex": 1}, {"field": "maxInputSetSize", "headerName": "Max Input", "flex": 0.8, "cellRenderer": "FilterLookupMaxInputRenderer"}, {"field": "maxOutputRows", "headerName": "Max Output", "flex": 0.8, "cellRenderer": "FilterLookupMaxOutputRenderer"}, {"field": "executionStrategy", "headerName": "Strategy", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "st", "headerName": "Status", "flex": 1, "cellRenderer": "status", "cellRendererParams": {"variant": "text"}}, {"field": "stats.lastExec", "headerName": "Last Exec", "flex": 1, "cellRenderer": "FilterLookupLastExecRenderer"}, {"field": "action", "headerName": "Action", "width": 150, "cellRenderer": "FilterLookupActionRenderer"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'SEMANTIC' AND node_code = 'GLOBAL' AND group_key = 'SEMANTIC_FILTER_LOOKUP_USAGE_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES
    (1217, 1, 'SEMANTIC', 'GLOBAL', 'SEMANTIC_FILTER_LOOKUP_USAGE_GRID', NULL, 'table', 'semantic_filter_lookup_usage_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig": {"gridId": "semantic_filter_lookup_usage", "title": "Filter Lookup Usage", "rowIdKey": "cd", "features": {"enableRowSelection": false, "enableGlobalSearch": true, "enableExport": true}, "columns": [{"field": "cd", "headerName": "Lookup", "flex": 1.5, "minWidth": 150}, {"field": "tenantCd", "headerName": "Tenant", "flex": 1, "minWidth": 100}, {"field": "stats.execLast30d", "headerName": "Executions", "flex": 1, "minWidth": 100}, {"field": "stats.avgPhase1Rows", "headerName": "Phase 1 avg", "flex": 1, "minWidth": 110}, {"field": "stats.avgPhase2Rows", "headerName": "Phase 2 avg", "flex": 1, "minWidth": 110}, {"field": "stats.cacheHitRate", "headerName": "Cache %", "flex": 1, "minWidth": 90}, {"field": "usedBy", "headerName": "Used by", "flex": 1.5, "minWidth": 120}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');

update meta.ui_elements_config 
set config_json = '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"variancePercentage","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"aiexplanation","dataType":"STRING","headerName":"","cellDataType":"text"}]}}'
where element_id = 1114;

update meta.ui_elements_config
set config_json = '{"gridConfig":{"gridId":"editcheck_breaks_summary","title":"Impacted Lines","rowIdKey":"line","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"line","headerName":"Line","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"pre","headerName":"Original","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"adjustment","headerName":"Adjustment","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"post","headerName":"After","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"ec_status","headerName":"EC Status","cellRenderer":"EditCheckStatusRenderer"}]}}'
where element_id = 1159;

update meta.ui_elements_config
set config_json = '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"variancePercentage","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"aiexplanation","dataType":"STRING","headerName":"","cellDataType":"text"}]}}'
where element_id = 1130;

update meta.ui_elements_config
set config_json = '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"variancePercentage","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"aiexplanation","dataType":"STRING","headerName":"","cellDataType":"text"}]}}'
where element_id = 1146;
-- DRILLDOWN UI ELEMENTS
DELETE FROM meta.ui_elements_config WHERE client_id = 1 AND module_name = 'DRILLDOWN' AND node_code = 'GLOBAL' AND group_key = 'DRILLDOWN_REPORT_GRID';
INSERT INTO meta.ui_elements_config (element_id, client_id, module_name, node_code, group_key, parent_id, element_key, translation_key, element_type, layout_type, order_index, is_required, config_json, dynamic_query, query_params, is_active, created_at, created_by, updated_at, updated_by) VALUES (1218, 1, 'DRILLDOWN', 'GLOBAL', 'DRILLDOWN_REPORT_GRID', NULL, 'table', 'drilldown_report_grid_key', 'GRID', 'INLINE', 1, TRUE, '{"gridConfig":{"gridId":"drilldown_report","title":"Drilldown Report","rowIdKey":"exec_id","features":{"enableRowSelection":false,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"client_id","headerName":"Client ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"exec_id","headerName":"Execution ID","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"rule_name","headerName":"Rule Name","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"period","headerName":"Period","dataType":"DATE","cellDataType":"date","filter":"agDateColumnFilter"},{"field":"restatement_version","headerName":"Restatement Version","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter"},{"field":"taxonomy_id","headerName":"Taxonomy ID","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"created_at","headerName":"Created At","dataType":"DATE","cellDataType":"date","filter":"agDateColumnFilter"},{"field":"updated_at","headerName":"Updated At","dataType":"DATE","cellDataType":"date","filter":"agDateColumnFilter"},{"field":"value_rpt","headerName":"Reported Value","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"value_num","headerName":"Numeric Value","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"value_str","headerName":"String Value","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"},{"field":"value_tsa","headerName":"TSA Value","dataType":"NUMBER","cellDataType":"number","filter":"agNumberColumnFilter","type":["numericColumn","rightIcons"],"headerClass":"text-right-header","cellClass":"ag-right-aligned-cell"},{"field":"prov_id","headerName":"Provider ID","dataType":"STRING","cellDataType":"text","filter":"agTextColumnFilter"}]}}', NULL, NULL, TRUE, now(), 'admin', now(), 'admin');


update meta.ui_elements_config
set config_json = '{"gridConfig":{"gridId":"variance","title":"variance","rowIdKey":"taxonomyId","features":{"enableRowSelection":true,"enableGlobalSearch":true,"enableExport":true},"columns":[{"field":"taxonomyName","headerName":"Taxonomy Name","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"currentAmount","headerName":"Current","displayType":"CURRENCY_STATIC","dataType":"NUMBER","cellDataType":"number","sortable":true,"filter":"agNumberColumnFilter"},{"field":"previousAmount","headerName":"Previous","dataType":"NUMBER","cellDataType":"number","displayType":"CURRENCY_STATIC","sortable":true,"filter":"agNumberColumnFilter"},{"field":"variancePercentage","headerName":"Δ / Change","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"varianceType","headerName":"Pattern | Variance Type","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agTextColumnFilter"},{"field":"risk","headerName":"Risk","dataType":"STRING","cellDataType":"text","sortable":true,"filter":"agSetColumnFilter","filterParams":{"values":["High","Medium","Low"]}},{"field":"aiexplanation","dataType":"STRING","headerName":"","cellDataType":"text"}]}}'
where element_id = 1138;