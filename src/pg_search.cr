module PgSearch
  macro included
    def self.search_by_text(
      query : String,
      weights : Hash(String, Int32)? = nil,
      table_name : String = "posts",
      searchable_columns : Array(String) = ["title", "body"],
      db = DB.open("your_database_url")
    )
      columns = searchable_columns.join(" || ' ' || ")
      base_query = <<-SQL
        SELECT #{table_name}.*,
          (
            ts_rank(to_tsvector('english', #{columns}), plainto_tsquery(?)) +
            COALESCE(
              (SELECT COUNT(*) FROM votes WHERE votes.resource_type = '#{table_name.singularize.capitalize}' AND votes.resource_id = #{table_name}.id) * COALESCE(?, 1),
              0
            ) +
            COALESCE(
              (SELECT COUNT(*) FROM comments WHERE comments.commentable_type = '#{table_name.singularize.capitalize}' AND comments.commentable_id = #{table_name}.id) * COALESCE(?, 1),
              0
            ) +
            COALESCE(
              (SELECT SUM(hits) FROM punches WHERE punches.punchable_type = '#{table_name.singularize.capitalize}' AND punches.punchable_id = #{table_name}.id) * COALESCE(?, 1),
              0
            )
          ) AS ranking_score
        FROM #{table_name}
        WHERE to_tsvector('english', #{columns}) @@ plainto_tsquery(?)
        ORDER BY ranking_score DESC
      SQL

      weights ||= {"votes" => 2, "comments" => 1, "punches" => 1}
      db.query_all(base_query, query, weights["votes"], weights["comments"], weights["punches"], query, as: Post)
    end
  end
end
