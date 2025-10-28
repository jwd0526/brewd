-- User Friendships junction table
-- Manages mutual friendships between users (Facebook-style model)
--
-- BIDIRECTIONAL STORAGE MODEL:
-- When a friendship is accepted, TWO rows are created:
--   (userA, userB, 'accepted') AND (userB, userA, 'accepted')
--
-- This enables simple, fast queries without OR logic:
--   SELECT friend_id FROM user_friendships WHERE user_id = 'userA' AND status = 'accepted'
--
-- FRIENDSHIP FLOW:
-- 1. UserA sends request → Creates: (userA, userB, 'pending')
-- 2. UserB accepts → Updates: (userA, userB, 'accepted') + Creates: (userB, userA, 'accepted')
-- 3. Either user can unfriend → Deletes: BOTH rows
--
-- BLOCKING:
-- Blocking is ONE-DIRECTIONAL:
--   (userA, userB, 'blocked') means userA has blocked userB
--   UserB may still have (userB, userA, 'accepted' or 'pending')
--   Application logic should filter out blocked users in queries
--
-- IMPORTANT: Use database transactions when accepting friendships to ensure
-- both rows are created atomically.

CREATE TABLE user_friendships (
    user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    friend_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT check_no_self_friendship CHECK (user_id != friend_id)
);

-- Indexes for common queries
CREATE INDEX idx_user_friendships_user_id ON user_friendships(user_id);
CREATE INDEX idx_user_friendships_friend_id ON user_friendships(friend_id);
CREATE INDEX idx_user_friendships_status ON user_friendships(user_id, status);


-- COMMON QUERY EXAMPLES
-- ====================

-- Get all pending friend requests RECEIVED by a user
-- SELECT u.* FROM "user" u
-- JOIN user_friendships f ON u.id = f.user_id
-- WHERE f.friend_id = 'userB_id' AND f.status = 'pending';

-- Get all pending friend requests SENT by a user
-- SELECT u.* FROM "user" u
-- JOIN user_friendships f ON u.id = f.friend_id
-- WHERE f.user_id = 'userA_id' AND f.status = 'pending';

-- Get all friends of a user (simple, uses index efficiently)
-- SELECT u.* FROM "user" u
-- JOIN user_friendships f ON u.id = f.friend_id
-- WHERE f.user_id = 'user1_id' AND f.status = 'accepted';

-- Check if two users are friends (bidirectional check)
-- SELECT EXISTS (
--     SELECT 1 FROM user_friendships
--     WHERE user_id = 'userA_id' AND friend_id = 'userB_id' AND status = 'accepted'
-- );

-- Get mutual friends between two users
-- SELECT f1.friend_id FROM user_friendships f1
-- JOIN user_friendships f2 ON f1.friend_id = f2.friend_id
-- WHERE f1.user_id = 'userA_id' AND f2.user_id = 'userB_id'
--   AND f1.status = 'accepted' AND f2.status = 'accepted';

-- Count total friends for a user
-- SELECT COUNT(*) FROM user_friendships
-- WHERE user_id = 'user1_id' AND status = 'accepted';

-- Get users who have blocked a specific user
-- SELECT user_id FROM user_friendships
-- WHERE friend_id = 'userA_id' AND status = 'blocked';


-- APPLICATION IMPLEMENTATION NOTES
-- =================================

-- ACCEPTING A FRIEND REQUEST (must use transaction):
-- BEGIN;
--   UPDATE user_friendships
--   SET status = 'accepted', updated_at = NOW()
--   WHERE user_id = 'userA_id' AND friend_id = 'userB_id' AND status = 'pending';
--
--   INSERT INTO user_friendships (user_id, friend_id, status)
--   VALUES ('userB_id', 'userA_id', 'accepted');
-- COMMIT;

-- UNFRIENDING (delete both rows):
-- BEGIN;
--   DELETE FROM user_friendships
--   WHERE (user_id = 'userA_id' AND friend_id = 'userB_id')
--      OR (user_id = 'userB_id' AND friend_id = 'userA_id');
-- COMMIT;

-- BLOCKING A USER:
-- INSERT INTO user_friendships (user_id, friend_id, status)
-- VALUES ('userA_id', 'userB_id', 'blocked')
-- ON CONFLICT (user_id, friend_id)
-- DO UPDATE SET status = 'blocked', updated_at = NOW();
--
-- Note: Blocking does NOT create a reverse row. Consider also deleting
-- any existing friendship rows to fully disconnect the users.

-- FILTERING OUT BLOCKED USERS in queries:
-- SELECT u.* FROM "user" u
-- WHERE u.id NOT IN (
--     SELECT friend_id FROM user_friendships
--     WHERE user_id = 'current_user_id' AND status = 'blocked'
-- );
