-- ============================================================================
-- POST QUERIES
-- ============================================================================
-- Operations for posts: create, read, feed generation, and user posts


-- ----------------------------------------------------------------------------
-- 1. CREATE POST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = id (ULID), $2 = owner_id, $3 = brew_id, $4 = title,
--             $5 = description, $6 = rating, $7 = visibility
-- Returns: The created post record
-- Usage: User creates a new coffee brew post
-- name: CreatePost :one
INSERT INTO post (id, owner_id, brew_id, title, description, rating, visibility)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING id, owner_id, brew_id, title, description, rating, visibility, created_at, updated_at;


-- ----------------------------------------------------------------------------
-- 2. GET SINGLE POST WITH FULL DETAILS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = post_id
-- Returns: Post with owner info, brew details, media, like count, comment count
-- Usage: Display detailed post view
-- Performance: Multiple LEFT JOINs, uses multiple indexes
-- name: GetPostWithDetails :one
SELECT
    p.*,
    u.username,
    u.profile_picture_url,
    b.name as brew_name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count,
    ARRAY_AGG(jsonb_build_object(
        'id', m.id,
        'url', m.url,
        'type', m.type,
        'display_order', m.display_order
    ) ORDER BY m.display_order) FILTER (WHERE m.id IS NOT NULL) as media
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
LEFT JOIN media m ON p.id = m.post_id
WHERE p.id = $1
GROUP BY p.id, u.id, b.id;


-- ----------------------------------------------------------------------------
-- 3. GET USER FEED (Posts from Friends)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = current_user_id, $2 = limit, $3 = offset
-- Returns: Posts from friends, sorted by recency, with pagination
-- Usage: Main feed feature - see what friends are brewing
-- Performance: Uses idx_user_friendships_status and idx_post_created_at
-- name: GetUserFeed :many
SELECT
    p.id,
    p.title,
    p.description,
    p.rating,
    p.created_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url,
    b.name as brew_name,
    b.brew_method,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count,
    EXISTS(
        SELECT 1 FROM post_likes pl2
        WHERE pl2.post_id = p.id AND pl2.user_id = $1
    ) as liked_by_current_user
FROM post p
JOIN user_friendships f ON p.owner_id = f.friend_id
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE f.user_id = $1
    AND f.status = 'accepted'
    AND p.visibility IN ('public', 'friends')
GROUP BY p.id, u.id, u.username, u.profile_picture_url, b.name, b.brew_method
ORDER BY p.created_at DESC
LIMIT $2 OFFSET $3;


-- ----------------------------------------------------------------------------
-- 4. GET USER'S OWN POSTS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = owner_id
-- Returns: All posts created by a specific user
-- Usage: User profile page showing their post history
-- Performance: Uses idx_post_owner_id
-- name: GetUserPosts :many
SELECT
    p.*,
    b.name as brew_name,
    b.brew_method,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count
FROM post p
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.owner_id = $1
GROUP BY p.id, b.name, b.brew_method
ORDER BY p.created_at DESC;


-- ----------------------------------------------------------------------------
-- 5. GET PUBLIC POSTS (Discovery Feed)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = limit, $2 = offset
-- Returns: Recent public posts from all users
-- Usage: Public discovery feed for non-friends
-- Performance: Uses idx_post_visibility
-- name: GetPublicPosts :many
SELECT
    p.id,
    p.title,
    p.description,
    p.rating,
    p.created_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url,
    b.name as brew_name,
    b.brew_method,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.visibility = 'public'
GROUP BY p.id, u.id, u.username, u.profile_picture_url, b.name, b.brew_method
ORDER BY p.created_at DESC
LIMIT $1 OFFSET $2;


-- ----------------------------------------------------------------------------
-- 6. UPDATE POST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = post_id, $2 = title, $3 = description, $4 = rating, $5 = visibility
-- Returns: Updated post record
-- Usage: User edits their post
-- name: UpdatePost :one
UPDATE post
SET
    title = COALESCE($2, title),
    description = COALESCE($3, description),
    rating = COALESCE($4, rating),
    visibility = COALESCE($5, visibility),
    updated_at = NOW()
WHERE id = $1
RETURNING *;


-- ----------------------------------------------------------------------------
-- 7. DELETE POST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = post_id
-- Returns: Deleted post id
-- Usage: User deletes their post
-- Note: CASCADE will also delete related media, likes, comments
-- name: DeletePost :one
DELETE FROM post
WHERE id = $1
RETURNING id;


-- ----------------------------------------------------------------------------
-- 8. GET POSTS BY BREW
-- ----------------------------------------------------------------------------
-- Parameters: $1 = brew_id, $2 = limit, $3 = offset
-- Returns: All posts using a specific brew
-- Usage: View all posts for a particular coffee brew
-- Performance: Uses idx_post_brew_id
-- name: GetPostsByBrew :many
SELECT
    p.id,
    p.title,
    p.description,
    p.rating,
    p.created_at,
    u.id as owner_id,
    u.username,
    u.profile_picture_url,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.brew_id = $1
    AND p.visibility = 'public'
GROUP BY p.id, u.id, u.username, u.profile_picture_url
ORDER BY p.created_at DESC
LIMIT $2 OFFSET $3;


-- ----------------------------------------------------------------------------
-- 9. ADD MEDIA TO POST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = id (ULID), $2 = post_id, $3 = url, $4 = type, $5 = display_order
-- Returns: Created media record
-- Usage: Attach photos/videos to a post
-- name: AddMediaToPost :one
INSERT INTO media (id, post_id, url, type, display_order)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;


-- ----------------------------------------------------------------------------
-- 10. GET MEDIA FOR POST
-- ----------------------------------------------------------------------------
-- Parameters: $1 = post_id
-- Returns: All media items for a post, ordered by display_order
-- Usage: Display post images/videos
-- name: GetMediaForPost :many
SELECT *
FROM media
WHERE post_id = $1
ORDER BY display_order;
