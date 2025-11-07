-- ============================================================================
-- ANALYTICS QUERIES
-- ============================================================================
-- Operations for statistics, metrics, and insights


-- ----------------------------------------------------------------------------
-- USER ANALYTICS
-- ----------------------------------------------------------------------------

-- 1. GET USER ACTIVITY STATS
-- Parameters: $1 = user_id
-- Returns: Comprehensive user statistics
-- Usage: User dashboard, admin analytics, insights page
-- Note: Uses subqueries to prevent Cartesian product and ensure accurate counts
-- name: GetUserActivityStats :one
SELECT
    u.id,
    u.username,
    u.joined_at,
    (SELECT COUNT(*) FROM post WHERE owner_id = u.id) as total_posts,
    (SELECT COALESCE(AVG(rating), 0) FROM post WHERE owner_id = u.id) as avg_rating,
    (SELECT COUNT(DISTINCT pl.user_id)
     FROM post p
     LEFT JOIN post_likes pl ON p.id = pl.post_id
     WHERE p.owner_id = u.id) as total_likes_received,
    (SELECT COUNT(DISTINCT c.id)
     FROM post p
     LEFT JOIN comment c ON p.id = c.post_id
     WHERE p.owner_id = u.id) as total_comments_received,
    (SELECT COUNT(*) FROM user_friendships WHERE user_id = u.id AND status = 'accepted') as friend_count,
    (SELECT COUNT(*) FROM post_likes WHERE user_id = u.id) as total_likes_given,
    (SELECT COUNT(*) FROM comment WHERE owner_id = u.id) as total_comments_given
FROM "user" u
WHERE u.id = $1;


-- 2. GET USER POSTING ACTIVITY OVER TIME
-- Parameters: $1 = user_id, $2 = days (e.g., 30)
-- Returns: Posts per day in time period
-- Usage: Activity graph on profile
-- name: GetUserPostingActivityOverTime :many
SELECT
    DATE(p.created_at) as post_date,
    COUNT(*) as post_count
FROM post p
WHERE p.owner_id = $1
    AND p.created_at > NOW() - INTERVAL '1 day' * $2
GROUP BY DATE(p.created_at)
ORDER BY post_date DESC;


-- 3. GET USER'S FAVORITE BREW METHODS
-- Parameters: $1 = user_id
-- Returns: Brew methods user posts about most
-- Usage: User preferences insights
-- name: GetUserFavoriteBrewMethods :many
SELECT
    b.brew_method,
    COUNT(p.id) as usage_count,
    AVG(p.rating) as avg_rating
FROM post p
JOIN brew b ON p.brew_id = b.id
WHERE p.owner_id = $1 AND b.brew_method IS NOT NULL
GROUP BY b.brew_method
ORDER BY usage_count DESC;


-- 4. GET USER'S TOP BREWS
-- Parameters: $1 = user_id, $2 = limit
-- Returns: Brews user has posted about most
-- Usage: "Your top brews" section
-- name: GetUserTopBrews :many
SELECT
    b.id,
    b.name,
    b.brew_method,
    COUNT(p.id) as post_count,
    AVG(p.rating) as avg_rating,
    MAX(p.created_at) as last_posted
FROM brew b
JOIN post p ON b.id = p.brew_id
WHERE p.owner_id = $1
GROUP BY b.id
ORDER BY post_count DESC, avg_rating DESC
LIMIT $2;


-- ----------------------------------------------------------------------------
-- PLATFORM ANALYTICS
-- ----------------------------------------------------------------------------

-- 5. GET PLATFORM OVERVIEW STATS
-- Parameters: None
-- Returns: Platform-wide statistics
-- Usage: Admin dashboard, homepage stats
-- name: GetPlatformOverviewStats :one
SELECT
    (SELECT COUNT(*) FROM "user") as total_users,
    (SELECT COUNT(*) FROM post) as total_posts,
    (SELECT COUNT(*) FROM brew WHERE is_public = true) as total_public_brews,
    (SELECT COUNT(*) FROM user_friendships WHERE status = 'accepted') / 2 as total_friendships,
    (SELECT COUNT(*) FROM post_likes) as total_likes,
    (SELECT COUNT(*) FROM comment) as total_comments,
    (SELECT COALESCE(AVG(rating), 0) FROM post) as avg_post_rating;


-- 6. GET DAILY ACTIVE USERS
-- Parameters: $1 = days_back (e.g., 7 for last week)
-- Returns: Count of users who posted, liked, or commented each day
-- Usage: DAU/MAU tracking
-- name: GetDailyActiveUsers :many
SELECT
    activity_date,
    COUNT(DISTINCT user_id) as active_users
FROM (
    SELECT owner_id as user_id, DATE(created_at) as activity_date
    FROM post
    WHERE created_at > NOW() - INTERVAL '1 day' * $1

    UNION ALL

    SELECT user_id, DATE(created_at) as activity_date
    FROM post_likes
    WHERE created_at > NOW() - INTERVAL '1 day' * $1

    UNION ALL

    SELECT owner_id as user_id, DATE(created_at) as activity_date
    FROM comment
    WHERE created_at > NOW() - INTERVAL '1 day' * $1
) activities
GROUP BY activity_date
ORDER BY activity_date DESC;


-- 7. GET GROWTH METRICS
-- Parameters: $1 = days (time window)
-- Returns: New users, posts, and engagement over time
-- Usage: Growth tracking dashboard
-- name: GetGrowthMetrics :many
SELECT
    'users' as metric,
    COUNT(*) as count,
    DATE(joined_at) as metric_date
FROM "user"
WHERE joined_at > NOW() - INTERVAL '1 day' * $1
GROUP BY DATE(joined_at)

UNION ALL

SELECT
    'posts' as metric,
    COUNT(*) as count,
    DATE(created_at) as metric_date
FROM post
WHERE created_at > NOW() - INTERVAL '1 day' * $1
GROUP BY DATE(created_at)

UNION ALL

SELECT
    'friendships' as metric,
    COUNT(*) as count,
    DATE(created_at) as metric_date
FROM user_friendships
WHERE status = 'accepted'
    AND created_at > NOW() - INTERVAL '1 day' * $1
GROUP BY DATE(created_at)

ORDER BY metric, metric_date DESC;


-- ----------------------------------------------------------------------------
-- CONTENT ANALYTICS
-- ----------------------------------------------------------------------------

-- 8. GET BREW METHOD DISTRIBUTION
-- Parameters: None
-- Returns: Usage statistics by brew method
-- Usage: "Most popular brew methods" chart
-- name: GetBrewMethodDistribution :many
SELECT
    brew_method,
    COUNT(DISTINCT b.id) as brew_count,
    COUNT(DISTINCT p.id) as post_count,
    AVG(p.rating) as avg_rating
FROM brew b
LEFT JOIN post p ON b.id = p.brew_id
WHERE b.is_public = true AND b.brew_method IS NOT NULL
GROUP BY brew_method
ORDER BY post_count DESC;


-- 9. GET RATING DISTRIBUTION
-- Parameters: None
-- Returns: Count of posts by rating
-- Usage: Rating distribution chart
-- name: GetRatingDistribution :many
SELECT
    rating,
    COUNT(*) as post_count
FROM post
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY rating DESC;


-- 10. GET TOP CONTRIBUTORS
-- Parameters: $1 = days (time window), $2 = limit
-- Returns: Most active users by various metrics
-- Usage: "Top contributors" leaderboard
-- name: GetTopContributors :many
SELECT
    u.id,
    u.username,
    u.profile_picture_url,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT c.id) as comment_count,
    COUNT(DISTINCT pl.post_id) as like_count,
    (COUNT(DISTINCT p.id) * 10 + COUNT(DISTINCT c.id) * 3 + COUNT(DISTINCT pl.post_id)) as activity_score
FROM "user" u
LEFT JOIN post p ON u.id = p.owner_id AND p.created_at > NOW() - INTERVAL '1 day' * $1
LEFT JOIN comment c ON u.id = c.owner_id AND c.created_at > NOW() - INTERVAL '1 day' * $1
LEFT JOIN post_likes pl ON u.id = pl.user_id AND pl.created_at > NOW() - INTERVAL '1 day' * $1
GROUP BY u.id
HAVING COUNT(DISTINCT p.id) > 0 OR COUNT(DISTINCT c.id) > 0 OR COUNT(DISTINCT pl.post_id) > 0
ORDER BY activity_score DESC
LIMIT $2;


-- ----------------------------------------------------------------------------
-- ENGAGEMENT ANALYTICS
-- ----------------------------------------------------------------------------

-- 11. GET AVERAGE ENGAGEMENT BY POST
-- Parameters: None
-- Returns: Average likes and comments per post
-- Usage: Platform health metrics
-- name: GetAverageEngagementByPost :one
SELECT
    AVG(like_count) as avg_likes_per_post,
    AVG(comment_count) as avg_comments_per_post,
    AVG(like_count + comment_count) as avg_engagement_per_post
FROM (
    SELECT
        p.id,
        COUNT(DISTINCT pl.user_id) as like_count,
        COUNT(DISTINCT c.id) as comment_count
    FROM post p
    LEFT JOIN post_likes pl ON p.id = pl.post_id
    LEFT JOIN comment c ON p.id = c.post_id
    GROUP BY p.id
) post_engagement;


-- 12. GET ENGAGEMENT RATE BY USER
-- Parameters: $1 = user_id
-- Returns: User's posts with engagement metrics
-- Usage: Show user which posts performed best
-- name: GetEngagementRateByUser :many
SELECT
    p.id,
    p.title,
    p.created_at,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count,
    (COUNT(DISTINCT pl.user_id) + COUNT(DISTINCT c.id)) as total_engagement
FROM post p
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.owner_id = $1
GROUP BY p.id
ORDER BY total_engagement DESC;


-- 13. GET MOST ENGAGING CONTENT
-- Parameters: $1 = days, $2 = limit
-- Returns: Posts with highest engagement rate
-- Usage: Identify viral content
-- name: GetMostEngagingContent :many
SELECT
    p.id,
    p.title,
    p.created_at,
    u.username,
    b.name as brew_name,
    COUNT(DISTINCT pl.user_id) as like_count,
    COUNT(DISTINCT c.id) as comment_count,
    (COUNT(DISTINCT pl.user_id) + COUNT(DISTINCT c.id) * 2) as engagement_score
FROM post p
JOIN "user" u ON p.owner_id = u.id
LEFT JOIN brew b ON p.brew_id = b.id
LEFT JOIN post_likes pl ON p.id = pl.post_id
LEFT JOIN comment c ON p.id = c.post_id
WHERE p.created_at > NOW() - INTERVAL '1 day' * $1
    AND p.visibility = 'public'
GROUP BY p.id, u.username, b.name
HAVING (COUNT(DISTINCT pl.user_id) + COUNT(DISTINCT c.id)) > 0
ORDER BY engagement_score DESC
LIMIT $2;


-- ----------------------------------------------------------------------------
-- RETENTION & COHORT ANALYSIS
-- ----------------------------------------------------------------------------

-- 14. GET USER RETENTION BY COHORT
-- Parameters: $1 = cohort_month (e.g., '2024-01')
-- Returns: Users who joined in cohort and posted in subsequent months
-- Usage: Retention analysis
-- name: GetUserRetentionByCohort :many
SELECT
    DATE_TRUNC('month', p.created_at) as activity_month,
    COUNT(DISTINCT p.owner_id) as active_users,
    (SELECT COUNT(*) FROM "user" u2 WHERE DATE_TRUNC('month', u2.joined_at) = $1) as cohort_size,
    ROUND(
        COUNT(DISTINCT p.owner_id)::numeric /
        (SELECT COUNT(*) FROM "user" u3 WHERE DATE_TRUNC('month', u3.joined_at) = $1) * 100,
        2
    ) as retention_rate
FROM post p
JOIN "user" u ON p.owner_id = u.id
WHERE DATE_TRUNC('month', u.joined_at) = $1
GROUP BY DATE_TRUNC('month', p.created_at)
ORDER BY activity_month;


-- 15. GET INACTIVE USERS
-- Parameters: $1 = days_inactive (e.g., 30)
-- Returns: Users who haven't posted, liked, or commented recently
-- Usage: Re-engagement campaigns
-- name: GetInactiveUsers :many
SELECT
    u.id,
    u.username,
    u.email,
    u.joined_at,
    MAX(GREATEST(
        COALESCE(p.created_at, '1970-01-01'::timestamp),
        COALESCE(pl.created_at, '1970-01-01'::timestamp),
        COALESCE(c.created_at, '1970-01-01'::timestamp)
    )) as last_activity
FROM "user" u
LEFT JOIN post p ON u.id = p.owner_id
LEFT JOIN post_likes pl ON u.id = pl.user_id
LEFT JOIN comment c ON u.id = c.owner_id
GROUP BY u.id
HAVING MAX(GREATEST(
    COALESCE(p.created_at, '1970-01-01'::timestamp),
    COALESCE(pl.created_at, '1970-01-01'::timestamp),
    COALESCE(c.created_at, '1970-01-01'::timestamp)
)) < NOW() - INTERVAL '1 day' * $1
ORDER BY last_activity ASC;
