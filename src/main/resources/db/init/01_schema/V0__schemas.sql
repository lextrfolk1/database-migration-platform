
-- Create schemas in lextr DB

DROP SCHEMA meta CASCADE;
DROP SCHEMA data CASCADE;

-- Create Schemas --
CREATE SCHEMA IF NOT EXISTS meta
    AUTHORIZATION lextr_user;

ALTER SCHEMA meta OWNER TO lextr_user;

COMMENT ON SCHEMA meta IS 'Metadata tables';

CREATE SCHEMA IF NOT EXISTS data
    AUTHORIZATION lextr_user;
ALTER SCHEMA data OWNER TO lextr_user;
COMMENT ON SCHEMA data IS 'Data tables';


-- make sure schema's are created under lextr-user