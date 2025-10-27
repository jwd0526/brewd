-- User Friendships junction table
-- Manages friendships/follows between users
CREATE TABLE user_friendships (
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    friend_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
);

-- Indexes for common queries
CREATE INDEX idx_user_friendships_user_id ON user_friendships(user_id);
CREATE INDEX idx_user_friendships_friend_id ON user_friendships(friend_id);
CREATE INDEX idx_user_friendships_status ON user_friendships(user_id, status);
