module QueryBuilders
  class CommentVotes
    def self.build_join_sql
      <<-SQL
        LEFT JOIN votes comment_votes ON
          comment_votes.resource_type = 'Comment' AND
          comment_votes.resource_id = comments.id
      SQL
    end

    def self.calculate_comment_score
      <<-SQL
        COALESCE(SUM(CASE
          WHEN comment_votes.positive = 1 THEN 1
          WHEN comment_votes.negative = 1 THEN -1
          ELSE 0
        END), 0) +
        (SELECT COUNT(*) FROM comments children WHERE children.parent_id = comments.id)
      SQL
    end
  end
end
