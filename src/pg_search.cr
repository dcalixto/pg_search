module PgSearch
  macro included
    macro searchable_columns(columns)
      def self.search(query : String)
        return [] of self if query.blank?
        
        sanitized_query = query.gsub("'", "''")
        columns_query = {{columns}}.map do |column|
          "to_tsvector('english', COALESCE(#{column}, '')) @@ plainto_tsquery('#{sanitized_query}')"
        end.join(" OR ")

        rank_expression = {{columns}}.map do |column|
          "ts_rank(to_tsvector('english', COALESCE(#{column}, '')), plainto_tsquery('#{sanitized_query}'))"
        end.join(" + ")

        sql = <<-SQL
          SELECT *, (#{rank_expression}) AS search_rank 
          FROM #{table_name}
          WHERE #{columns_query}
          ORDER BY search_rank DESC
        SQL

        db.query_all(sql, as: self)
      end
    end
  end
end
