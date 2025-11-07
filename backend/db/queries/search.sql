-- ============================================================================
-- SEARCH & DISCOVERY QUERIES
-- ============================================================================
-- Operations for searching users, brews, posts, and discovering popular content


-- ----------------------------------------------------------------------------
-- USER SEARCH
-- ----------------------------------------------------------------------------

-- 1. SEARCH USERS BY USERNAME
-- Parameters: $1 = search_term (use '%term%' for contains, 'term%' for starts with)
-- Returns: Matching users with basic info
-- Usage: User search bar
-- Performance: Fast if pattern doesn't start with %, uses idx_user_username
-- name: SearchUsersByUsername :many
SELECT
    id,
    username,
    profile_picture_url,
    bio,
    location
FROM "user"
WHERE username ILIKE $1
ORDER BY username
LIMIT 20;


-- 2. SEARCH USERS WITH STATS
-- Parameters: $1 = search_term
-- Returns: Matching users with friend/post counts
-- Usage: Enhanced user search with activity indicators
-- name: SearchUsersWithStats :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    u.bio,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT f.friend_id) as friend_count
FROM "user" u
LEFT JOIN post p ON u.id = p.owner_id
LEFT JOIN user_friendships f ON u.id = f.user_id AND f.status = 'accepted'
WHERE u.username ILIKE $1
GROUP BY u.id
ORDER BY friend_count DESC, post_count DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- BREW SEARCH
-- ----------------------------------------------------------------------------

-- 3. SEARCH BREWS
-- Parameters: $1 = search_term (searches name, brew_method, bean_origin, roaster)
-- Returns: Matching brews with usage count
-- Usage: Search for coffee brews
-- Performance: Uses idx_brew_name and idx_brew_method
-- name: SearchBrews :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    b.notes,
    COUNT(p.id) as usage_count
FROM brew b
LEFT JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true
    AND (
        b.name ILIKE $1
        OR b.brew_method ILIKE $1
        OR b.bean_origin ILIKE $1
        OR b.roaster ILIKE $1
    )
GROUP BY b.id
ORDER BY usage_count DESC, b.name
LIMIT 20;


-- 4. SEARCH BREWS BY METHOD
-- Parameters: $1 = brew_method (exact match)
-- Returns: All brews using this method
-- Usage: Filter brews by brewing method
-- Performance: Uses idx_brew_method
-- name: SearchBrewsByMethod :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(p.id) as usage_count
FROM brew b
LEFT JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true AND b.brew_method = $1
GROUP BY b.id
ORDER BY usage_count DESC
LIMIT 20;


-- 5. SEARCH BREWS BY ROASTER
-- Parameters: $1 = roaster (case-insensitive)
-- Returns: All brews from this roaster
-- Usage: Discover brews from a specific roaster
-- name: SearchBrewsByRoaster :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(p.id) as usage_count
FROM brew b
LEFT JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true AND b.roaster ILIKE $1
GROUP BY b.id
ORDER BY usage_count DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- POST SEARCH
-- ----------------------------------------------------------------------------

-- 6. SEARCH POSTS
-- Parameters: $1 = search_term (searches title and description)
-- Returns: Matching posts with owner and engagement metrics
-- Usage: Search for specific posts/content
-- name: SearchPosts :many
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
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.visibility = 'public'
    AND (p.title ILIKE $1 OR p.description ILIKE $1)
GROUP BY p.id, u.id, u.username, u.profile_picture_url, b.name
ORDER BY p.created_at DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- POPULAR/TRENDING CONTENT
-- ----------------------------------------------------------------------------

-- 7. GET POPULAR BREWS
-- Parameters: $1 = days (e.g., 30 for last 30 days), $2 = limit
-- Returns: Most-used brews in time period
-- Usage: "Trending brews" section
-- Performance: Uses idx_post_brew_id and idx_post_created_at
-- name: GetPopularBrews :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(p.id) as post_count,
    AVG(p.rating) as avg_rating
FROM brew b
JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true
    AND p.created_at > NOW() - INTERVAL '1 day' * $1
    AND p.visibility = 'public'
GROUP BY b.id
HAVING COUNT(p.id) >= 3
ORDER BY post_count DESC, avg_rating DESC
LIMIT $2;


-- 8. GET POPULAR POSTS
-- Parameters: $1 = days (time window), $2 = limit
-- Returns: Posts with most engagement (likes + comments)
-- Usage: "Trending posts" feed
-- Performance: Aggregates engagement metrics
-- name: GetPopularPosts :many
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
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count,
    (COUNT(DISTINCT pl.user_id) + COUNT(DISTINCT c.id)) as engagement_score
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.visibility = 'public'
    AND p.created_at > NOW() - INTERVAL '1 day' * $1
GROUP BY p.id, u.id, u.username, u.profile_picture_url, b.name
HAVING (COUNT(DISTINCT pl.user_id) + COUNT(DISTINCT c.id)) > 0
ORDER BY engagement_score DESC, p.created_at DESC
LIMIT $2;


-- 9. GET TOP RATED BREWS
-- Parameters: $1 = minimum_post_count, $2 = limit
-- Returns: Highest-rated brews with enough posts for statistical validity
-- Usage: "Best brews" discovery
-- name: GetTopRatedBrews :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(p.id) as post_count,
    AVG(p.rating) as avg_rating,
    MAX(p.rating) as max_rating,
    MIN(p.rating) as min_rating
FROM brew b
JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true AND p.visibility = 'public'
GROUP BY b.id
HAVING COUNT(p.id) >= $1
ORDER BY avg_rating DESC, post_count DESC
LIMIT $2;


-- 10. GET ACTIVE USERS
-- Parameters: $1 = days (time window), $2 = limit
-- Returns: Most active users by post count in time period
-- Usage: "Active brewers" leaderboard
-- name: GetActiveUsers :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    COUNT(p.id) as post_count,
    AVG(p.rating) as avg_rating
FROM "user" u
JOIN post p ON u.id = p.owner_id
WHERE p.created_at > NOW() - INTERVAL '1 day' * $1
GROUP BY u.id
ORDER BY post_count DESC
LIMIT $2;


-- ----------------------------------------------------------------------------
-- RECOMMENDATIONS
-- ----------------------------------------------------------------------------

-- 11. GET SIMILAR BREWS
-- Parameters: $1 = brew_id
-- Returns: Brews with similar characteristics (same method or origin)
-- Usage: "You might also like" recommendations
-- name: GetSimilarBrews :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    b.bean_origin,
    b.roaster,
    COUNT(p.id) as usage_count
FROM brew b
LEFT JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true
    AND b.id != $1
    AND (
        b.brew_method = (SELECT brew_method FROM brew WHERE id = $1)
        OR b.bean_origin = (SELECT bean_origin FROM brew WHERE id = $1)
    )
GROUP BY b.id
ORDER BY usage_count DESC
LIMIT 10;


-- 12. GET SUGGESTED FRIENDS
-- Parameters: $1 = current_user_id, $2 = limit
-- Returns: Users with mutual friends (friend-of-friend suggestions)
-- Usage: "People you may know" recommendations
-- name: GetSuggestedFriends :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    u.bio,
    COUNT(DISTINCT mf.friend_id) as mutual_friend_count
FROM "user" u
JOIN user_friendships fof ON u.id = fof.user_id
JOIN user_friendships mf ON fof.friend_id = mf.friend_id
WHERE mf.user_id = $1
    AND mf.status = 'accepted'
    AND fof.status = 'accepted'
    AND u.id != $1
    AND NOT EXISTS (
        SELECT 1 FROM user_friendships
        WHERE user_id = $1 AND friend_id = u.id
    )
GROUP BY u.id
ORDER BY mutual_friend_count DESC
LIMIT $2;


-- 13. GET RECENTLY JOINED USERS
-- Parameters: $1 = days, $2 = limit
-- Returns: Users who joined recently
-- Usage: "New to the community" section
-- name: GetRecentlyJoinedUsers :many
SELECT
    id,
    username,
    profile_picture_url,
    bio,
    joined_at
FROM "user"
WHERE joined_at > NOW() - INTERVAL '1 day' * $1
ORDER BY joined_at DESC
LIMIT $2;
