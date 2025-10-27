-- Media table
-- Represents photos or videos attached to posts
CREATE TABLE media (
    id TEXT PRIMARY KEY, -- ULID format
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('image', 'video')),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_media_post_id ON media(post_id);
CREATE INDEX idx_media_display_order ON media(post_id, display_order);
