module PgSearch
  macro included
    extend ClassMethods

    macro searchable_columns(columns)
      def self.search(query : String)
        return [] of self if query.blank?

        sanitized_query = query.gsub("'", "''")
        sql = <<-SQL
          SELECT * FROM #{table_name}
          WHERE title ILIKE $1 OR body ILIKE $1
          ORDER BY 
            CASE 
              WHEN title ILIKE $1 THEN 2
              WHEN body ILIKE $1 THEN 1
              ELSE 0
            END DESC,
            created_at DESC
        SQL

        db.query_all(sql, "%#{sanitized_query}%", as: self)
      end
    end
  end

  module ClassMethods
  end
end
