-- ============================================================================
-- USER QUERIES
-- ============================================================================
-- Operations for user management: registration, profiles, search, and stats


-- ----------------------------------------------------------------------------
-- 1. CREATE USER (Registration)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = id (ULID), $2 = username, $3 = email, $4 = password_hash
-- Returns: The created user record
-- Usage: Called during user registration
-- name: CreateUser :one
INSERT INTO "user" (id, username, email, password_hash, joined_at)
VALUES ($1, $2, $3, $4, NOW())
RETURNING id, username, email, joined_at, created_at;


-- ----------------------------------------------------------------------------
-- 2. GET USER BY ID
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id
-- Returns: Single user record (excludes password_hash for security)
-- Usage: View user profiles, verify authentication
-- name: GetUserByID :one
SELECT id, username, email, profile_picture_url, bio, location, joined_at
FROM "user"
WHERE id = $1;


-- ----------------------------------------------------------------------------
-- 3. GET USER BY EMAIL (Authentication)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = email
-- Returns: User record including password_hash for authentication
-- Usage: Login verification (compare hashed passwords)
-- name: GetUserByEmail :one
SELECT id, username, email, password_hash, profile_picture_url
FROM "user"
WHERE email = $1;


-- ----------------------------------------------------------------------------
-- 4. GET USER BY USERNAME
-- ----------------------------------------------------------------------------
-- Parameters: $1 = username
-- Returns: Single user record
-- Usage: View profiles by username, check username availability
-- name: GetUserByUsername :one
SELECT id, username, email, profile_picture_url, bio, location, joined_at
FROM "user"
WHERE username = $1;


-- ----------------------------------------------------------------------------
-- 5. UPDATE USER PROFILE
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = profile_picture_url, $3 = bio, $4 = location
-- Returns: Updated user record
-- Usage: User edits their profile
-- name: UpdateUserProfile :one
UPDATE "user"
SET
    profile_picture_url = COALESCE($2, profile_picture_url),
    bio = COALESCE($3, bio),
    location = COALESCE($4, location),
    updated_at = NOW()
WHERE id = $1
RETURNING id, username, email, profile_picture_url, bio, location, updated_at;


-- ----------------------------------------------------------------------------
-- 6. GET USER PROFILE WITH STATS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id
-- Returns: User info + post_count, friend_count, avg_rating
-- Usage: Display rich user profiles with activity statistics
-- Performance: Uses LEFT JOINs and aggregations, leverages multiple indexes
-- name: GetUserProfileWithStats :one
SELECT
    u.id,
    u.username,
    u.email,
    u.profile_picture_url,
    u.bio,
    u.location,
    u.joined_at,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT f.friend_id) as friend_count,
    COALESCE(AVG(p.rating), 0) as avg_rating
FROM "user" u
LEFT JOIN post p ON u.id = p.owner_id
LEFT JOIN user_friendships f ON u.id = f.user_id AND f.status = 'accepted'
WHERE u.id = $1
GROUP BY u.id;


-- ----------------------------------------------------------------------------
-- 7. SEARCH USERS BY USERNAME
-- ----------------------------------------------------------------------------
-- Parameters: $1 = search_term (use '%term%' for contains, 'term%' for starts with)
-- Returns: List of matching users (max 20)
-- Usage: User search/discovery feature
-- Performance: Uses idx_user_username, fast if pattern doesn't start with %
-- name: SearchUsersByUsernameBasic :many
SELECT id, username, profile_picture_url, bio
FROM "user"
WHERE username ILIKE $1
ORDER BY username
LIMIT 20;


-- ----------------------------------------------------------------------------
-- 8. CHECK USERNAME AVAILABILITY
-- ----------------------------------------------------------------------------
-- Parameters: $1 = username
-- Returns: Boolean (true if available, false if taken)
-- Usage: Real-time validation during registration
-- name: CheckUsernameAvailability :one
SELECT NOT EXISTS (
    SELECT 1 FROM "user" WHERE username = $1
) as available;


-- ----------------------------------------------------------------------------
-- 9. CHECK EMAIL AVAILABILITY
-- ----------------------------------------------------------------------------
-- Parameters: $1 = email
-- Returns: Boolean (true if available, false if taken)
-- Usage: Real-time validation during registration
-- name: CheckEmailAvailability :one
SELECT NOT EXISTS (
    SELECT 1 FROM "user" WHERE email = $1
) as available;


-- ----------------------------------------------------------------------------
-- 10. UPDATE PASSWORD
-- ----------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = new_password_hash
-- Returns: Success confirmation
-- Usage: Password reset/change functionality
-- name: UpdatePassword :one
UPDATE "user"
SET
    password_hash = $2,
    updated_at = NOW()
WHERE id = $1
RETURNING id, email;
