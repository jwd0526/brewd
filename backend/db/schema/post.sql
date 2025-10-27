-- Post table
-- The main content unit representing a coffee brew that a user has made and rated
CREATE TABLE post (
    id TEXT PRIMARY KEY, -- ULID format
    owner_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    brew_id TEXT REFERENCES brew(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_post_owner_id ON post(owner_id);
CREATE INDEX idx_post_brew_id ON post(brew_id);
CREATE INDEX idx_post_created_at ON post(created_at);
CREATE INDEX idx_post_rating ON post(rating);
