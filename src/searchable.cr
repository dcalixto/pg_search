module Searchable
  def self.text_search(query : String)
    sanitized_query = query.gsub("'", "''") # Prevent SQL injection
    <<-SQL
      SELECT posts.*, (
        ts_rank(to_tsvector('english', COALESCE(title, '')), plainto_tsquery('#{sanitized_query}')) +
        ts_rank(to_tsvector('english', COALESCE(body, '')), plainto_tsquery('#{sanitized_query}'))
      ) AS search_rank
      FROM posts
      WHERE to_tsvector('english', COALESCE(title, '')) @@ plainto_tsquery('#{sanitized_query}') OR
            to_tsvector('english', COALESCE(body, '')) @@ plainto_tsquery('#{sanitized_query}')
      ORDER BY search_rank DESC
    SQL
  end
end
