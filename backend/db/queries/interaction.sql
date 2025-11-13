-- ============================================================================
-- INTERACTION QUERIES
-- ============================================================================
-- Operations for likes and comments on posts and comments


-- ----------------------------------------------------------------------------
-- POST LIKES
-- ----------------------------------------------------------------------------

-- 1. LIKE A POST
-- Parameters: $1 = post_id, $2 = user_id
-- Returns: Created like record
-- Usage: User likes a post
-- Note: ON CONFLICT makes this idempotent (can call multiple times safely)
-- name: LikePost :one
INSERT INTO post_likes (post_id, user_id, created_at)
VALUES ($1, $2, NOW())
ON CONFLICT (post_id, user_id) DO NOTHING
RETURNING post_id, user_id, created_at;


-- 2. UNLIKE A POST
-- Parameters: $1 = post_id, $2 = user_id
-- Returns: Deleted like record
-- Usage: User removes their like from a post
-- name: UnlikePost :one
DELETE FROM post_likes
WHERE post_id = $1 AND user_id = $2
RETURNING post_id, user_id;


-- 3. GET USERS WHO LIKED A POST
-- Parameters: $1 = post_id, $2 = limit, $3 = offset
-- Returns: List of users who liked this post
-- Usage: Display "Liked by X, Y, and 23 others"
-- Performance: Uses idx_post_likes_post_id
-- name: GetPostLikers :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    pl.created_at as liked_at
FROM "user" u
JOIN post_likes pl ON u.id = pl.user_id
WHERE pl.post_id = $1
ORDER BY pl.created_at DESC
LIMIT $2 OFFSET $3;


-- 4. GET POST LIKE COUNT
-- Parameters: $1 = post_id
-- Returns: Number of likes on a post
-- Usage: Display like count
-- name: GetPostLikeCount :one
SELECT COUNT(*) as like_count
FROM post_likes
WHERE post_id = $1;


-- 5. CHECK IF USER LIKED POST
-- Parameters: $1 = post_id, $2 = user_id
-- Returns: Boolean (true if user liked this post)
-- Usage: Show liked/unliked state in UI
-- name: CheckUserLikedPost :one
SELECT EXISTS (
    SELECT 1 FROM post_likes
    WHERE post_id = $1 AND user_id = $2
) as liked;


-- ----------------------------------------------------------------------------
-- COMMENT LIKES
-- ----------------------------------------------------------------------------

-- 6. LIKE A COMMENT
-- Parameters: $1 = comment_id, $2 = user_id
-- Returns: Created like record
-- Usage: User likes a comment
-- Note: ON CONFLICT makes this idempotent
-- name: LikeComment :one
INSERT INTO comment_likes (comment_id, user_id, created_at)
VALUES ($1, $2, NOW())
ON CONFLICT (comment_id, user_id) DO NOTHING
RETURNING comment_id, user_id, created_at;


-- 7. UNLIKE A COMMENT
-- Parameters: $1 = comment_id, $2 = user_id
-- Returns: Deleted like record
-- Usage: User removes their like from a comment
-- name: UnlikeComment :one
DELETE FROM comment_likes
WHERE comment_id = $1 AND user_id = $2
RETURNING comment_id, user_id;


-- 8. GET COMMENT LIKE COUNT
-- Parameters: $1 = comment_id
-- Returns: Number of likes on a comment
-- name: GetCommentLikeCount :one
-- Usage: Display like count on comments

SELECT COUNT(*) as like_count
FROM comment_likes
WHERE comment_id = $1;


-- ----------------------------------------------------------------------------
-- COMMENTS
-- ----------------------------------------------------------------------------

-- 9. ADD COMMENT (Top-level)
-- Parameters: $1 = id (ULID), $2 = post_id, $3 = owner_id, $4 = content
-- Returns: Created comment record
-- Usage: User comments on a post
-- Note: parent_comment_id is NULL for top-level comments
-- name: AddComment :one
INSERT INTO comment (id, post_id, parent_comment_id, owner_id, content)
VALUES ($1, $2, NULL, $3, $4)
RETURNING id, post_id, parent_comment_id, owner_id, content, created_at;


-- 10. ADD REPLY (Threaded comment)
-- Parameters: $1 = id (ULID), $2 = post_id, $3 = parent_comment_id,
--             $4 = owner_id, $5 = content
-- Returns: Created reply record
-- Usage: User replies to an existing comment
-- name: AddReply :one
INSERT INTO comment (id, post_id, parent_comment_id, owner_id, content)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, post_id, parent_comment_id, owner_id, content, created_at;


-- 11. GET COMMENTS FOR POST (Top-level only)
-- Parameters: $1 = post_id
-- Returns: Top-level comments with user info, reply count, like count
-- Usage: Display comment section (fetch replies separately)
-- Performance: Uses idx_comment_post_id and idx_comment_parent_comment_id
-- name: GetCommentsForPost :many
SELECT
    c.id,
    c.content,
    c.created_at,
    c.updated_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url,
    COUNT(DISTINCT replies.id) as reply_count,
    COUNT(DISTINCT cl.user_id) as like_count
FROM comment c
JOIN "user" u ON c.owner_id = u.id
LEFT JOIN comment replies ON c.id = replies.parent_comment_id
LEFT JOIN comment_likes cl ON c.id = cl.comment_id
WHERE c.post_id = $1 AND c.parent_comment_id IS NULL
GROUP BY c.id, u.id, u.username, u.profile_picture_url
ORDER BY c.created_at ASC;


-- 12. GET REPLIES TO COMMENT
-- Parameters: $1 = parent_comment_id
-- Returns: Replies to a specific comment with user info and like count
-- Usage: Load threaded replies (nested comments)
-- Performance: Uses idx_comment_parent_comment_id
-- name: GetRepliesToComment :many
SELECT
    c.id,
    c.content,
    c.created_at,
    c.updated_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url,
    COUNT(DISTINCT cl.user_id) as like_count
FROM comment c
JOIN "user" u ON c.owner_id = u.id
LEFT JOIN comment_likes cl ON c.id = cl.comment_id
WHERE c.parent_comment_id = $1
GROUP BY c.id, u.id, u.username, u.profile_picture_url
ORDER BY c.created_at ASC;


-- 13. UPDATE COMMENT
-- Parameters: $1 = comment_id, $2 = content
-- Returns: Updated comment record
-- Usage: User edits their comment
-- name: UpdateComment :one
UPDATE comment
SET
    content = $2,
    updated_at = NOW()
WHERE id = $1
RETURNING id, post_id, parent_comment_id, owner_id, content, updated_at;


-- 14. DELETE COMMENT
-- Parameters: $1 = comment_id
-- Returns: Deleted comment id
-- Usage: User deletes their comment
-- name: DeleteComment :one
-- Note: CASCADE will also delete replies (see comment.sql schema)

DELETE FROM comment
WHERE id = $1
RETURNING id;


-- 15. GET COMMENT COUNT FOR POST
-- Parameters: $1 = post_id
-- Returns: Total number of comments (including replies)
-- Usage: Display "X comments" on post preview
-- name: GetCommentCount :one
SELECT COUNT(*) as comment_count
FROM comment
WHERE post_id = $1;


-- 16. GET TOP-LEVEL COMMENT COUNT FOR POST
-- Parameters: $1 = post_id
-- Returns: Number of top-level comments only (excludes replies)
-- Usage: Display "X comments" excluding nested replies
-- name: GetTopLevelCommentCount :one
SELECT COUNT(*) as comment_count
FROM comment
WHERE post_id = $1 AND parent_comment_id IS NULL;


-- ----------------------------------------------------------------------------
-- POST USER TAGS
-- ----------------------------------------------------------------------------

-- 17. TAG USER IN POST
-- Parameters: $1 = post_id, $2 = user_id
-- Returns: Created tag record
-- Usage: Tag a friend in a coffee post
-- Note: Should trigger notification (see notification.sql)
-- name: TagUserInPost :one
INSERT INTO post_user_tags (post_id, user_id, created_at)
VALUES ($1, $2, NOW())
ON CONFLICT (post_id, user_id) DO NOTHING
RETURNING post_id, user_id, created_at;


-- 18. UNTAG USER FROM POST
-- Parameters: $1 = post_id, $2 = user_id
-- Returns: Deleted tag record
-- Usage: Remove tag from post
-- name: UntagUserFromPost :one
DELETE FROM post_user_tags
WHERE post_id = $1 AND user_id = $2
RETURNING post_id, user_id;


-- 19. GET USERS TAGGED IN POST
-- Parameters: $1 = post_id
-- Returns: List of users tagged in this post
-- Usage: Display "with X and Y" in post
-- name: GetUsersTaggedInPost :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url
FROM "user" u
JOIN post_user_tags t ON u.id = t.user_id
WHERE t.post_id = $1
ORDER BY u.username;


-- 20. GET POSTS WHERE USER IS TAGGED
-- Parameters: $1 = user_id, $2 = limit, $3 = offset
-- Returns: Posts where user has been tagged
-- Usage: "Posts you're tagged in" section on profile
-- name: GetPostsWhereUserIsTagged :many
SELECT
    p.id,
    p.title,
    p.description,
    p.rating,
    p.created_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url
FROM post p
JOIN post_user_tags t ON p.id = t.post_id
JOIN "user" u ON p.owner_id = u.id
WHERE t.user_id = $1
ORDER BY p.created_at DESC
LIMIT $2 OFFSET $3;
