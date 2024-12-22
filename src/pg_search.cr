module PgSearch
  macro included
    extend ClassMethods

    macro searchable_columns(columns)
      def self.search(query : String)
        return self.none if query.blank?

        sanitized_query = query.gsub("'", "''")
        sql = <<-SQL
          SELECT *, (
            ts_rank(to_tsvector('english', COALESCE(title, '')), plainto_tsquery('#{sanitized_query}')) +
            ts_rank(to_tsvector('english', COALESCE(body, '')), plainto_tsquery('#{sanitized_query}'))
          ) AS search_rank
          FROM #{table_name}
          WHERE to_tsvector('english', COALESCE(title, '')) @@ plainto_tsquery('#{sanitized_query}') OR
                to_tsvector('english', COALESCE(body, '')) @@ plainto_tsquery('#{sanitized_query}')
          ORDER BY search_rank DESC
        SQL

        query(sql)
      end
    end
  end

  module ClassMethods
  end
end
