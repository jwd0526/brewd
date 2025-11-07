-- ============================================================================
-- NOTIFICATION QUERIES
-- ============================================================================
-- Operations for user notifications: create, fetch, mark as read


-- ----------------------------------------------------------------------------
-- 1. CREATE NOTIFICATION
-- ----------------------------------------------------------------------------
-- Parameters: $1 = id (ULID), $2 = recipient_user_id, $3 = actor_user_id,
--             $4 = type, $5 = reference_id, $6 = reference_type
-- Returns: Created notification record
-- Usage: Notify user of actions (like, comment, friend request, tag)
-- Types: 'like', 'comment', 'friend_request', 'tag', 'follow'
-- Reference types: 'post', 'comment', 'friendship'
-- name: CreateNotification :one
INSERT INTO notification (id, recipient_user_id, actor_user_id, type, reference_id, reference_type)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, recipient_user_id, actor_user_id, type, reference_id, reference_type, is_read, created_at;


-- ----------------------------------------------------------------------------
-- 2. GET UNREAD NOTIFICATIONS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = limit
-- Returns: Unread notifications with actor info
-- Usage: Show notification dropdown/badge
-- Performance: Uses idx_notification_is_read
-- name: GetUnreadNotifications :many
SELECT
    n.id,
    n.type,
    n.reference_id,
    n.reference_type,
    n.created_at,
    u.id as actor_id,
    u.username as actor_username,
    u.profile_picture_url as actor_profile_picture
FROM notification n
JOIN "user" u ON n.actor_user_id = u.id
WHERE n.recipient_user_id = $1 AND n.is_read = false
ORDER BY n.created_at DESC
LIMIT $2;


-- ----------------------------------------------------------------------------
-- 3. GET ALL NOTIFICATIONS (Read and Unread)
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = limit, $3 = offset
-- Returns: All notifications with actor info, paginated
-- Usage: Notification history page
-- Performance: Uses idx_notification_recipient
-- name: GetAllNotifications :many
SELECT
    n.id,
    n.type,
    n.reference_id,
    n.reference_type,
    n.is_read,
    n.created_at,
    u.id as actor_id,
    u.username as actor_username,
    u.profile_picture_url as actor_profile_picture
FROM notification n
JOIN "user" u ON n.actor_user_id = u.id
WHERE n.recipient_user_id = $1
ORDER BY n.created_at DESC
LIMIT $2 OFFSET $3;


-- ----------------------------------------------------------------------------
-- 4. MARK NOTIFICATION AS READ
-- ----------------------------------------------------------------------------
-- Parameters: $1 = notification_id, $2 = recipient_user_id
-- Returns: Updated notification
-- Usage: User clicks on a notification
-- Note: Includes recipient_user_id check for security
-- name: MarkNotificationAsRead :one
UPDATE notification
SET is_read = true
WHERE id = $1 AND recipient_user_id = $2
RETURNING id, is_read;


-- ----------------------------------------------------------------------------
-- 5. MARK MULTIPLE NOTIFICATIONS AS READ
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = array of notification_ids
-- Returns: Number of updated notifications
-- Usage: "Mark all as read" or batch mark
-- Note: ANY($2) allows passing array of IDs
-- name: MarkMultipleNotificationsAsRead :many
UPDATE notification
SET is_read = true
WHERE recipient_user_id = $1 AND id = ANY($2)
RETURNING id;


-- ----------------------------------------------------------------------------
-- 6. MARK ALL NOTIFICATIONS AS READ
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id
-- Returns: Number of updated notifications
-- Usage: "Mark all as read" button
-- name: MarkAllNotificationsAsRead :many
UPDATE notification
SET is_read = true
WHERE recipient_user_id = $1 AND is_read = false
RETURNING id;


-- ----------------------------------------------------------------------------
-- 7. DELETE NOTIFICATION
-- ----------------------------------------------------------------------------
-- Parameters: $1 = notification_id, $2 = recipient_user_id
-- Returns: Deleted notification id
-- Usage: User dismisses a notification
-- Note: Includes recipient_user_id check for security
-- name: DeleteNotification :one
DELETE FROM notification
WHERE id = $1 AND recipient_user_id = $2
RETURNING id;


-- ----------------------------------------------------------------------------
-- 8. GET UNREAD NOTIFICATION COUNT
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id
-- Returns: Number of unread notifications
-- Usage: Display badge count on notification bell
-- name: GetUnreadNotificationCount :one
SELECT COUNT(*) as unread_count
FROM notification
WHERE recipient_user_id = $1 AND is_read = false;


-- ----------------------------------------------------------------------------
-- 9. GET NOTIFICATIONS BY TYPE
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = type, $3 = limit, $4 = offset
-- Returns: Notifications filtered by type
-- Usage: Filter notifications (e.g., show only 'like' notifications)
-- Performance: Uses idx_notification_type
-- name: GetNotificationsByType :many
SELECT
    n.id,
    n.type,
    n.reference_id,
    n.reference_type,
    n.is_read,
    n.created_at,
    u.id as actor_id,
    u.username as actor_username,
    u.profile_picture_url as actor_profile_picture
FROM notification n
JOIN "user" u ON n.actor_user_id = u.id
WHERE n.recipient_user_id = $1 AND n.type = $2
ORDER BY n.created_at DESC
LIMIT $3 OFFSET $4;


-- ----------------------------------------------------------------------------
-- 10. DELETE OLD READ NOTIFICATIONS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = days_old (e.g., 30)
-- Returns: Number of deleted notifications
-- Usage: Cleanup old notifications (scheduled job)
-- Note: Only deletes READ notifications older than X days
-- name: DeleteOldReadNotifications :many
DELETE FROM notification
WHERE recipient_user_id = $1
    AND is_read = true
    AND created_at < NOW() - INTERVAL '1 day' * $2
RETURNING id;


-- ----------------------------------------------------------------------------
-- 11. GET NOTIFICATION WITH DETAILS
-- ----------------------------------------------------------------------------
-- Parameters: $1 = notification_id
-- Returns: Notification with full context (actor, reference object)
-- Usage: Display rich notification with post/comment preview
-- Note: This is a base query - you may need to join additional tables
--       based on reference_type (post, comment, etc.)
-- name: GetNotificationWithDetails :one
SELECT
    n.*,
    actor.id as actor_id,
    actor.username as actor_username,
    actor.profile_picture_url as actor_profile_picture,
    recipient.id as recipient_id,
    recipient.username as recipient_username
FROM notification n
JOIN "user" actor ON n.actor_user_id = actor.id
JOIN "user" recipient ON n.recipient_user_id = recipient.id
WHERE n.id = $1;


-- ----------------------------------------------------------------------------
-- 12. CHECK FOR DUPLICATE NOTIFICATION
-- ----------------------------------------------------------------------------
-- Parameters: $1 = recipient_user_id, $2 = actor_user_id, $3 = type,
--             $4 = reference_id, $5 = hours (e.g., 24)
-- Returns: Boolean (true if duplicate exists)
-- Usage: Prevent duplicate notifications within time window
-- Example: Don't notify twice if same user likes and unlikes quickly
-- name: CheckForDuplicateNotification :one
SELECT EXISTS (
    SELECT 1 FROM notification
    WHERE recipient_user_id = $1
        AND actor_user_id = $2
        AND type = $3
        AND reference_id = $4
        AND created_at > NOW() - INTERVAL '1 hour' * $5
) as duplicate_exists;
