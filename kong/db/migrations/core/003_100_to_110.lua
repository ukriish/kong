return {
  postgres = {
    up = [[

      UPDATE consumers SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE plugins   SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE upstreams SET created_at = DATE_TRUNC('seconds', created_at);
      UPDATE targets   SET created_at = DATE_TRUNC('milliseconds', created_at);


      DROP FUNCTION IF EXISTS "upsert_ttl" (TEXT, UUID, TEXT, TEXT, TIMESTAMP WITHOUT TIME ZONE);

      CREATE TABLE IF NOT EXISTS "tags" (
        entity_id         UUID    PRIMARY KEY,
        entity_name       TEXT,
        tags              TEXT[]
      );

      CREATE INDEX IF NOT EXISTS tags_entity_name_idx ON tags(entity_name);
      CREATE INDEX IF NOT EXISTS tags_tags_idx ON tags USING GIN(tags);

      CREATE OR REPLACE FUNCTION sync_tags() RETURNS trigger AS $sync_tags$
        BEGIN
          IF (TG_OP = 'TRUNCATE') THEN
            DELETE FROM tags WHERE entity_name = TG_TABLE_NAME;
            RETURN NULL;
          ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM tags WHERE entity_id = OLD.id;
            RETURN OLD;
          ELSE

          -- Triggered by INSERT/UPDATE
          -- Do an upsert on the tags table
          -- So we don't need to migrate pre 1.1 entities
          INSERT INTO tags VALUES (NEW.id, TG_TABLE_NAME, NEW.tags)
          ON CONFLICT (entity_id) DO UPDATE
                  SET tags=EXCLUDED.tags;
          END IF;
          RETURN NEW;
        END;
      $sync_tags$ LANGUAGE plpgsql;

      DO $$
      BEGIN
        ALTER TABLE services ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS services_tags_idx ON services USING GIN(tags);

      DROP TRIGGER IF EXISTS services_sync_tags_trigger ON services;

      CREATE TRIGGER services_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON services
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS services_truncate_tags_trigger ON services;

      CREATE TRIGGER services_truncate_tags_trigger
      AFTER TRUNCATE ON services
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();

      DO $$
      BEGIN
        ALTER TABLE routes ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS routes_tags_idx ON routes USING GIN(tags);

      DROP TRIGGER IF EXISTS routes_sync_tags_trigger ON routes;

      CREATE TRIGGER routes_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON routes
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS routes_truncate_tags_trigger ON routes;

      CREATE TRIGGER routes_truncate_tags_trigger
      AFTER TRUNCATE ON routes
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE certificates ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS certificates_tags_idx ON certificates USING GIN(tags);

      DROP TRIGGER IF EXISTS certificates_sync_tags_trigger ON certificates;

      CREATE TRIGGER certificates_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON certificates
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS certificates_truncate_tags_trigger ON certificates;

      CREATE TRIGGER certificates_truncate_tags_trigger
      AFTER TRUNCATE ON certificates
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE snis ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS snis_tags_idx ON snis USING GIN(tags);

      DROP TRIGGER IF EXISTS snis_sync_tags_trigger ON snis;

      CREATE TRIGGER snis_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON snis
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS snis_truncate_tags_trigger ON snis;

      CREATE TRIGGER snis_truncate_tags_trigger
      AFTER TRUNCATE ON snis
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE consumers ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS consumers_tags_idx ON consumers USING GIN(tags);

      DROP TRIGGER IF EXISTS consumers_sync_tags_trigger ON consumers;

      CREATE TRIGGER consumers_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON consumers
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS consumers_truncate_tags_trigger ON consumers;

      CREATE TRIGGER consumers_truncate_tags_trigger
      AFTER TRUNCATE ON consumers
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE plugins ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS plugins_tags_idx ON plugins USING GIN(tags);

      DROP TRIGGER IF EXISTS plugins_sync_tags_trigger ON plugins;

      CREATE TRIGGER plugins_sync_tags_trigger
      AFTER INSERT OR UPDATE OR DELETE ON plugins
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS plugins_truncate_tags_trigger ON plugins;

      CREATE TRIGGER plugins_truncate_tags_trigger
      AFTER TRUNCATE ON plugins
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE upstreams ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS upstreams_tags_idx ON upstreams USING GIN(tags);

      DROP TRIGGER IF EXISTS upstreams_sync_tags_trigger ON upstreams;

      CREATE TRIGGER upstreams_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON upstreams
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS upstreams_truncate_tags_trigger ON upstreams;

      CREATE TRIGGER upstreams_truncate_tags_trigger
      AFTER TRUNCATE ON upstreams
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


      DO $$
      BEGIN
        ALTER TABLE targets ADD tags TEXT[];
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
      $$;

      CREATE INDEX IF NOT EXISTS targets_tags_idx ON targets USING GIN(tags);

      DROP TRIGGER IF EXISTS targets_sync_tags_trigger ON targets;

      CREATE TRIGGER targets_sync_tags_trigger
      AFTER INSERT OR UPDATE OF tags OR DELETE ON targets
      FOR EACH ROW
      EXECUTE PROCEDURE sync_tags();

      DROP TRIGGER IF EXISTS targets_truncate_tags_trigger ON targets;

      CREATE TRIGGER targets_truncate_tags_trigger
      AFTER TRUNCATE ON targets
      FOR EACH STATEMENT
      EXECUTE PROCEDURE sync_tags();


    ]],
  },

  cassandra = {
    up = [[
      ALTER TABLE services ADD tags set<text>;
      ALTER TABLE routes ADD tags set<text>;
      ALTER TABLE certificates ADD tags set<text>;
      ALTER TABLE snis ADD tags set<text>;
      ALTER TABLE consumers ADD tags set<text>;
      ALTER TABLE plugins ADD tags set<text>;
      ALTER TABLE upstreams ADD tags set<text>;
      ALTER TABLE targets ADD tags set<text>;

      CREATE TABLE IF NOT EXISTS tags (
        tag               text,
        entity_name       text,
        entity_id         text,
        other_tags        set<text>,
        PRIMARY KEY       ((tag), entity_name, entity_id)
      );
    ]],
  },
}