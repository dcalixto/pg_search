require "../src/pg_search"

describe PgSearch do
  it "performs a full-text search" do
    query = "example"
    results = PgSearch.search_by_text(query)
    expect(results).not_to be_empty
  end

  it "uses custom weights for ranking" do
    query = "example"
    weights = {"votes" => 3, "comments" => 2, "punches" => 1}
    results = PgSearch.search_by_text(query, weights)
    expect(results).not_to be_empty
  end
end
