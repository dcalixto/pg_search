module PgSearch
  macro included
    extend ClassMethods
  end

  module ClassMethods
    def search(query : String)
      return [] of self if query.blank?

      sanitized_query = query.gsub("'", "''")
      sql = <<-SQL
        SELECT *, (
          ts_rank(to_tsvector('english', COALESCE(title, '')), plainto_tsquery('#{sanitized_query}')) +
          ts_rank(to_tsvector('english', COALESCE(body, '')), plainto_tsquery('#{sanitized_query}'))
        ) AS search_rank
        FROM posts
        WHERE to_tsvector('english', COALESCE(title, '')) @@ plainto_tsquery('#{sanitized_query}') OR
              to_tsvector('english', COALESCE(body, '')) @@ plainto_tsquery('#{sanitized_query}'))
        ORDER BY search_rank DESC
      SQL

      db.query_all(sql, as: self)
    end
  end
end
