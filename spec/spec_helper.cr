require "spec"
require "db"
require "pg"
require "../src/pg_search"

DB_URL = "postgres://postgres:postgres@localhost/pg_search_test"

Spec.before_each do
  DB.open(DB_URL) do |db|
    # First terminate all other connections to allow schema drop
    db.exec "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid()"

    # Now we can safely drop and recreate the schema
    db.exec "DROP SCHEMA public CASCADE"
    db.exec "CREATE SCHEMA public"
    db.exec "GRANT ALL ON SCHEMA public TO postgres"
    db.exec "GRANT ALL ON SCHEMA public TO public"

    # Create tables in the fresh schema
    db.exec "CREATE TABLE test_models (id BIGSERIAL PRIMARY KEY, title VARCHAR(255), body TEXT, created_at TIMESTAMP DEFAULT NOW())"
    db.exec "CREATE TABLE punches (id BIGSERIAL PRIMARY KEY, punchable_id BIGINT, punchable_type VARCHAR(255), created_at TIMESTAMP DEFAULT NOW())"
    db.exec "CREATE TABLE votes (id BIGSERIAL PRIMARY KEY, resource_id BIGINT, resource_type VARCHAR(255), positive INTEGER DEFAULT 0, negative INTEGER DEFAULT 0)"
    db.exec "CREATE TABLE comments (id BIGSERIAL PRIMARY KEY, commentable_id BIGINT, commentable_type VARCHAR(255))"
  end
end

class TestModel
  include DB::Serializable
  include PgSearch

  @@db : DB::Database? = nil

  def self.db : DB::Database
    @@db ||= DB.open(DB_URL)
  end

  property id : Int64?
  property title : String
  property body : String
  property created_at : Time = Time.utc
  property total_comments : Int64 = 0
  property total_replies : Int64 = 0
  property engagement : Float64 = 0.0

  def initialize(@title : String, @body : String)
  end

  def self.table_name
    "test_models"
  end

  searchable_columns [:title, :body]

  def self.table_name
    "test_models"
  end

  searchable_columns [:title, :body]
end

Spec.after_each do
  TestModel.db.exec "DROP TABLE IF EXISTS test_models"
end
