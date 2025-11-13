-- Post User Tags junction table
-- Tracks which users are tagged in which posts
CREATE TABLE post_user_tags (
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

-- Indexes for common queries
CREATE INDEX idx_post_user_tags_post_id ON post_user_tags(post_id);
CREATE INDEX idx_post_user_tags_user_id ON post_user_tags(user_id);
