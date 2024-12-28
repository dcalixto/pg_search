CREATE TABLE punches (
  id SERIAL PRIMARY KEY,
  punchable_id INTEGER,
  punchable_type VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE votes (
  id SERIAL PRIMARY KEY,
  resource_id INTEGER,
  resource_type VARCHAR(255),
  positive INTEGER DEFAULT 0,
  negative INTEGER DEFAULT 0
);

CREATE TABLE comments (
  id SERIAL PRIMARY KEY,
  commentable_id INTEGER,
  commentable_type VARCHAR(255),
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
