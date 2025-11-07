# brewd API Design

## Overview

A RESTful API design for brewd. Users can share coffee brews, follow friends, like/comment on posts, and discover new coffee experiences.

## Architecture

### Technology Stack
- **Framework**: Gin
- **Database**: PostgreSQL with pgx
- **Query Generation**: sqlc
- **Authentication**: JWT tokens
- **Password Hashing**: bcrypt
- **Validation**: go-playground/validator

### Design Principles
1. **Simplicity** - Simple handler design
2. **Extensibility** - Clear separation of concerns at repo level
3. **Type Safety** - Use sqlc code for type safety when possible
4. **Stateless** - No server-side sessions

## Project Structure

```
backend/
├── cmd/server/main.go              # Entry point
├── internal/
│   ├── config/                     # Environment configuration
│   ├── auth/                       # JWT + password utilities
│   ├── middleware/                 # Auth, CORS, etc.
│   ├── handlers/                   # Endpoint logic
│   ├── routes/                     # Route registration
│   ├── errors/                     # Error handling
│   └── db/                         # sqlc-generated code
└── pkg/database/                   # DB pool management
```

## API Versioning

All endpoints are versioned under `/api/v1` prefix.

## Authentication

### JWT Tokens
- Stateless authentication using JSON Web Tokens
- Token contains: user_id, username, expiration
- Passed via `Authorization: Bearer <token>` header
- Tokens expire after 24 hours (configurable)

### Password Security
- bcrypt hashing with automatic salting
- Cost factor: 10 (adjustable via config)
- Passwords never stored in plaintext or logged

## Request/Response Format

### Standard Response
```json
{
  "data": { ... }
}
```

### Error Response
```json
{
  "error": "Error message",
  "code": 400
}
```

### Authentication Response
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": "01ARZ3NDEKTSV4RRFFQ69G5FAV",
    "username": "johndoe",
    "email": "john@example.com",
    "profile_picture_url": "https://...",
    "bio": "Coffee enthusiast",
    "location": "Portland, OR",
    "joined_at": "2024-01-15T10:30:00Z"
  }
}
```

## Validation

All input is validated using struct tags:
- Email format validation
- Username: 3-30 alphanumeric characters
- Password: minimum 8 characters
- Required fields enforced
- Max lengths for text fields

## Error Handling

Standard HTTP status codes:
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Missing/invalid token
- `404 Not Found` - Resource not found
- `409 Conflict` - Username/email already exists
- `500 Internal Server Error` - Server error

## Phase 1: User Management API

### Authentication Endpoints

#### Register User
- **POST** `/api/v1/auth/register`
- **Public**
- Creates new user account
- Returns JWT token + user object

#### Login
- **POST** `/api/v1/auth/login`
- **Public**
- Authenticates user with username/email + password
- Returns JWT token + user object

#### Logout
- **POST** `/api/v1/auth/logout`
- **Protected**
- Client-side token removal (stateless - no server action needed)
- Returns success message

### Profile Endpoints

#### Get Current User Profile
- **GET** `/api/v1/users/me`
- **Protected**
- Returns current user's profile

#### Update Profile
- **PATCH** `/api/v1/users/me`
- **Protected**
- Updates bio, location, profile_picture_url
- Returns updated user object

#### Change Password
- **POST** `/api/v1/users/change-password`
- **Protected**
- Requires current password for verification
- Updates password hash

### Validation Endpoints

#### Check Username Availability
- **GET** `/api/v1/users/check-username/:username`
- **Public**
- Returns `{"available": true/false}`
- Used for real-time registration validation

#### Check Email Availability
- **GET** `/api/v1/users/check-email/:email`
- **Public**
- Returns `{"available": true/false}`
- Used for real-time registration validation

## Configuration

Environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT signing
- `PORT` - Server port (default: 8080)
- `BCRYPT_COST` - bcrypt cost factor (default: 10)
- `JWT_EXPIRATION_HOURS` - Token expiration (default: 24)

## Future Phases

- **Phase 2**: Posts & Brews (create, read, update, delete)
- **Phase 3**: Social Features (friendships, likes, comments)
- **Phase 4**: Discovery (search, trending, recommendations)
- **Phase 5**: Notifications & Analytics

## Security Considerations

1. **Password Storage**: Never store plaintext passwords
2. **SQL Injection**: Prevented by sqlc parameterized queries
3. **JWT Secret**: Must be cryptographically random, stored securely
4. **CORS**: Restrict allowed origins in production
5. **Rate Limiting**: TODO - implement in future phase
6. **Input Sanitization**: Validation via go-playground/validator

## Development Workflow

1. Define endpoints in this document
2. Create handlers in `internal/handlers/`
3. Register routes in `internal/routes/`
4. Test with curl/Postman
5. Update this document with any changes
