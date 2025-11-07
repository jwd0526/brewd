-- ============================================================================
-- FRIENDSHIP QUERIES
-- ============================================================================
-- Operations for friendships: send requests, accept, list friends, pending requests
-- NOTE: Uses bidirectional storage model - see user_friendships.sql for details


-- ----------------------------------------------------------------------------
-- 1. SEND FRIEND REQUEST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id (requester), $2 = friend_id (recipient)
-- Returns: The created friendship record
-- Usage: User A sends friend request to User B
-- Note: Creates single 'pending' row, reverse row created on acceptance
-- name: SendFriendRequest :one
INSERT INTO user_friendships (user_id, friend_id, status)
VALUES ($1, $2, 'pending')
RETURNING user_id, friend_id, status, created_at;


-- ----------------------------------------------------------------------------
-- 2. ACCEPT FRIEND REQUEST (Use Transaction!)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = requester_user_id, $2 = accepter_user_id
-- Returns: Both friendship records
-- Usage: User B accepts User A's request, creating bidirectional friendship
--
-- ⚠️  CRITICAL: These TWO queries MUST be wrapped in a transaction in your application code!
-- ⚠️  If the UPDATE succeeds but INSERT fails, you'll have inconsistent data.
--
-- Example application code:
--   BEGIN;
--     [Execute first query]
--     [Execute second query]
--   COMMIT;

-- First query: Update the pending request
-- name: AcceptFriendRequestUpdate :one
UPDATE user_friendships
SET status = 'accepted', updated_at = NOW()
WHERE user_id = $1 AND friend_id = $2 AND status = 'pending'
RETURNING user_id, friend_id, status, updated_at;

-- Second query: Create reverse direction
-- name: AcceptFriendRequestInsert :one
INSERT INTO user_friendships (user_id, friend_id, status)
VALUES ($2, $1, 'accepted')
RETURNING user_id, friend_id, status, created_at;


-- ----------------------------------------------------------------------------
-- 3. REJECT/CANCEL FRIEND REQUEST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = friend_id
-- Returns: Deleted friendship id
-- Usage: Reject incoming request or cancel outgoing request
-- name: RejectFriendRequest :one
DELETE FROM user_friendships
WHERE user_id = $1 AND friend_id = $2 AND status = 'pending'
RETURNING user_id, friend_id;


-- ----------------------------------------------------------------------------
-- 4. GET FRIEND LIST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id
-- Returns: All accepted friends with user details
-- Usage: Display user's friends list
-- Performance: Uses idx_user_friendships_status, bidirectional storage makes query simple
-- name: GetFriendList :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    u.bio,
    f.created_at as friends_since
FROM "user" u
JOIN user_friendships f ON u.id = f.friend_id
WHERE f.user_id = $1 AND f.status = 'accepted'
ORDER BY u.username;


-- ----------------------------------------------------------------------------
-- 5. GET PENDING FRIEND REQUESTS (Incoming)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id (recipient)
-- Returns: Users who have sent friend requests
-- Usage: Show incoming friend requests for user to accept/reject
-- Performance: Uses idx_user_friendships_friend_id
-- name: GetPendingRequestsReceived :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    u.bio,
    f.created_at as requested_at
FROM "user" u
JOIN user_friendships f ON u.id = f.user_id
WHERE f.friend_id = $1 AND f.status = 'pending'
ORDER BY f.created_at DESC;


-- ----------------------------------------------------------------------------
-- 6. GET SENT FRIEND REQUESTS (Outgoing)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id (requester)
-- Returns: Users to whom current user has sent pending requests
-- Usage: Show outgoing friend requests (for cancellation)
-- Performance: Uses idx_user_friendships_user_id
-- name: GetPendingRequestsSent :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    u.bio,
    f.created_at as requested_at
FROM "user" u
JOIN user_friendships f ON u.id = f.friend_id
WHERE f.user_id = $1 AND f.status = 'pending'
ORDER BY f.created_at DESC;


-- ----------------------------------------------------------------------------
-- 7. UNFRIEND (Use Transaction!)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_a_id, $2 = user_b_id
-- Returns: Number of deleted rows (should be 2)
-- Usage: Remove friendship between two users
--
-- ⚠️  CRITICAL: This query MUST be wrapped in a transaction in your application code!
-- ⚠️  If only one row is deleted due to error, you'll have inconsistent data.
--
-- Example application code:
--   BEGIN;
--     [Execute DELETE query]
--     [Verify 2 rows affected]
--   COMMIT;
-- name: Unfriend :exec
DELETE FROM user_friendships
WHERE (user_id = $1 AND friend_id = $2)
   OR (user_id = $2 AND friend_id = $1);


-- ----------------------------------------------------------------------------
-- 8. CHECK FRIENDSHIP STATUS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = current_user_id, $2 = other_user_id
-- Returns: Status ('accepted', 'pending', 'blocked', or NULL if no relationship)
-- Usage: Determine relationship between two users
-- name: CheckFriendshipStatus :one
SELECT status
FROM user_friendships
WHERE user_id = $1 AND friend_id = $2;


-- ----------------------------------------------------------------------------
-- 9. ARE USERS FRIENDS?
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_a_id, $2 = user_b_id
-- Returns: Boolean (true if friends, false otherwise)
-- Usage: Quick check if two users are friends
-- name: AreUsersFriends :one
SELECT EXISTS (
    SELECT 1 FROM user_friendships
    WHERE user_id = $1 AND friend_id = $2 AND status = 'accepted'
) as are_friends;


-- ----------------------------------------------------------------------------
-- 10. GET MUTUAL FRIENDS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_a_id, $2 = user_b_id
-- Returns: Users who are friends with both user A and user B
-- Usage: Show mutual friends between two users
-- name: GetMutualFriends :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url
FROM "user" u
WHERE u.id IN (
    SELECT f1.friend_id
    FROM user_friendships f1
    JOIN user_friendships f2 ON f1.friend_id = f2.friend_id
    WHERE f1.user_id = $1 AND f2.user_id = $2
        AND f1.status = 'accepted' AND f2.status = 'accepted'
)
ORDER BY u.username;


-- ----------------------------------------------------------------------------
-- 11. GET FRIEND COUNT
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id
-- Returns: Number of accepted friends
-- Usage: Display friend count on profile
-- name: GetFriendCount :one
SELECT COUNT(*) as friend_count
FROM user_friendships
WHERE user_id = $1 AND status = 'accepted';


-- ----------------------------------------------------------------------------
-- 12. BLOCK USER
-- ----------------------------------------------------------------------------
-- Parameters: $1 = blocker_user_id, $2 = blocked_user_id
-- Returns: Block record
-- Usage: User blocks another user
-- Note: Blocking is ONE-DIRECTIONAL (see user_friendships.sql for details)
-- name: BlockUser :one
INSERT INTO user_friendships (user_id, friend_id, status)
VALUES ($1, $2, 'blocked')
ON CONFLICT (user_id, friend_id)
DO UPDATE SET status = 'blocked', updated_at = NOW()
RETURNING user_id, friend_id, status, updated_at;


-- ----------------------------------------------------------------------------
-- 13. UNBLOCK USER
-- ----------------------------------------------------------------------------
-- Parameters: $1 = blocker_user_id, $2 = blocked_user_id
-- Returns: Deleted block record
-- Usage: User unblocks another user
-- name: UnblockUser :one
DELETE FROM user_friendships
WHERE user_id = $1 AND friend_id = $2 AND status = 'blocked'
RETURNING user_id, friend_id;


-- ----------------------------------------------------------------------------
-- 14. GET BLOCKED USERS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id (blocker)
-- Returns: List of users blocked by current user
-- Usage: Display blocked users list
-- name: GetBlockedUsers :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    f.created_at as blocked_at
FROM "user" u
JOIN user_friendships f ON u.id = f.friend_id
WHERE f.user_id = $1 AND f.status = 'blocked'
ORDER BY f.created_at DESC;
