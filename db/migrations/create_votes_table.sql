CREATE TABLE votes (
    id BIGSERIAL PRIMARY KEY,
    resource_id BIGINT NOT NULL,
    positive BOOLEAN,
    negative BOOLEAN,
    value FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
