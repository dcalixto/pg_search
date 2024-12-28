require "db"
require "pg"

class TestModel
  @@table_name : String = "test_models"
  @@db : DB::Database = DB.open(ENV["DATABASE_URL"])

  include DB::Serializable
  include PgSearch

  property id : Int64
  property title : String
  property body : String
  property created_at : Time

  def self.query_all(query : String)
    @@db.query_all(query, as: self)
  end

  searchable_columns [:title, :body]
end
