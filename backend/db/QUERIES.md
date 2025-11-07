# Database Queries Reference

This document provides a quick reference for all SQL queries in the brewd database. Each query is implemented with sqlc annotations for type-safe Go code generation.

---

## User Queries (`queries/user.sql`)

### User Management
- **CreateUser** - Creates a new user account with username, email, and hashed password
- **GetUserByID** - Retrieves a user's profile information by their ID
- **GetUserByUsername** - Finds a user by their username for login or profile lookup
- **GetUserByEmail** - Looks up a user by email address for authentication
- **UpdateUserProfile** - Updates user profile fields (bio, location, profile picture)
- **UpdateUserPassword** - Changes a user's password hash

### User Activity
- **GetUserPostCount** - Returns the total number of posts created by a user
- **SearchUsersByUsernameBasic** - Simple username search returning basic user info (max 20 results)
- **CheckUsernameAvailability** - Validates if a username is available during registration
- **CheckEmailAvailability** - Validates if an email is available during registration

---

## Post Queries (`queries/post.sql`)

### Post Management
- **CreatePost** - Creates a new coffee brew post with title, description, rating, and visibility
- **GetPostWithDetails** - Retrieves complete post info including owner, brew, media, likes, and comments
- **UpdatePost** - Updates post fields (title, description, rating, visibility)
- **DeletePost** - Removes a post and all associated media, likes, and comments (CASCADE)

### Feed Generation
- **GetUserFeed** - Main feed showing posts from friends, sorted by recency with pagination
- **GetPublicPosts** - Discovery feed of public posts from all users for non-friends
- **GetUserPosts** - All posts created by a specific user for their profile page

### Post Filtering
- **GetPostsByBrew** - Shows all posts that used a specific coffee brew

### Media Management
- **AddMediaToPost** - Attaches an image or video to a post with display order
- **GetMediaForPost** - Retrieves all media items for a post, ordered by display_order

---

## Friendship Queries (`queries/friendship.sql`)

### Friend Requests
- **SendFriendRequest** - User A sends a friend request to User B (creates 'pending' row)
- **AcceptFriendRequestUpdate** - Updates pending request to 'accepted' (use in transaction)
- **AcceptFriendRequestInsert** - Creates reverse friendship row (use in transaction)
- **RejectFriendRequest** - Declines incoming request or cancels outgoing request

### Friend Lists
- **GetFriendList** - Returns all accepted friends for a user with profile details
- **GetPendingRequestsReceived** - Shows incoming friend requests waiting for acceptance
- **GetPendingRequestsSent** - Shows outgoing friend requests user has sent
- **GetMutualFriends** - Finds friends shared between two users

### Friendship Status
- **CheckFriendshipStatus** - Returns relationship status between two users (pending/accepted/blocked)
- **AreUsersFriends** - Quick boolean check if two users are friends
- **GetFriendCount** - Returns total number of accepted friends for a user
- **Unfriend** - Removes friendship between two users (deletes both rows, use transaction)

### Blocking
- **BlockUser** - Blocks another user (one-directional)
- **UnblockUser** - Removes block on another user
- **GetBlockedUsers** - Lists all users blocked by current user

---

## Interaction Queries (`queries/interaction.sql`)

### Post Likes
- **LikePost** - User likes a post (idempotent with ON CONFLICT)
- **UnlikePost** - User removes their like from a post
- **GetPostLikers** - Returns list of users who liked a post with pagination
- **GetPostLikeCount** - Returns total number of likes on a post
- **CheckUserLikedPost** - Boolean check if user has liked a specific post

### Comment Likes
- **LikeComment** - User likes a comment (idempotent)
- **UnlikeComment** - User removes their like from a comment
- **GetCommentLikeCount** - Returns total number of likes on a comment

### Comments
- **AddComment** - Creates a top-level comment on a post
- **AddReply** - Creates a threaded reply to an existing comment
- **GetCommentsForPost** - Retrieves top-level comments with reply count and likes
- **GetRepliesToComment** - Fetches nested replies for a specific comment
- **UpdateComment** - Edits comment content and updates timestamp
- **DeleteComment** - Removes comment and all replies (CASCADE)
- **GetCommentCount** - Returns total comments including replies for a post
- **GetTopLevelCommentCount** - Returns only top-level comment count (excludes replies)

### User Tagging
- **TagUserInPost** - Tags a friend in a coffee post (triggers notification)
- **UntagUserFromPost** - Removes user tag from a post
- **GetUsersTaggedInPost** - Lists all users tagged in a specific post
- **GetPostsWhereUserIsTagged** - Shows posts where user has been tagged

---

## Notification Queries (`queries/notification.sql`)

### Create & Fetch
- **CreateNotification** - Creates notification for user action (like, comment, friend request, tag)
- **GetUnreadNotifications** - Retrieves unread notifications with actor info for badge/dropdown
- **GetAllNotifications** - Paginated list of all notifications (read and unread)
- **GetNotificationsByType** - Filters notifications by type (like, comment, friend_request, etc.)
- **GetNotificationWithDetails** - Full notification context with actor and reference object

### Mark as Read
- **MarkNotificationAsRead** - Marks single notification as read when user clicks it
- **MarkMultipleNotificationsAsRead** - Batch marks notifications as read by ID array
- **MarkAllNotificationsAsRead** - Marks all unread notifications as read

### Notification Management
- **GetUnreadNotificationCount** - Returns count for notification bell badge
- **DeleteNotification** - User dismisses a notification
- **DeleteOldReadNotifications** - Cleanup job to remove old read notifications (30+ days)
- **CheckForDuplicateNotification** - Prevents duplicate notifications within time window

---

## Search Queries (`queries/search.sql`)

### User Search
- **SearchUsersByUsername** - Searches users by username with stats (post/friend counts)
- **SearchUsersWithStats** - Enhanced user search with activity indicators

### Brew Search
- **SearchBrews** - Searches brews by name, method, origin, or roaster with usage count
- **SearchBrewsByMethod** - Filters brews by specific brewing method (exact match)
- **SearchBrewsByRoaster** - Finds all brews from a specific roaster

### Post Search
- **SearchPosts** - Searches posts by title and description with engagement metrics

### Popular Content
- **GetPopularBrews** - Most-used brews in time period (trending brews)
- **GetPopularPosts** - Posts with most engagement (likes + comments) for trending feed
- **GetTopRatedBrews** - Highest-rated brews with minimum post count for validity
- **GetActiveUsers** - Most active users by post count for leaderboard

### Recommendations
- **GetSimilarBrews** - Brews with similar method or origin for "you might also like"
- **GetSuggestedFriends** - Friend-of-friend suggestions based on mutual friends
- **GetRecentlyJoinedUsers** - Users who joined recently for "new to community" section

---

## Analytics Queries (`queries/analytics.sql`)

### User Analytics
- **GetUserActivityStats** - Comprehensive user statistics (posts, ratings, likes, comments, friends)
- **GetUserPostingActivityOverTime** - Posts per day for activity graph on profile
- **GetUserFavoriteBrewMethods** - Brew methods user posts about most with ratings
- **GetUserTopBrews** - Brews user has posted about most for "your top brews" section

### Platform Analytics
- **GetPlatformOverviewStats** - Platform-wide stats (users, posts, brews, friendships, engagement)
- **GetDailyActiveUsers** - DAU tracking by posts, likes, and comments per day
- **GetGrowthMetrics** - New users, posts, and friendships over time for growth dashboard

### Content Analytics
- **GetBrewMethodDistribution** - Usage statistics by brew method for charts
- **GetRatingDistribution** - Count of posts by rating for distribution chart
- **GetTopContributors** - Most active users by weighted activity score (posts, comments, likes)

### Engagement Analytics
- **GetAverageEngagementByPost** - Average likes and comments per post for health metrics
- **GetEngagementRateByUser** - User's posts with engagement metrics to show best performers
- **GetMostEngagingContent** - Posts with highest engagement for viral content identification

### Retention Analytics
- **GetUserRetentionByCohort** - Cohort retention analysis by join month and activity
- **GetInactiveUsers** - Users with no recent activity for re-engagement campaigns

---

## Query Execution Notes

### Return Types
- `:one` - Returns single row (GetUserByID, CheckUsernameAvailability, etc.)
- `:many` - Returns multiple rows (GetUserFeed, SearchBrews, etc.)
- `:exec` - No return data (Unfriend)

### Transaction Requirements
Some queries MUST be wrapped in transactions in application code:
- **AcceptFriendRequest** - Use AcceptFriendRequestUpdate + AcceptFriendRequestInsert together
- **Unfriend** - Deletes both friendship rows, must verify 2 rows affected

### Performance Considerations
- Search queries with ILIKE patterns starting with `%` cannot use indexes
- Queries with multiple JOINs and aggregations may need query plan optimization
- Pagination (LIMIT/OFFSET) is implemented for large result sets
- Composite indexes support multi-column filters (e.g., notification type + read status)

---

**Total Queries: 94 across 7 query files**
