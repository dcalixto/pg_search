require "spec"
require "../src/pg_search"

class String
  def blank?
    empty?
  end
end

Spec.before_each do
  TestModel.db.exec "DROP TABLE IF EXISTS test_models"
  TestModel.db.exec <<-SQL
    CREATE TABLE test_models (
      id SERIAL PRIMARY KEY,
      title VARCHAR,
      body TEXT,
      created_at TIMESTAMP
    )
  SQL
end
