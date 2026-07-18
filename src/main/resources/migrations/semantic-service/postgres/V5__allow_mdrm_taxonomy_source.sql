-- ck_attr_tax_source / ck_rld_tax_source only allowed REG_DEFINED/LEXTR_ASSIGNED, but the
-- taxonomy/jurisdiction_valid OPA policy (and its Java TaxonomyPolicyClient allow-list) has always
-- recognized MDRM as a third valid taxonomy_source_cd - the canonical USA regulatory-defined source.
-- Without this, no MDRM-sourced attribute could ever be registered, even though OPA would allow it.

ALTER TABLE meta.attribute_catalog DROP CONSTRAINT ck_attr_tax_source;
ALTER TABLE meta.attribute_catalog ADD CONSTRAINT ck_attr_tax_source CHECK (taxonomy_source_cd IS NULL OR taxonomy_source_cd IN
    ('REG_DEFINED', 'LEXTR_ASSIGNED', 'MDRM'));

ALTER TABLE report.report_line_definition DROP CONSTRAINT ck_rld_tax_source;
ALTER TABLE report.report_line_definition ADD CONSTRAINT ck_rld_tax_source CHECK (taxonomy_source_cd IS NULL OR taxonomy_source_cd IN
    ('REG_DEFINED', 'LEXTR_ASSIGNED', 'MDRM'));
