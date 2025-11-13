package middleware

import (
	"net/http"
	"strings"

	"brewd/internal/auth"

	"github.com/gin-gonic/gin"
)

// RequireAuth is middleware that validates JWT tokens and protects routes
func RequireAuth(authService auth.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Authorization header required",
			})
			c.Abort()
			return
		}

		// Check Bearer prefix
		if !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		// Extract token
		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Token required",
			})
			c.Abort()
			return
		}

		// Validate token
		claims, err := authService.ValidateToken(token)
		if err != nil {
			if err == auth.ErrExpiredToken {
				c.JSON(http.StatusUnauthorized, gin.H{
					"success": false,
					"error":   "Token has expired",
				})
			} else {
				c.JSON(http.StatusUnauthorized, gin.H{
					"success": false,
					"error":   "Invalid token",
				})
			}
			c.Abort()
			return
		}

		// Attach user information to context
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)

		// Continue to the next handler
		c.Next()
	}
}
