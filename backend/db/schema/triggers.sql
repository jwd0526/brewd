-- ============================================================================
-- DATABASE TRIGGERS
-- ============================================================================
-- Automatic triggers for maintaining data integrity and timestamps


-- ----------------------------------------------------------------------------
-- UPDATED_AT TRIGGER FUNCTION
-- ----------------------------------------------------------------------------
-- Automatically updates the updated_at column to NOW() whenever a row is modified
-- This ensures updated_at is always accurate without requiring application logic

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- APPLY UPDATED_AT TRIGGER TO ALL RELEVANT TABLES
-- ----------------------------------------------------------------------------

-- User table
CREATE TRIGGER update_user_updated_at
BEFORE UPDATE ON "user"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Post table
CREATE TRIGGER update_post_updated_at
BEFORE UPDATE ON post
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Brew table
CREATE TRIGGER update_brew_updated_at
BEFORE UPDATE ON brew
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Comment table
CREATE TRIGGER update_comment_updated_at
BEFORE UPDATE ON comment
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- User Friendships table
CREATE TRIGGER update_user_friendships_updated_at
BEFORE UPDATE ON user_friendships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ----------------------------------------------------------------------------
-- NOTES
-- ----------------------------------------------------------------------------
-- This trigger must be applied AFTER creating all tables
-- Recommended schema creation order:
--   1. user.sql
--   2. brew.sql
--   3. post.sql
--   4. media.sql
--   5. comment.sql
--   6. user_friendships.sql
--   7. post_likes.sql
--   8. comment_likes.sql
--   9. post_user_tags.sql
--  10. notification.sql
--  11. triggers.sql (this file)
