
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