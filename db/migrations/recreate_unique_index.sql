DROP INDEX IF EXISTS post_engagement_scores_unique_idx;
CREATE UNIQUE INDEX post_engagement_scores_unique_idx ON post_engagement_scores (id, engagement, created_at);
