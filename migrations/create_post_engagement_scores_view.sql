CREATE MATERIALIZED VIEW post_engagement_scores AS
SELECT 
  posts.*,
  COALESCE(
    SUM(
      CASE 
        WHEN votes.positive::boolean THEN 1
        WHEN votes.negative::boolean THEN -1
        ELSE votes.value
      END
    )::bigint, 
    0
  ) as engagement
FROM posts
LEFT JOIN votes ON votes.resource_type = 'Post' AND votes.resource_id = posts.id
GROUP BY posts.id;

CREATE UNIQUE INDEX post_engagement_scores_id_idx ON post_engagement_scores (id);
