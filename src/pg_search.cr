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
      sanitized_query = PG::EscapeHelper.escape_literal("%#{query}%")
      
      DB.connect(DB_URL) do |db|
        # Create temporary views in the same session
        db.exec "CREATE TEMP TABLE post_views AS SELECT punchable_id as post_id, COUNT(*) as view_count FROM punches WHERE punchable_type = '#{table_name}' AND created_at > NOW() - INTERVAL '7 days' GROUP BY punchable_id"
        
        db.exec "CREATE TEMP TABLE post_votes AS SELECT resource_id as post_id, SUM(positive - negative) as vote_score FROM votes WHERE resource_type = '#{table_name}' GROUP BY resource_id"
        
        db.exec "CREATE TEMP TABLE comment_votes AS SELECT p.id as post_id, COUNT(c.id) as comment_count, SUM(v.positive - v.negative) as comment_vote_score FROM #{table_name} p LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = '#{table_name}' LEFT JOIN votes v ON v.resource_id = c.id AND v.resource_type = 'Comment' GROUP BY p.id"
        
        db.exec "CREATE TEMP TABLE reply_votes AS SELECT p.id as post_id, COUNT(r.id) as reply_count, SUM(v.positive - v.negative) as reply_vote_score FROM #{table_name} p LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = '#{table_name}' LEFT JOIN comments r ON r.commentable_id = c.id AND r.commentable_type = 'Comment' LEFT JOIN votes v ON v.resource_id = r.id AND v.resource_type = 'Comment' GROUP BY p.id"
        
        db.exec "CREATE TEMP TABLE engagement_scores AS SELECT p.*, COALESCE(cv.comment_count, 0) as total_comments, COALESCE(rv.reply_count, 0) as total_replies, (LOG(GREATEST(COALESCE(cv.comment_count, 0) + 1, 1)) * 3.5 + LOG(GREATEST(COALESCE(rv.reply_count, 0) + 1, 1)) * 3.2 + LOG(GREATEST(COALESCE(pvo.vote_score, 0) + 1, 1)) * 3.0 + LOG(GREATEST(COALESCE(cv.comment_vote_score, 0) + 1, 1)) * 2.8 + LOG(GREATEST(COALESCE(rv.reply_vote_score, 0) + 1, 1)) * 2.5 + LOG(GREATEST(COALESCE(pv.view_count, 0) + 1, 1)) * 1.5) * EXP(-EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 45000) as engagement FROM #{table_name} p LEFT JOIN post_views pv ON pv.post_id = p.id LEFT JOIN post_votes pvo ON pvo.post_id = p.id LEFT JOIN comment_votes cv ON cv.post_id = p.id LEFT JOIN reply_votes rv ON rv.post_id = p.id"

        # Execute search query in the same session
        where_conditions = {{ columns }}.map { |col| "#{col} ILIKE #{sanitized_query}" }.join(" OR ")
        db.query_all "SELECT * FROM engagement_scores WHERE #{where_conditions} ORDER BY engagement DESC, created_at DESC", as: self
      end
    end
  end
end
