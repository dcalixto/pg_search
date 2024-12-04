module QueryBuilders
  class Ranking
    def self.build_ranking_query(weights : Hash(String, Int32) = {"votes" => 2, "comments" => 1, "punches" => 1})
      <<-SQL
        COALESCE((
          SELECT SUM(CASE
            WHEN votes.resource_type = 'Post' AND votes.resource_id = posts.id THEN
              CASE
                WHEN votes.positive = 1 THEN #{weights["votes"]}
                WHEN votes.negative = 1 THEN -#{weights["votes"]}
                ELSE 0
              END
            ELSE 0
          END)
        ), 0) +
        COALESCE((
          SELECT COUNT(*) FROM comments
          WHERE comments.commentable_type = 'Post' AND comments.commentable_id = posts.id
        ) * #{weights["comments"]}, 0) +
        COALESCE((
          SELECT SUM(hits) FROM punches
          WHERE punches.punchable_type = 'Post' AND punches.punchable_id = posts.id
        ) * #{weights["punches"]}, 0)
      SQL
    end
  end
end
