/* sql script to fix issues in notary tables after migrate mysql to postgress.
  There are two migrators, one is harbor-db-migrator, another is container build-in migration tools.
  When upgrade 1.5.0 to 1.6.0, the harbor-db-migrator migrate database table from mysql to pgsql, there is a bug between 1.6.0 to 1.6.3, it cause table owner is postgres.
  When 1.6.0 container starts, the notary container build-in migration tools trys to migrate and fails, the dirty column is not created because tables owner is not signer/server
  use the condition dirty column in table schema_migrations to check if it is need to update databse table, if it exit, means the migration is success, if not exist, means the migration fails.
*/

\c notarysigner;
DO $$
BEGIN
    IF not exists(select column_name FROM information_schema.columns WHERE table_name = 'schema_migrations' AND column_name = 'dirty') then
        ALTER TABLE private_keys OWNER TO signer;
        ALTER SEQUENCE private_keys_id_seq OWNER TO signer;
        ALTER TABLE schema_migrations OWNER TO signer;
        DELETE FROM schema_migrations WHERE version > 1;
    END IF;
END $$;
\c notaryserver;
SELECT setval('changefeed_id_seq', max(id)) FROM changefeed;
DO $$
BEGIN
    IF not exists(select column_name FROM information_schema.columns WHERE table_name = 'schema_migrations' AND column_name = 'dirty') then
        ALTER TABLE tuf_files OWNER TO server;
        ALTER SEQUENCE tuf_files_id_seq OWNER TO server;
        ALTER TABLE change_category OWNER TO server;
        ALTER TABLE changefeed OWNER TO server;
        ALTER SEQUENCE changefeed_id_seq OWNER TO server;
        ALTER TABLE schema_migrations OWNER TO server;
        DELETE FROM schema_migrations WHERE version > 2;
        ALTER TABLE "changefeed" ALTER COLUMN "id" SET default nextval('changefeed_id_seq');
    END IF;
END $$;


