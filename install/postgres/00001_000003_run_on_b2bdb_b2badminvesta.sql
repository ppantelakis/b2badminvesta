CREATE ROLE b2badminvesta SUPERUSER NOINHERIT VALID UNTIL 'infinity';
ALTER ROLE b2badminvesta SUPERUSER CREATEDB CREATEROLE NOINHERIT LOGIN;
CREATE SCHEMA IF NOT EXISTS b2badminvestaschema;
ALTER SCHEMA b2badminvestaschema OWNER TO b2badminvesta;
ALTER ROLE b2badminvesta SET search_path TO b2badminvestaschema,pg_catalog,public;
GRANT  USAGE ON SCHEMA public  TO b2badminvesta;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO b2badminvesta;
GRANT CONNECT ON DATABASE b2bdb TO b2badminvesta;