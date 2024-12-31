require "./spec_helper"

describe PgSearch do
  before_each do
    TestModel.db.exec "DROP TABLE IF EXISTS test_models CASCADE"
    TestModel.db.exec "DROP TABLE IF EXISTS post_engagement_scores CASCADE"
    TestModel.db.exec "DROP TABLE IF EXISTS votes CASCADE"
    TestModel.db.exec "DROP MATERIALIZED VIEW IF EXISTS post_engagement_scores"

    TestModel.db.exec "CREATE TABLE test_models (id BIGSERIAL PRIMARY KEY, title VARCHAR(255), body TEXT, created_at TIMESTAMP DEFAULT NOW())"
    TestModel.db.exec "CREATE MATERIALIZED VIEW post_engagement_scores AS SELECT id, title, body, created_at, 0 as engagement FROM test_models"
    TestModel.db.exec "CREATE TABLE votes (id BIGSERIAL PRIMARY KEY, resource_id BIGINT, resource_type VARCHAR(255), positive BOOLEAN, negative BOOLEAN, value INTEGER)"
  end

  describe ".calculate_engagement_score" do
    it "returns 0 when no votes exist" do
      score = TestModel.calculate_engagement_score(1_i64)
      score.should eq(0)
    end

    it "calculates positive votes correctly" do
      TestModel.db.exec "INSERT INTO votes (resource_id, resource_type, positive, negative, value) VALUES (1, 'test_models', true, false, null)"
      score = TestModel.calculate_engagement_score(1_i64)
      score.should eq(1)
    end

    it "calculates negative votes correctly" do
      TestModel.db.exec "INSERT INTO votes (resource_id, resource_type, positive, negative, value) VALUES (1, 'test_models', false, true, null)"
      score = TestModel.calculate_engagement_score(1_i64)
      score.should eq(-1)
    end

    it "sums multiple vote types correctly" do
      TestModel.db.exec "INSERT INTO votes (resource_id, resource_type, positive, negative, value) VALUES (1, 'test_models', true, false, null)"
      TestModel.db.exec "INSERT INTO votes (resource_id, resource_type, positive, negative, value) VALUES (1, 'test_models', false, true, null)"
      TestModel.db.exec "INSERT INTO votes (resource_id, resource_type, positive, negative, value) VALUES (1, 'test_models', null, null, 5)"
      score = TestModel.calculate_engagement_score(1_i64)
      score.should eq(5)
    end
  end

  describe ".search" do
    it "returns empty array for blank query" do
      results = TestModel.search("")
      results.should be_empty
    end

    it "performs case-insensitive search" do
      model = TestModel.new(title: "Test Title", body: "Test Body")
      DB.open(DB_URL) do |db|
        db.exec "INSERT INTO test_models (title, body) VALUES ($1, $2)", model.title, model.body
        db.exec "INSERT INTO votes (resource_id, positive, value) VALUES (1, true, 1.0)"
      end

      TestModel.refresh_engagement_scores

      results = TestModel.search("test")
      results.size.should eq(1)
      results.first.title.should eq("Test Title")
      results.first.engagement.should be_a(Float64)
    end

    it "orders results by engagement and creation date" do
      TestModel.db.exec "INSERT INTO test_models (title, body) VALUES ('First Post', 'First post content')"
      TestModel.db.exec "INSERT INTO test_models (title, body) VALUES ('Second Post', 'Second post content')"
      TestModel.db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"

      TestModel.db.exec "DROP MATERIALIZED VIEW post_engagement_scores"
      TestModel.db.exec "CREATE MATERIALIZED VIEW post_engagement_scores AS
        SELECT t.id, t.title, t.body, t.created_at,
        CAST(CASE WHEN t.title = 'Second Post' THEN 10 ELSE 0 END AS FLOAT8) as engagement
        FROM test_models t"

      results = TestModel.search("Post")
      results.size.should eq(2)
      results.first.title.should eq("Second Post")
    end
  end
end
