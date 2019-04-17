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


