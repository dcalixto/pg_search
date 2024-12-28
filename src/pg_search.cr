module PgSearch
  macro included
    def self.query(sql)
      DB.connect(DB_URL) do |db|
        db.exec(sql)
      end
    end

    def self.query_all(sql)
      DB.connect(DB_URL) do |db|
        db.query_all(sql, as: self)
      end
    end
  end

  macro searchable_columns(columns)
    def self.search(query : String)
      return [] of self if query.blank?
      
      sanitized_query = PG::EscapeHelper.escape_literal("%#{query}%")
      where_conditions = {{ columns }}.map { |col| "#{col} ILIKE #{sanitized_query}" }.join(" OR ")
      
      DB.connect(DB_URL) do |db|
        db.query_all "SELECT * FROM post_engagement_scores WHERE #{where_conditions} ORDER BY engagement DESC, created_at DESC", as: self
      end
    end
  end

  module PgSearch
    def self.start_auto_refresh(interval_seconds = 300)
      spawn do
        loop do
          refresh_engagement_scores
          sleep interval_seconds
        end
      end
    end
  end
end

def self.refresh_engagement_scores
  DB.connect(DB_URL) do |db|
    db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"
  end
end
