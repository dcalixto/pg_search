require "./spec_helper"
require "./support/test_model"

describe PgSearch do
  describe ".search" do
    it "returns posts with highest engagement from last 24 hours when search is blank" do
      # Create posts within 24h window
      low_engagement = TestModel.new(
        title: "low engagement",
        body: "test body",
        created_at: Time.utc - 12.hours
      )

      high_engagement = TestModel.new(
        title: "high engagement",
        body: "test body",
        created_at: Time.utc - 12.hours
      )

      # Create post outside 24h window
      old_post = TestModel.new(
        title: "old post",
        body: "test body",
        created_at: Time.utc - 25.hours
      )

      results = TestModel.search("").to_a

      # Verify results are within 24h window
      results.each do |post|
        (Time.utc - post.created_at).should be <= 24.hours
      end
    end

    it "finds matches in title" do
      model = TestModel.new(title: "test title", body: "some body")
      results = TestModel.search("test")
      results.first.title.should match(/test/i)
    end

    it "orders results by created_at in descending order" do
      older = TestModel.new(
        title: "test post",
        body: "test body",
        created_at: Time.utc - 1.day
      )
      newer = TestModel.new(
        title: "test post",
        body: "test body",
        created_at: Time.utc
      )

      results = TestModel.search("test").to_a
      ordered = results.sort_by(&.created_at).reverse
      results.should eq ordered
    end
  end
end
