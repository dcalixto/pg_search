require "db"
require "pg"

class TestModel
  include PgSearch
  include DB::Serializable

  @@db : DB::Database = DB.open("postgres://postgres:postgres@localhost:5432/test_db")
  property id : Int32?
  property title : String
  property body : String
  property created_at : Time

  def self.table_name
    "test_models"
  end

  def self.db
    @@db
  end

  searchable_columns [:title, :body]

  def initialize(@title, @body, @created_at = Time.utc)
    @id = nil
    save
  end

  def save
    result = self.class.db.exec(
      "INSERT INTO test_models (title, body, created_at) VALUES ($1, $2, $3) RETURNING id",
      @title, @body, @created_at
    )
    @id = result.last_insert_id.to_i32
  end
end
