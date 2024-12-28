require "./spec_helper"

describe PgSearch do
  before_each do
    # Drop tables
    TestModel.db.exec "DROP TABLE IF EXISTS test_models CASCADE"
    TestModel.db.exec "DROP TABLE IF EXISTS punches CASCADE"
    TestModel.db.exec "DROP TABLE IF EXISTS votes CASCADE"
    TestModel.db.exec "DROP TABLE IF EXISTS comments CASCADE"

    # Create test_models table
    TestModel.db.exec "CREATE TABLE test_models (id BIGSERIAL PRIMARY KEY, title VARCHAR(255), body TEXT, created_at TIMESTAMP DEFAULT NOW())"

    # Create punches table
    TestModel.db.exec "CREATE TABLE punches (id BIGSERIAL PRIMARY KEY, punchable_id BIGINT, punchable_type VARCHAR(255), created_at TIMESTAMP DEFAULT NOW())"

    # Create votes table
    TestModel.db.exec "CREATE TABLE votes (id BIGSERIAL PRIMARY KEY, resource_id BIGINT, resource_type VARCHAR(255), positive INTEGER DEFAULT 0, negative INTEGER DEFAULT 0)"

    # Create comments table
    TestModel.db.exec "CREATE TABLE comments (id BIGSERIAL PRIMARY KEY, commentable_id BIGINT, commentable_type VARCHAR(255))"
  end

  describe ".search with engagement" do
    it "calculates engagement scores correctly" do
      # Insert test data
      TestModel.db.exec(
        "INSERT INTO test_models (title, body) VALUES ($1, $2)",
        "Engaging Post",
        "Popular content"
      )

      # Add engagement data
      TestModel.db.exec(
        "INSERT INTO punches (punchable_id, punchable_type) VALUES (1, 'test_models')"
      )

      TestModel.db.exec(
        "INSERT INTO votes (resource_id, resource_type, positive) VALUES (1, 'test_models', 5)"
      )

      results = TestModel.search("Engaging")
      results.size.should eq(1)
      results.first.title.should eq("Engaging Post")
    end
  end
end
