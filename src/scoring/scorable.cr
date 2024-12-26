module PgSearch
  module Scorable
    def self.calculate_engagement_score
      <<-SQL
      (
        LOG(GREATEST(ABS(COALESCE(comments_count, 0)), 1)) * 2 +
        LOG(GREATEST(ABS(COALESCE(votes_count, 0)), 1)) * 3 +
        LOG(GREATEST(ABS(COALESCE(replies_count, 0)), 1)) * 1.5 +
        LOG(GREATEST(ABS(COALESCE(views_count, 0)), 1)) +
        CASE 
          WHEN COALESCE(comments_count, 0) > 0 THEN 1 
          WHEN COALESCE(votes_count, 0) > 0 THEN 1.5
          ELSE -1 
        END *
        (EXTRACT(EPOCH FROM (NOW() - created_at)) / 45000)
      )
      SQL
    end
  end
end
