require "db"
require "pg"

class TestModel
  include PgSearch
  extend PgSearch::ClassMethods

  getter id : Int64
  getter title : String
  getter body : String

  def initialize(@id, @title, @body)
  end
end
