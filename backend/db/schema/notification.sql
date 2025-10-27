-- Notification table
-- Represents notifications for user activities
CREATE TABLE notification (
    id TEXT PRIMARY KEY, -- ULID format
    recipient_user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    actor_user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('like', 'comment', 'friend_request', 'tag', 'follow')),
    reference_id TEXT,
    reference_type VARCHAR(50) CHECK (reference_type IN ('post', 'comment', 'friendship')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_notification_recipient ON notification(recipient_user_id);
CREATE INDEX idx_notification_is_read ON notification(recipient_user_id, is_read);
CREATE INDEX idx_notification_created_at ON notification(created_at);
