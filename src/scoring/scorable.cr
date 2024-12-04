module Scorable
  def self.calculate_hot_score(up_votes : Int32, down_votes : Int32, created_at : Time)
    <<-SQL
      SELECT (
        LOG(GREATEST(ABS(#{up_votes} - #{down_votes}), 1)) +
        (CASE WHEN #{up_votes} > #{down_votes} THEN 1 ELSE -1 END) *
        (EXTRACT(EPOCH FROM (NOW() - '#{created_at.to_s}')) / 45000)
      ) AS hot_score
    SQL
  end

  def self.calculate_total_engagement_score(up_votes : Int32, down_votes : Int32, comments_count : Int32, created_at : Time)
    hot_score_query = calculate_hot_score(up_votes, down_votes, created_at)
    <<-SQL
      (#{hot_score_query}) + (#{comments_count} * 2.0)
    SQL
  end
end
