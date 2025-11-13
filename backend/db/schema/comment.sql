-- Comment table
-- Represents comments on posts, with support for threaded replies
CREATE TABLE comment (
    id TEXT PRIMARY KEY, -- ULID format
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    parent_comment_id TEXT REFERENCES comment(id) ON DELETE CASCADE,
    owner_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_comment_post_id ON comment(post_id);
CREATE INDEX idx_comment_parent_comment_id ON comment(parent_comment_id);
CREATE INDEX idx_comment_owner_id ON comment(owner_id);
CREATE INDEX idx_comment_created_at ON comment(created_at);
