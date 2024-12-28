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

  def self.start_auto_refresh(interval_seconds = 300)
    spawn do
      loop do
        refresh_engagement_scores
        sleep interval_seconds
      end
    end
  end

  def self.refresh_engagement_scores
    DB.connect(DB_URL) do |db|
      db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"
    end
  end

  def self.calculate_engagement_score(resource_type : String, resource_id : Int64)
    query = <<-SQL
      SELECT COALESCE(
        SUM(
          CASE 
            WHEN positive = true THEN 1
            WHEN negative = true THEN -1
            ELSE value
          END
        )::bigint, 
        0
      ) as score
      FROM votes 
      WHERE resource_type = $1 
      AND resource_id = $2
    SQL

    DB.connect(DB_URL) do |db|
      db.query_one(query, resource_type, resource_id, as: Int64)
    end
  end

  def self.refresh_engagement_scores
    DB.connect(DB_URL) do |db|
      # Update the materialized view with new engagement scores
      db.exec <<-SQL
        REFRESH MATERIALIZED VIEW post_engagement_scores;
        UPDATE post_engagement_scores 
        SET engagement = (
          SELECT calculate_engagement_score('Post', id)
          FROM posts WHERE posts.id = post_engagement_scores.id
        );
      SQL
    end
  end
end
