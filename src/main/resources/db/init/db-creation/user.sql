-- Description: This script creates the role, database, and schemas.
-- this script will not be executed using migrator

-- Create Role --
CREATE ROLE lextr_user
    WITH LOGIN
    SUPERUSER
    CREATEDB
    CREATEROLE
    INHERIT
    NOREPLICATION
    BYPASSRLS
    CONNECTION LIMIT -1
    PASSWORD 'admin';

COMMENT ON ROLE lextr_user IS 'Lextr User';

-- Create Database --
CREATE DATABASE lextr
    WITH OWNER = lextr_user
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;