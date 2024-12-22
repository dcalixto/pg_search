module PgSearch
  macro included
    extend ClassMethods

    macro searchable_columns(columns)
      def self.search(query : String)
        return [] of self if query.blank?

        sanitized_query = query.gsub("'", "''")
        sql = <<-SQL
          SELECT * FROM #{table_name}
          WHERE to_tsvector('english', COALESCE(title, '')) @@ plainto_tsquery($1) OR
                to_tsvector('english', COALESCE(body, '')) @@ plainto_tsquery($1)
          ORDER BY 
            ts_rank(to_tsvector('english', COALESCE(title, '')), plainto_tsquery($1)) +
            ts_rank(to_tsvector('english', COALESCE(body, '')), plainto_tsquery($1)) DESC
        SQL

        db.query_all(sql, sanitized_query, as: self)
      end
    end
  end

  module ClassMethods
  end
end
