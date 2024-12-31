require "spec"
require "db"
require "pg"
require "../src/pg_search"

DB_URL = ENV["DATABASE_URL"]? || "postgres://postgres:postgres@localhost:5432/pg_search_test"

# Initial database setup
DB.open(DB_URL) do |db|
  db.exec <<-SQL
    CREATE TABLE IF NOT EXISTS test_models (
      id BIGSERIAL PRIMARY KEY,
      title VARCHAR(255),
      body TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    )
  SQL
end

Spec.before_each do
  DB.open(DB_URL) do |db|
    # Drop existing tables and views
    db.exec "DROP TABLE IF EXISTS test_models CASCADE"
    db.exec "DROP TABLE IF EXISTS votes CASCADE"
    db.exec "DROP MATERIALIZED VIEW IF EXISTS post_engagement_scores"

    # Create test_models table
    db.exec <<-SQL
      CREATE TABLE test_models (
        id BIGSERIAL PRIMARY KEY,
        title VARCHAR(255),
        body TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    SQL

    # Create votes table
    db.exec <<-SQL
      CREATE TABLE votes (
        id BIGSERIAL PRIMARY KEY,
        resource_id BIGINT,
        resource_type VARCHAR(255),
        positive BOOLEAN,
        negative BOOLEAN,
        value FLOAT8
      )
    SQL
    # Create materialized view with explicit FLOAT8 casting
    db.exec <<-SQL
      CREATE MATERIALIZED VIEW post_engagement_scores AS
      SELECT
        t.id,
        t.title,
        t.body,
        t.created_at,
        COALESCE(
          (SELECT SUM(
            CASE
              WHEN positive IS TRUE THEN 1.0
              WHEN negative IS TRUE THEN -1.0
              ELSE COALESCE(value, 0.0)
            END
          )::FLOAT8
          FROM votes
          WHERE resource_id = t.id),
          0.0
        )::FLOAT8 as engagement
      FROM test_models t
    SQL
    db.exec "CREATE UNIQUE INDEX ON post_engagement_scores (id)"
  end
end

class TestModel
  include DB::Serializable
  include PgSearch

  def self.refresh_engagement_scores
    db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"
  end
end

class TestModel
  include DB::Serializable
  include PgSearch

  @@db : DB::Database? = nil

  def self.db
    @@db ||= DB.open(DB_URL)
  end

  property id : Int64?
  property title : String
  property body : String
  property created_at : Time = Time.utc
  property engagement : Float64 = 0.0

  def initialize(@title : String, @body : String)
  end

  searchable_columns [:title, :body]

  def self.search(query : String)
    return [] of TestModel if query.blank?

    sql = <<-SQL
      SELECT
        t.id,
        t.title,
        t.body,
        t.created_at,
        COALESCE(pes.engagement, 0.0)::FLOAT8 as engagement
      FROM test_models t
      LEFT JOIN post_engagement_scores pes ON pes.id = t.id
      WHERE
        t.title ILIKE $1 OR
        t.body ILIKE $1
      ORDER BY pes.engagement DESC, t.created_at DESC
    SQL

    db.query_all(sql, "%#{query}%", as: TestModel)
  end

  def self.refresh_engagement_scores
    db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"
  end
end

Spec.after_each do
  DB.open(DB_URL) do |db|
    # No need to drop the materialized view here, CASCADE handles it
    db.exec "DROP TABLE IF EXISTS test_models CASCADE"
  end
end
