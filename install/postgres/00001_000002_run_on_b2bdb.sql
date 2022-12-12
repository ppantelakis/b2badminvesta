CREATE EXTENSION IF NOT EXISTS hstore;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE EXTENSION IF NOT EXISTS dblink;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE EXTENSION IF NOT EXISTS file_fdw;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

CREATE OR REPLACE FUNCTION public.b2badmin_first (my_schemaname text, my_username text, my_userpass text, my_createschema numeric)
    RETURNS integer
    LANGUAGE plpgsql
    AS $function$
DECLARE
    crmtables CURSOR FOR
        SELECT
            *
        FROM (
            SELECT
                count(*) myorder,
                n1.nspname schemaname,
                cl1.relname tablename
            FROM
                pg_constraint AS co
                JOIN pg_class AS cl1 ON co.conrelid = cl1.oid
                JOIN pg_class AS cl2 ON co.confrelid = cl2.oid
                JOIN pg_catalog.pg_namespace n1 ON n1.oid = cl1.relnamespace
                JOIN pg_catalog.pg_namespace n2 ON n2.oid = cl2.relnamespace
            WHERE
                co.contype = 'f'
                AND n1.nspname = my_schemaname
                AND cl1.relname LIKE 'core_crm%'
            GROUP BY
                cl1.relname,
                n1.nspname) a
    ORDER BY
        myorder ASC;
    erptables CURSOR FOR
        SELECT
            *
        FROM (
            SELECT
                count(*) myorder,
                n1.nspname schemaname,
                cl1.relname tablename
            FROM
                pg_constraint AS co
                JOIN pg_class AS cl1 ON co.conrelid = cl1.oid
                JOIN pg_class AS cl2 ON co.confrelid = cl2.oid
                JOIN pg_catalog.pg_namespace n1 ON n1.oid = cl1.relnamespace
                JOIN pg_catalog.pg_namespace n2 ON n2.oid = cl2.relnamespace
            WHERE
                co.contype = 'f'
                AND n1.nspname = my_schemaname
                AND cl1.relname LIKE 'core_erp%'
            GROUP BY
                cl1.relname,
                n1.nspname) a
    ORDER BY
        myorder ASC;
    tables CURSOR FOR
        SELECT
            schemaname,
            tablename
        FROM
            pg_tables
        WHERE
            schemaname = my_schemaname;
    table_constraints CURSOR FOR
        SELECT
            table_schema,
            TABLE_NAME,
            CONSTRAINT_NAME
        FROM
            information_schema.constraint_table_usage
        WHERE
            table_schema = my_schemaname;
    qrytxt text;
    my_views CURSOR FOR
        SELECT
            table_schema,
            TABLE_NAME
        FROM
            information_schema.views
        WHERE
            table_schema = my_schemaname;
BEGIN
    qrytxt := 'CREATE ROLE ' || my_username || ' LOGIN PASSWORD ''' || my_userpass || ''' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION';
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    qrytxt := 'ALTER USER ' || my_username || ' WITH PASSWORD ''' || my_userpass || '''';
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    IF my_createschema = 1 THEN
        qrytxt := 'DROP SCHEMA IF EXISTS ' || my_schemaname || ' CASCADE';
        BEGIN
            EXECUTE qrytxt;
        EXCEPTION
            WHEN OTHERS THEN
                FOR table_record IN table_constraints LOOP
                    BEGIN
                        EXECUTE 'ALTER TABLE ' || quote_ident(table_record.table_schema) || '.' || quote_ident(table_record. TABLE_NAME) || ' DROP CONSTRAINT ' || quote_ident(table_record. CONSTRAINT_NAME) || ' cascade';
                    EXCEPTION
                        WHEN OTHERS THEN
                    END;
                END LOOP;
            FOR table_record IN tables LOOP
                BEGIN
                    EXECUTE 'ALTER TABLE ' || table_record.schemaname || '.' || table_record.tablename || ' NO INHERIT ' || table_record.schemaname || '.mitra_mitrapk';
                EXCEPTION
                    WHEN OTHERS THEN
                END;
            END LOOP;
            FOR view_record IN my_views LOOP
                BEGIN
                    EXECUTE 'drop view ' || view_record.schemaname || '.' || view_record.tablename || ' cascade';
                EXCEPTION
                    WHEN OTHERS THEN
                END;
            END LOOP;
            FOR table_record IN crmtables LOOP
                BEGIN
                    EXECUTE 'drop table ' || table_record.schemaname || '.' || table_record.tablename || ' cascade';
                EXCEPTION
                    WHEN OTHERS THEN
                END;
            END LOOP;
            FOR table_record IN erptables LOOP
                BEGIN
                    EXECUTE 'drop table ' || table_record.schemaname || '.' || table_record.tablename || ' cascade';
                EXCEPTION
                    WHEN OTHERS THEN
                END;
            END LOOP;
            FOR table_record IN tables LOOP
                BEGIN
                    EXECUTE 'drop table ' || table_record.schemaname || '.' || table_record.tablename || ' cascade';
                EXCEPTION
                    WHEN OTHERS THEN
                END;
            END LOOP;
            qrytxt := 'DROP SCHEMA IF EXISTS ' || my_schemaname || ' CASCADE';
            BEGIN
                EXECUTE qrytxt;
            EXCEPTION
                WHEN OTHERS THEN
            END;
        END;
    END IF;
    qrytxt := 'CREATE SCHEMA IF NOT EXISTS ' || my_schemaname;
    --RAISE NOTICE 'qrytxt %', qrytxt;
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    qrytxt := 'ALTER SCHEMA ' || my_schemaname || ' OWNER TO ' || my_username;
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    qrytxt := 'ALTER ROLE ' || my_username || ' SET search_path TO ' || my_schemaname || ',pg_catalog,public';
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    qrytxt := 'GRANT  USAGE ON SCHEMA public  TO ' || my_username;
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    qrytxt := 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO ' || my_username;
    BEGIN
        EXECUTE qrytxt;
    EXCEPTION
        WHEN OTHERS THEN
    END;
    RETURN 1;
END
$function$;

-- Permissions
ALTER FUNCTION public.b2badmin_first (text, text, text, numeric) OWNER TO b2badminvesta;

GRANT ALL ON FUNCTION public.b2badmin_first (text, text, text, numeric) TO b2badminvesta;

