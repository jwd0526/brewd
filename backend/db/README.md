# Coffee Social Platform - Database Schema

A social media platform for coffee enthusiasts to share, rate, and discover coffee brews. Inspired by Untappd.

## Core Objects

### User

Represents a user account on the platform.

```sql
CREATE TABLE user {
    id ulid PRIMARY KEY,
    username varchar UNIQUE NOT NULL,
    email varchar UNIQUE NOT NULL,
    password_hash varchar NOT NULL,
    profile_picture_url text,
    bio text,
    location text,
    joined_at timestamp DEFAULT NOW(),
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier (ULID format)
- `username` - Unique username for the user
- `email` - User's email address
- `profile_picture_url` - URL to profile image
- `bio` - User's bio/description
- `location` - User's location (free text)
- `joined_at` - When the user created their account

**Relationships:**
- Has many Posts (via `owner_id`)
- Has many Comments (via `owner_id`)
- Has many Friendships (via `user_friendships`)
- Has many Notifications (via `recipient_user_id`)



### Post

The main content unit representing a coffee brew that a user has made and rated.

```sql
CREATE TABLE post {
    id ulid PRIMARY KEY,
    owner_id ulid REFERENCES user(id) ON DELETE CASCADE,
    brew_id ulid REFERENCES brew(id),
    title varchar NOT NULL,
    description text,
    rating decimal(2,1) CHECK (rating >= 0 AND rating <= 5),
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier
- `owner_id` - User who created the post
- `brew_id` - The brew/coffee type being reviewed
- `title` - Post title
- `description` - Detailed description or notes
- `rating` - User's rating of their own brew (0-5 scale)

**Relationships:**
- Belongs to User (owner)
- Belongs to Brew
- Has many Media (photos/videos)
- Has many Comments
- Has many Likes (via `post_likes`)
- Has many Tags (via `post_user_tags`)


### Brew

Represents a type of coffee or specific brew configuration.

```sql
CREATE TABLE brew {
    id ulid PRIMARY KEY,
    name varchar NOT NULL,
    brew_method varchar,
    bean_origin text,
    roaster text,
    notes text,
    created_by ulid REFERENCES user(id),
    is_public boolean DEFAULT true,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier
- `name` - Name of the brew
- `brew_method` - Method used (e.g., "espresso", "pour over", "french press", "aeropress", "cold brew")
- `bean_origin` - Origin of the coffee beans
- `roaster` - Coffee roaster name
- `notes` - Additional notes about the brew
- `created_by` - User who created this brew entry
- `is_public` - Whether this brew is visible to all users

**Relationships:**
- Created by User
- Used in many Posts



### Comment

Represents comments on posts, with support for threaded replies.

```sql
CREATE TABLE comment {
    id ulid PRIMARY KEY,
    post_id ulid REFERENCES post(id) ON DELETE CASCADE,
    parent_comment_id ulid REFERENCES comment(id) ON DELETE CASCADE,
    owner_id ulid REFERENCES user(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier
- `post_id` - Post this comment belongs to
- `parent_comment_id` - Parent comment (null for top-level comments)
- `owner_id` - User who wrote the comment
- `content` - Comment text

**Relationships:**
- Belongs to Post
- Belongs to User (owner)
- Belongs to Comment (parent, optional)
- Has many Comments (replies)
- Has many Likes (via `comment_likes`)



### Media

Represents photos or videos attached to posts.

```sql
CREATE TABLE media {
    id ulid PRIMARY KEY,
    post_id ulid REFERENCES post(id) ON DELETE CASCADE,
    url text NOT NULL,
    type varchar NOT NULL,
    display_order int DEFAULT 0,
    created_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier
- `post_id` - Post this media belongs to
- `url` - URL to the media file
- `type` - Media type ("image" or "video")
- `display_order` - Order for displaying multiple media items

**Relationships:**
- Belongs to Post



### Notification

Represents notifications for user activities.

```sql
CREATE TABLE notification {
    id ulid PRIMARY KEY,
    recipient_user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    actor_user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    type varchar NOT NULL,
    reference_id ulid,
    reference_type varchar,
    is_read boolean DEFAULT false,
    created_at timestamp DEFAULT NOW()
}
```

**Fields:**
- `id` - Unique identifier
- `recipient_user_id` - User receiving the notification
- `actor_user_id` - User who triggered the notification
- `type` - Notification type ("like", "comment", "friend_request", "tag", "follow")
- `reference_id` - ID of the related object (post, comment, etc.)
- `reference_type` - Type of reference ("post", "comment", "friendship")
- `is_read` - Whether the notification has been read

**Relationships:**
- Belongs to User (recipient)
- Belongs to User (actor)



## Junction Tables

These tables manage many-to-many relationships between entities.

### post_likes

Tracks which users liked which posts.

```sql
CREATE TABLE post_likes {
    post_id ulid REFERENCES post(id) ON DELETE CASCADE,
    user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    created_at timestamp DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
}
```

**Purpose:** Allow users to like posts and query who liked what.



### comment_likes

Tracks which users liked which comments.

```sql
CREATE TABLE comment_likes {
    comment_id ulid REFERENCES comment(id) ON DELETE CASCADE,
    user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    created_at timestamp DEFAULT NOW(),
    PRIMARY KEY (comment_id, user_id)
}
```

**Purpose:** Allow users to like comments.



### post_user_tags

Tracks which users are tagged in which posts.

```sql
CREATE TABLE post_user_tags {
    post_id ulid REFERENCES post(id) ON DELETE CASCADE,
    user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    created_at timestamp DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
}
```

**Purpose:** Allow users to tag friends in their coffee posts.



### user_friendships

Manages friendships/follows between users.

```sql
CREATE TABLE user_friendships {
    user_id ulid REFERENCES user(id) ON DELETE CASCADE,
    friend_id ulid REFERENCES user(id) ON DELETE CASCADE,
    status varchar DEFAULT 'pending',
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
}
```

**Fields:**
- `status` - Friendship status ("pending", "accepted", "blocked")

**Purpose:** Manage social connections. Can be used for mutual friendships or one-way follows depending on implementation.



## Common Query Examples

### Get all posts by a user
```sql
SELECT * FROM post WHERE owner_id = 'user123' ORDER BY created_at DESC;
```

### Get all users who liked a post
```sql
SELECT u.* FROM user u
JOIN post_likes pl ON u.id = pl.user_id
WHERE pl.post_id = 'post456';
```

### Get all posts a user has liked
```sql
SELECT p.* FROM post p
JOIN post_likes pl ON p.id = pl.post_id
WHERE pl.user_id = 'user123';
```

### Get comments for a post (top-level only)
```sql
SELECT * FROM comment 
WHERE post_id = 'post456' AND parent_comment_id IS NULL
ORDER BY created_at ASC;
```

### Get user's friends (accepted only)
```sql
SELECT u.* FROM user u
JOIN user_friendships uf ON u.id = uf.friend_id
WHERE uf.user_id = 'user123' AND uf.status = 'accepted';
```

### Get unread notifications for a user
```sql
SELECT * FROM notification 
WHERE recipient_user_id = 'user123' AND is_read = false
ORDER BY created_at DESC;
```

### Get most popular brews (by post count)
```sql
SELECT b.*, COUNT(p.id) as post_count
FROM brew b
JOIN post p ON b.id = p.brew_id
GROUP BY b.id
ORDER BY post_count DESC
LIMIT 10;
```



## Design Decisions

### Why Junction Tables?
Rather than storing arrays of IDs (like `likes: [user1, user2, user3]`), we use junction tables because they:
- Enable efficient querying and indexing
- Support metadata (like `created_at` timestamps)
- Maintain referential integrity
- Handle concurrent operations better
- Scale more effectively

### Why ULID?
ULIDs (Universally Unique Lexicographically Sortable Identifiers) provide:
- Sortability by creation time
- URL-safe format
- Better performance than UUIDs in indexes
- No central ID generation needed

### Rating System
Posts include a self-rating where users rate their own brew (0-5 scale), similar to Untappd's check-in system.
