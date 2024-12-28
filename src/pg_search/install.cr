module PgSearch
  class Install
    def self.run
      DB.connect(DATABASE_URL) do |db|
        db.exec <<-SQL
          CREATE MATERIALIZED VIEW IF NOT EXISTS post_engagement_scores AS
          SELECT p.*, 
            COALESCE(cv.comment_count, 0) as total_comments,
            COALESCE(rv.reply_count, 0) as total_replies,
            (LOG(GREATEST(COALESCE(cv.comment_count, 0) + 1, 1)) * 3.5 + 
             LOG(GREATEST(COALESCE(rv.reply_count, 0) + 1, 1)) * 3.2 + 
             LOG(GREATEST(COALESCE(pvo.vote_score, 0) + 1, 1)) * 3.0 + 
             LOG(GREATEST(COALESCE(cv.comment_vote_score, 0) + 1, 1)) * 2.8 + 
             LOG(GREATEST(COALESCE(rv.reply_vote_score, 0) + 1, 1)) * 2.5 + 
             LOG(GREATEST(COALESCE(pv.view_count, 0) + 1, 1)) * 1.5) * 
             EXP(-EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 45000) as engagement
          FROM posts p
          LEFT JOIN (
            SELECT punchable_id as post_id, COUNT(*) as view_count 
            FROM punches 
            WHERE punchable_type = 'Post' 
            AND created_at > NOW() - INTERVAL '7 days' 
            GROUP BY punchable_id
          ) pv ON pv.post_id = p.id
          LEFT JOIN (
            SELECT resource_id as post_id, SUM(positive - negative) as vote_score 
            FROM votes 
            WHERE resource_type = 'Post' 
            GROUP BY resource_id
          ) pvo ON pvo.post_id = p.id
          LEFT JOIN (
            SELECT p.id as post_id, 
                   COUNT(c.id) as comment_count, 
                   SUM(v.positive - v.negative) as comment_vote_score
            FROM posts p
            LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = 'Post'
            LEFT JOIN votes v ON v.resource_id = c.id AND v.resource_type = 'Comment'
            GROUP BY p.id
          ) cv ON cv.post_id = p.id
          LEFT JOIN (
            SELECT p.id as post_id, 
                   COUNT(r.id) as reply_count, 
                   SUM(v.positive - v.negative) as reply_vote_score
            FROM posts p
            LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = 'Post'
            LEFT JOIN comments r ON r.commentable_id = c.id AND r.commentable_type = 'Comment'
            LEFT JOIN votes v ON v.resource_id = r.id AND v.resource_type = 'Comment'
            GROUP BY p.id
          ) rv ON rv.post_id = p.id;

          CREATE INDEX IF NOT EXISTS idx_post_engagement_scores_engagement 
          ON post_engagement_scores(engagement DESC);
        SQL
      end
    end
  end
end
