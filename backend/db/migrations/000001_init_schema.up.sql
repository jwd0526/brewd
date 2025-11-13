-- ============================================================================
-- BREWD DATABASE SCHEMA - INITIAL MIGRATION
-- ============================================================================
-- This migration creates all tables for the Brewd coffee social platform
-- Migration: 000001_init_schema
-- Created: 2025-11-13

-- ----------------------------------------------------------------------------
-- 1. USER TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE "user" (
    id TEXT PRIMARY KEY, -- ULID format
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_picture_url TEXT,
    bio TEXT,
    location TEXT,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_username ON "user"(username);
CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_user_joined_at ON "user"(joined_at);

-- ----------------------------------------------------------------------------
-- 2. BREW TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE brew (
    id TEXT PRIMARY KEY, -- ULID format
    name VARCHAR(255) NOT NULL,
    brew_method VARCHAR(100) CHECK (
        brew_method IS NULL OR
        brew_method IN ('espresso', 'pour_over', 'french_press', 'aeropress',
                       'cold_brew', 'drip', 'moka_pot', 'siphon', 'chemex',
                       'v60', 'turkish', 'percolator', 'other')
    ),
    bean_origin TEXT,
    roaster TEXT,
    notes TEXT,
    created_by TEXT REFERENCES "user"(id),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_brew_created_by ON brew(created_by);
CREATE INDEX idx_brew_is_public ON brew(is_public);
CREATE INDEX idx_brew_name ON brew(name);
CREATE INDEX idx_brew_method ON brew(brew_method);

-- ----------------------------------------------------------------------------
-- 3. POST TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE post (
    id TEXT PRIMARY KEY, -- ULID format
    owner_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    brew_id TEXT REFERENCES brew(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
    visibility VARCHAR(50) DEFAULT 'public' CHECK (visibility IN ('public', 'friends', 'private')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_owner_id ON post(owner_id);
CREATE INDEX idx_post_brew_id ON post(brew_id);
CREATE INDEX idx_post_created_at ON post(created_at);
CREATE INDEX idx_post_rating ON post(rating);
CREATE INDEX idx_post_visibility ON post(visibility, created_at);

-- ----------------------------------------------------------------------------
-- 4. MEDIA TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE media (
    id TEXT PRIMARY KEY, -- ULID format
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('image', 'video')),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_post_id ON media(post_id);
CREATE INDEX idx_media_display_order ON media(post_id, display_order);

-- ----------------------------------------------------------------------------
-- 5. COMMENT TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE comment (
    id TEXT PRIMARY KEY, -- ULID format
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    parent_comment_id TEXT REFERENCES comment(id) ON DELETE CASCADE,
    owner_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comment_post_id ON comment(post_id);
CREATE INDEX idx_comment_parent_comment_id ON comment(parent_comment_id);
CREATE INDEX idx_comment_owner_id ON comment(owner_id);
CREATE INDEX idx_comment_created_at ON comment(created_at);

-- ----------------------------------------------------------------------------
-- 6. USER FRIENDSHIPS TABLE
-- ----------------------------------------------------------------------------
-- Bidirectional friendship model - see schema comments for details
CREATE TABLE user_friendships (
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    friend_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT check_no_self_friendship CHECK (user_id != friend_id)
);

CREATE INDEX idx_user_friendships_user_id ON user_friendships(user_id);
CREATE INDEX idx_user_friendships_friend_id ON user_friendships(friend_id);
CREATE INDEX idx_user_friendships_status ON user_friendships(user_id, status);

-- ----------------------------------------------------------------------------
-- 7. POST LIKES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE post_likes (
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);

-- ----------------------------------------------------------------------------
-- 8. COMMENT LIKES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE comment_likes (
    comment_id TEXT NOT NULL REFERENCES comment(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON comment_likes(user_id);

-- ----------------------------------------------------------------------------
-- 9. POST USER TAGS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE post_user_tags (
    post_id TEXT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

CREATE INDEX idx_post_user_tags_post_id ON post_user_tags(post_id);
CREATE INDEX idx_post_user_tags_user_id ON post_user_tags(user_id);

-- ----------------------------------------------------------------------------
-- 10. NOTIFICATION TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE notification (
    id TEXT PRIMARY KEY, -- ULID format
    recipient_user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    actor_user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('like', 'comment', 'friend_request', 'tag', 'follow')),
    reference_id TEXT,
    reference_type VARCHAR(50) CHECK (reference_type IN ('post', 'comment', 'friendship')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_recipient ON notification(recipient_user_id);
CREATE INDEX idx_notification_is_read ON notification(recipient_user_id, is_read);
CREATE INDEX idx_notification_type ON notification(recipient_user_id, type, is_read);
CREATE INDEX idx_notification_created_at ON notification(created_at);

-- ----------------------------------------------------------------------------
-- 11. TRIGGERS - UPDATED_AT AUTOMATION
-- ----------------------------------------------------------------------------
-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_user_updated_at
BEFORE UPDATE ON "user"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_updated_at
BEFORE UPDATE ON post
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brew_updated_at
BEFORE UPDATE ON brew
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comment_updated_at
BEFORE UPDATE ON comment
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_friendships_updated_at
BEFORE UPDATE ON user_friendships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
