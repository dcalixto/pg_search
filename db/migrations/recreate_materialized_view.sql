DROP MATERIALIZED VIEW IF EXISTS post_engagement_scores;
CREATE MATERIALIZED VIEW post_engagement_scores AS
SELECT 
    p.id,
    p.title,
    p.content,
    COALESCE(SUM(
        CASE 
            WHEN v.positive IS TRUE THEN 1
            WHEN v.negative IS TRUE THEN -1
            ELSE COALESCE(v.value, 0)
        END
    )::float, 0.0) as engagement,
    p.created_at
FROM posts p
LEFT JOIN votes v ON p.id = v.resource_id
GROUP BY p.id, p.title, p.content, p.created_at
ORDER BY engagement DESC, created_at DESC;
