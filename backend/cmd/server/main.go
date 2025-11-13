package main

import (
	"context"
	"net/http"
	"os"
	"time"

	"brewd/internal/auth"
	"brewd/internal/config"
	"brewd/internal/db"
	"brewd/internal/handlers"
	"brewd/internal/logger"
	"brewd/internal/middleware"
	"brewd/pkg/database"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.LoadConfig()
	logger.Init(cfg.LogLevel)

	// Initialize database connection
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Get db config
	dbConfig, err := database.LoadConfigFromEnv()
	if err != nil {
		logger.Error("Failed to load database configuration", "error", err)
		os.Exit(1)
	}

	pool, err := database.NewPool(ctx, dbConfig)
	if err != nil {
		logger.Error("Failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	// Create queries instance for database operations
	queries := db.New(pool)
	logger.Info("Database connection established")

	// Initialize authentication service
	authService := auth.NewService(cfg.JWTSecret, cfg.JWTExpirationHrs)
	logger.Info("Authentication service initialized")

	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create router
	router := gin.New()

	// Add recovery middleware first to catch panics
	router.Use(gin.Recovery())

	// Add logger middleware
	router.Use(middleware.Logger())

	// Public routes
	router.GET("/health", handlers.HealthCheckWithDB(pool))

	// Auth routes (public)
	authGroup := router.Group("/auth")
	{
		authGroup.POST("/register", handlers.Register(queries, authService, cfg.BcryptCost))
		authGroup.POST("/login", handlers.Login(queries, authService))
	}

	// Protected API routes (require authentication)
	apiGroup := router.Group("/api")
	apiGroup.Use(middleware.RequireAuth(authService))
	{
		// Get current user
		apiGroup.GET("/me", func(c *gin.Context) {
			userID := c.GetString("user_id")
			username := c.GetString("username")
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"data": gin.H{
					"user_id":  userID,
					"username": username,
				},
			})
		})
	}

	logger.Info("Starting server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, router); err != nil {
		logger.Error("Failed to start server", "error", err)
		os.Exit(1)
	}
}
