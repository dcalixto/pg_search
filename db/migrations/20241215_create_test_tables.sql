-- +micrate Up
CREATE TABLE test_models (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR,
  body TEXT,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE punches (
  id BIGSERIAL PRIMARY KEY,
  punchable_type VARCHAR,
  punchable_id BIGINT,
  hits INTEGER DEFAULT 1,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE votes (
  id BIGSERIAL PRIMARY KEY,
  resource_type VARCHAR,
  resource_id BIGINT,
  positive BOOLEAN,
  negative BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY,
  commentable_type VARCHAR,
  commentable_id BIGINT,
  body TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- +micrate Down
DROP TABLE comments;
DROP TABLE votes;
DROP TABLE punches;
DROP TABLE test_models;
