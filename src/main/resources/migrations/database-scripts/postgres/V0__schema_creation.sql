-- Description: This script creates the role, database, and schemas.

-- Role and Database creation (Handled during initial DBA setup / bootstrap)
-- CREATE ROLE lextr_user
--     WITH LOGIN
--     SUPERUSER
--     CREATEDB
--     CREATEROLE
--     INHERIT
--     NOREPLICATION
--     BYPASSRLS
--     CONNECTION LIMIT -1
--     PASSWORD 'Mygooru1028$';
--
-- COMMENT ON ROLE lextr_user IS 'Lextr User';
--
-- CREATE DATABASE lextr
--     WITH OWNER = lextr_user
--     ENCODING = 'UTF8'
--     LOCALE_PROVIDER = 'libc'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

-- Create Schemas --
-- make sure schema's are created with lextr DB and lextr-user
CREATE SCHEMA IF NOT EXISTS meta
    AUTHORIZATION lextr_user;

ALTER SCHEMA meta OWNER TO lextr_user;

COMMENT ON SCHEMA meta IS 'Metadata tables';

CREATE SCHEMA IF NOT EXISTS data
    AUTHORIZATION lextr_user;

ALTER SCHEMA data OWNER TO lextr_user;
COMMENT ON SCHEMA data IS 'Data tables';

CREATE SCHEMA IF NOT EXISTS adhoc
    AUTHORIZATION lextr_user;

ALTER SCHEMA adhoc OWNER TO lextr_user;
COMMENT ON SCHEMA adhoc IS 'Adhoc reporting temp tables';


CREATE SCHEMA IF NOT EXISTS ai
    AUTHORIZATION lextr_user;

ALTER SCHEMA ai OWNER TO lextr_user;
COMMENT ON SCHEMA ai IS 'Schema for Lextr AI related tables';


