require "./scoring/scorable"

module PgSearch
  macro included
    extend ClassMethods

    macro searchable_columns(columns)
      def self.search(query : String)
        if query.blank?
          sql = <<-SQL
            WITH post_views AS (
              SELECT punchable_id as post_id, COUNT(*) as view_count
              FROM punches 
              WHERE punchable_type = 'Post'
              AND created_at > NOW() - INTERVAL '7 days'
              GROUP BY punchable_id
            ),
            comment_votes AS (
              SELECT p.id as post_id, 
                SUM(COALESCE(c.votes_count, 0)) as comment_vote_score
              FROM posts p
              LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = 'Post'
              GROUP BY p.id
            ),
            reply_votes AS (
              SELECT p.id as post_id,
                SUM(COALESCE(r.votes_count, 0)) as reply_vote_score
              FROM posts p
              LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = 'Post'
              LEFT JOIN comments r ON r.commentable_id = c.id AND r.commentable_type = 'Comment'
              GROUP BY p.id
            ),            scored_posts AS (
              SELECT posts.*,
              (
                LOG(GREATEST(ABS(COALESCE(comments_count, 0)), 1)) * 2 +
                LOG(GREATEST(ABS(COALESCE(up_votes - down_votes, 0)), 1)) * 3 +
                LOG(GREATEST(ABS(COALESCE(replies_count, 0)), 1)) * 1.5 +
                LOG(GREATEST(ABS(COALESCE(pv.view_count, 0)), 1)) * 2.5 +
                LOG(GREATEST(ABS(COALESCE(cv.comment_vote_score, 0)), 1)) * 1.8 +
                LOG(GREATEST(ABS(COALESCE(rv.reply_vote_score, 0)), 1)) * 1.3 +
                CASE 
                  WHEN COALESCE(comments_count, 0) > 0 THEN 1 
                  WHEN COALESCE(up_votes, 0) > 0 THEN 1.5
                  WHEN COALESCE(pv.view_count, 0) > 10 THEN 1.2
                  WHEN COALESCE(cv.comment_vote_score, 0) > 5 THEN 1.1
                  WHEN COALESCE(rv.reply_vote_score, 0) > 5 THEN 1.0
                  ELSE -1 
                END *
                (EXTRACT(EPOCH FROM (NOW() - created_at)) / 45000)
              ) as engagement_score
              FROM posts posts
              LEFT JOIN post_views pv ON pv.post_id = posts.id
              LEFT JOIN comment_votes cv ON cv.post_id = posts.id
              LEFT JOIN reply_votes rv ON rv.post_id = posts.id
              WHERE posts.created_at > $1
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
