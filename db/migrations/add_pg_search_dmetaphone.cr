class AddPgSearchDmetaphone < DB::Migration
  def up
    execute <<-SQL
      CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
      
      CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text AS $$
      BEGIN
        RETURN dmetaphone($1);
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS pg_search_dmetaphone(text);
    SQL
  end
end
