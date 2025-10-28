-- name: CreateUser :one
INSERT INTO user (
    email,
    password_hash,
    first_name,
    last_name,
    created_by
) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: GetUserByID :one
SELECT * FROM user
WHERE id = $1
AND deleted_at IS NULL;

-- name: GetUserByEmail :one
SELECT * FROM user
WHERE email = $1
AND deleted_at IS NULL;

-- name: UpdateUser :exec
UPDATE user
SET
    email = $2,
    password_hash = $3,
    first_name = $4,
    last_name = $5,
    features = $6,
    active = $7,
    email_verified = $8,
    last_login = $9,
    updated_by = $10,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
AND deleted_at IS NULL;
