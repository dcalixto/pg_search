require "./scoring/scorable"

module PgSearch
  macro included
    extend ClassMethods

    macro searchable_columns(columns)
      def self.search(query : String)
        if query.blank?
          sql = <<-SQL
            WITH scored_posts AS (
              SELECT *,
              #{Scorable.calculate_engagement_score} as engagement_score
              FROM #{table_name}
              WHERE created_at > $1
            )
            SELECT *, engagement_score FROM scored_posts
            ORDER BY engagement_score DESC, created_at DESC
          SQL
          # db.query_all(sql, Time.utc - 24.hours, as: self)
          db.query_all(sql, Time.utc - 30.days, as: self)
        else
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
  end

  module ClassMethods
  end
end
