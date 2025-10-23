# DB Definition

Description of the user schema.

## Object Definition

The User schema is defined as follows:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(254) UNIQUE NOT NULL,
    password_hash VARCHAR(60) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    features JSONB DEFAULT '{}',
    active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    last_login TIMESTAMPTZ,
    created_by INTEGER REFERENCES users(id),
    updated_by INTEGER REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);
```

## Column Definitions

### id

- Type: `SERIAL PRIMARY KEY`
- Primary key and unique identifier
- While the database uses SERIAL for auto-incrementing, the application layer should use [ULID](https://github.com/oklog/ulid) for user identification in API routes
- ULIDs are lexicographically sortable, URL-safe, and globally unique identifiers

### email

- Type: `VARCHAR(254) UNIQUE NOT NULL`
- User's email address
- Must be unique across all users
- Maximum length of 254 characters (per RFC 5321)
- Required field for account creation
- Used for login authentication

### password_hash

- Type: `VARCHAR(60) NOT NULL`
- Bcrypt hash of the user's password
- Never store plain text passwords
- 60 characters accommodate bcrypt hash format
- Required field for authentication

### first_name

- Type: `VARCHAR(100) NOT NULL`
- User's first name
- Maximum length of 100 characters
- Required field for account creation

### last_name

- Type: `VARCHAR(100) NOT NULL`
- User's last name
- Maximum length of 100 characters
- Required field for account creation

### features

- Type: `JSONB DEFAULT '{}'`
- JSON object storing user data
- Allows flexible storage of user-specific configuration
- Defaults to empty JSON object
- Example: `{"darkMode": true, "notifications": false}`

### active

- Type: `BOOLEAN DEFAULT true`
- Indicates whether the user account is active
- Defaults to true on account creation
- Can be used to soft-disable accounts without deletion

### email_verified

- Type: `BOOLEAN DEFAULT false`
- Tracks whether the user has verified their email address
- Defaults to false on account creation
- Should be set to true after email verification process

### last_login

- Type: `TIMESTAMPTZ`
- Timestamp of the user's most recent login
- Nullable - will be NULL for users who have never logged in
- Updated on each successful login via POST /api/auth/login

### created_by

- Type: `INTEGER REFERENCES users(id)`
- Foreign key reference to the user who created this account
- Nullable - will be NULL for self-registered users
- Useful for admin-created accounts or system auditing

### updated_by

- Type: `INTEGER REFERENCES users(id)`
- Foreign key reference to the user who last updated this account
- Nullable - will be NULL until first update
- Tracks who made the most recent modification

### created_at

- Type: `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
- Timestamp when the user account was created
- Automatically set to current timestamp on insertion
- Immutable after creation

### updated_at

- Type: `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
- Timestamp when the user account was last modified
- Should be updated whenever the user record changes
- Useful for tracking account modifications

### deleted_at

- Type: `TIMESTAMPTZ`
- Timestamp when the user account was soft-deleted
- Nullable - NULL for active accounts
- Implements soft delete pattern - records are never physically removed
- When set, the account should be treated as deleted by the application

## Query Definitions

The following queries are defined in `queries/users.sql` for user operations:

### CreateUser

Creates a new user account with the required fields.

**Parameters:**
1. email (VARCHAR)
2. password_hash (VARCHAR)
3. first_name (VARCHAR)
4. last_name (VARCHAR)
5. created_by (INTEGER, nullable)

**Returns:** Complete user record

**Usage:** Called during user registration (POST /api/users)

### GetUserByID

Retrieves a user by their ID.

**Parameters:**
1. id (INTEGER)

**Returns:** Complete user record, or null if not found

**Notes:**
- Automatically filters out soft-deleted users (WHERE deleted_at IS NULL)
- Used for retrieving user details and validating user existence

### GetUserByEmail

Finds a user by their email address.

**Parameters:**
1. email (VARCHAR)

**Returns:** Complete user record, or null if not found

**Notes:**
- Automatically filters out soft-deleted users (WHERE deleted_at IS NULL)
- Primary query for authentication (POST /api/auth/login)
- Can be used to check if email already exists during registration

### UpdateUser

Updates all user fields in a single operation.

**Parameters:**
1. id (INTEGER) - User to update
2. email (VARCHAR)
3. password_hash (VARCHAR)
4. first_name (VARCHAR)
5. last_name (VARCHAR)
6. features (JSONB)
7. active (BOOLEAN)
8. email_verified (BOOLEAN)
9. last_login (TIMESTAMPTZ, nullable)
10. updated_by (INTEGER, nullable)

**Returns:** None (exec query)

**Notes:**
- Automatically sets updated_at to CURRENT_TIMESTAMP
- Only updates non-deleted users (WHERE deleted_at IS NULL)
- Application must provide all field values (no partial updates)
- Used for profile updates (PUT /api/users/:id), password changes, and tracking last login

## Related API Endpoints

Per Phase 1 specifications, the following API endpoints interact with this schema:

- `POST /api/users` - Create new user account
- `PUT /api/users/:id` - Modify user (where :id is a ULID)
- `POST /api/auth/login` - User login with JWT validation
- `POST /api/auth/logout` - User logout and token removal

## ULID Usage

Users are designated by their ULID (Universally Unique Lexicographically Sortable Identifier) in API routes. While the database uses SERIAL for the primary key, the application layer should convert between the database ID and ULID format.

ULID Specification: https://github.com/oklog/ulid

Benefits of ULID:
- 128-bit compatibility with UUID
- Lexicographically sortable
- Canonically encoded as 26 character string (vs 36 for UUID)
- URL-safe characters
- Case insensitive
- No special characters
- Monotonic sort order (when generated in same millisecond)