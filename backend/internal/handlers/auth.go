package handlers

import (
	"net/http"

	"brewd/internal/auth"
	"brewd/internal/db"
	"brewd/internal/logger"
	"brewd/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
)

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Username string `json:"username" binding:"required,min=3,max=30"`
	Password string `json:"password" binding:"required,min=8"`
}

// LoginRequest represents the login request payload
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse represents the authentication response
type AuthResponse struct {
	Token string   `json:"token"`
	User  UserInfo `json:"user"`
}

// UserInfo represents basic user information returned in auth responses
type UserInfo struct {
	ID       string `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
}

// Register handles user registration
func Register(queries *db.Queries, authService auth.AuthService, bcryptCost int) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RegisterRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid request: " + err.Error(),
			})
			return
		}

		ctx := c.Request.Context()

		if err := utils.ValidatePassword(req.Password); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}

		email := utils.NormalizeEmail(req.Email)
		username := utils.NormalizeUsername(req.Username)

		// Check if email is available
		emailAvailable, err := queries.CheckEmailAvailability(ctx, email)
		if err != nil {
			logger.Error("Failed to check email availability", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to check email availability",
			})
			return
		}
		if !emailAvailable {
			c.JSON(http.StatusConflict, gin.H{
				"success": false,
				"error":   "Email already registered",
			})
			return
		}

		// Check if username is available
		usernameAvailable, err := queries.CheckUsernameAvailability(ctx, username)
		if err != nil {
			logger.Error("Failed to check username availability", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to check username availability",
			})
			return
		}
		if !usernameAvailable {
			c.JSON(http.StatusConflict, gin.H{
				"success": false,
				"error":   "Username already taken",
			})
			return
		}

		// Hash password
		passwordHash, err := auth.HashPassword(req.Password, bcryptCost)
		if err != nil {
			logger.Error("Failed to hash password", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to create user",
			})
			return
		}

		// Create user
		user, err := queries.CreateUser(ctx, db.CreateUserParams{
			ID:           utils.GenerateID(),
			Username:     username,
			Email:        email,
			PasswordHash: passwordHash,
		})
		if err != nil {
			logger.Error("Failed to create user", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to create user",
			})
			return
		}

		// Generate JWT token
		token, err := authService.GenerateToken(user.ID, user.Username)
		if err != nil {
			logger.Error("Failed to generate token", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to generate authentication token",
			})
			return
		}

		logger.Info("User registered successfully", "user_id", user.ID, "username", user.Username)

		c.JSON(http.StatusCreated, gin.H{
			"success": true,
			"data": AuthResponse{
				Token: token,
				User: UserInfo{
					ID:       user.ID,
					Username: user.Username,
					Email:    user.Email,
				},
			},
		})
	}
}

// Login handles user authentication
func Login(queries *db.Queries, authService auth.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid request: " + err.Error(),
			})
			return
		}

		ctx := c.Request.Context()

		// Normalize email
		email := utils.NormalizeEmail(req.Email)

		// Get user by email (includes password hash)
		user, err := queries.GetUserByEmail(ctx, email)
		if err != nil {
			if err == pgx.ErrNoRows {
				c.JSON(http.StatusUnauthorized, gin.H{
					"success": false,
					"error":   "Invalid email or password",
				})
				return
			}
			logger.Error("Failed to get user by email", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Authentication failed",
			})
			return
		}

		// Verify password
		if !auth.ComparePassword(user.PasswordHash, req.Password) {
			c.JSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"error":   "Invalid email or password",
			})
			return
		}

		// Generate JWT token
		token, err := authService.GenerateToken(user.ID, user.Username)
		if err != nil {
			logger.Error("Failed to generate token", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to generate authentication token",
			})
			return
		}

		logger.Info("User logged in successfully", "user_id", user.ID, "username", user.Username)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": AuthResponse{
				Token: token,
				User: UserInfo{
					ID:       user.ID,
					Username: user.Username,
					Email:    user.Email,
				},
			},
		})
	}
}
