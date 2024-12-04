# pg_search

PgSearch is a flexible full-text search and ranking shard for Crystal, leveraging PostgreSQL's to_tsvector and ts_rank for high-performance searches. It includes support for dynamic ranking based on user-defined weights for votes, comments, and other engagement metrics.

**Features**

- Full-text search using PostgreSQL.
- Dynamic ranking based on engagement (votes, comments, punches, etc.).
- Configurable weights for ranking factors.
- Easy integration with any Crystal application.

## Installation

Add the shard to your `shard.yml`:

```yaml
dependencies:
pg_search:
github: dcalixto/pg_search
version: ~> 0.1.0
```

Then, run shards install.

## Configuration

Database Setup
Ensure your database is set up with PostgreSQL. Update your database connection in the app to match your environment:

```crystal

require "pg"
DB.open("postgres://username:password@localhost/db_name")
```

## Usage

1. Full-Text Search
   PgSearch provides a search_by_text method to perform a full-text search on a PostgreSQL table. Include PgSearch in your model to use it.

```crystal
require "pg_search"

class Post
include PgSearch
end

## Perform a full-text search

results = Post.search_by_text("example query")
results.each do |post|
puts "Post Title: #{post.title}, Score: #{post.ranking_score}"
end
```

2. Custom Ranking
   Pass custom weights for ranking factors like votes, comments, and punches:

```crystal

weights = {"votes" => 3, "comments" => 2, "punches" => 1}
results = Post.search_by_text("example query", weights) 3. Search with Time Range
```

Use the SearchService to combine full-text search with time-based filtering and ranking:

Example:

```crystal
require "pg_search/services/search_service"

## Search for posts created within the last 7 days

results = SearchService.search_with_ranking("example query", "7_days")
results.each do |post|
puts "Post Title: #{post.title}, Ranking Score: #{post.ranking_score}"
end
```

Time range options:

- "1_hour"
- "24_hours"
- "7_days"
- "30_days" 4. Flexible Table and Columns

Override the default table name (posts) or searchable columns (title, body) by passing additional parameters:

```crystal
results = PgSearch.search_by_text(
"example query",
{"votes" => 2, "comments" => 1},
table_name: "articles",
searchable_columns: ["headline", "content"]
)
```

## Testing

Run the included specs to verify functionality:

```crystal
crystal spec
```

## Contributing

1. Fork this repository.
2. Create a feature branch (git checkout -b feature/my-feature).
3. Commit your changes (git commit -am 'Add my feature').
4. Push to the branch (git push origin feature/my-feature).
5. Create a Pull Request.

## License

This shard is open-sourced under the MIT License.
