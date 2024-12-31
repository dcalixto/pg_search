CREATE MATERIALIZED VIEW post_engagement_scores AS
SELECT 
  p.id,
  COALESCE(SUM(
      CASE 
          WHEN v.positive IS TRUE THEN 1
          WHEN v.negative IS TRUE THEN -1
          ELSE v.value
      END
  )::float, 0.0) as engagement,
  p.created_at
FROM posts p
LEFT JOIN votes v ON p.id = v.resource_id
GROUP BY p.id, p.created_at;
