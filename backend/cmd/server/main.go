package main

import (
	"context"
	"net/http"
	"os"
	"time"

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

	// Set environment variable for database config loader
	os.Setenv("DATABASE_URL", cfg.DBConnectionString)

	dbConfig, err := database.LoadConfigFromEnv()
	if err != nil {
		logger.Error("Failed to parse database configuration", "error", err)
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

	// TODO: Pass queries to handlers that need database access
	_ = queries // Suppress unused variable warning until handlers are implemented

	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create router
	router := gin.Default()

	// Add recovery middleware first to catch panics
	router.Use(gin.Recovery())

	// Add logger middleware
	router.Use(middleware.Logger())

	// Health check endpoint with DB ping
	router.GET("/health", handlers.HealthCheckWithDB(pool))

	// Other endpoints here

	logger.Info("Starting server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, router); err != nil {
		logger.Error("Failed to start server", "error", err)
		os.Exit(1)
	}
}
