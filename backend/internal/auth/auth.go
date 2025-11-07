package auth

import "github.com/golang-jwt/jwt/v5"

// Claims represents the JWT claims structure
type Claims struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// AuthService defines the interface for authentication operations
type AuthService interface {
	// ValidateToken validates a JWT token and returns the claims if valid
	ValidateToken(token string) (*Claims, error)

	// GenerateToken creates a new JWT token for a user
	GenerateToken(userID, username string) (string, error)
}