package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	"brewd/internal/auth"
	"brewd/internal/config"
	"brewd/internal/db"
	"brewd/internal/handlers"
	"brewd/internal/logger"
	"brewd/internal/middleware"
	"brewd/internal/routes"
	"brewd/pkg/database"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "FATAL: %v\n", err)
		os.Exit(1)
	}
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

	router.GET("/health", handlers.HealthCheckWithDB(pool))

	// Routes
	routes.RegisterRoutes(router, queries, authService, cfg)

	logger.Info("Starting server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, router); err != nil {
		logger.Error("Failed to start server", "error", err)
		os.Exit(1)
	}
}
