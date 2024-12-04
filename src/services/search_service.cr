require "../query_builders/ranking"
require "../scoring/scorable"
require "../pg_search"

class SearchService
  def self.search_with_ranking(query : String, time_range : String? = nil, weights : Hash(String, Int32)? = nil)
    time_condition = case time_range
                     when "1_hour"
                       "AND created_at >= NOW() - INTERVAL '1 hour'"
                     when "24_hours"
                       "AND created_at >= NOW() - INTERVAL '24 hours'"
                     when "7_days"
                       "AND created_at >= NOW() - INTERVAL '7 days'"
                     when "30_days"
                       "AND created_at >= NOW() - INTERVAL '30 days'"
                     else
                       ""
                     end

    ranking_query = QueryBuilders::Ranking.build_ranking_query(weights || {"votes" => 2, "comments" => 1, "punches" => 1})

    base_query = <<-SQL
      SELECT posts.*, (
        #{ranking_query}
      ) AS ranking_score
      FROM posts
      WHERE to_tsvector('english', title || ' ' || body) @@ plainto_tsquery(?)
      #{time_condition}
      ORDER BY ranking_score DESC
    SQL

    # Execute the query using the database connection
    db.query_all(base_query, query, as: Post)
  end
end
