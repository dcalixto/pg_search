require "./spec_helper"
require "./support/test_model"

describe PgSearch do
  describe ".search" do
    it "returns empty array for blank search" do
      results = TestModel.search("")
      results.empty?.should be_true
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
