package routes

import (
	"github.com/gin-gonic/gin"

	"brewd/internal/auth"
	"brewd/internal/config"
	"brewd/internal/db"
	"brewd/internal/handlers"
	"brewd/internal/middleware"
)

func RegisterRoutes(router *gin.Engine, queries *db.Queries, authService auth.AuthService, cfg *config.Config) {
	// health endpoint is registered in main.go, because it requires a pool object

	v1 := router.Group("/api/v1")
	{
		// Auth routes (public)
		authGroup := v1.Group("/auth")
		{
			authGroup.POST("/register", handlers.Register(queries, authService, cfg.BcryptCost))
			authGroup.POST("/login", handlers.Login(queries, authService))
		}

		// Protected user routes
		usersGroup := v1.Group("/users")
		usersGroup.Use(middleware.RequireAuth(authService))
		{
			usersGroup.GET("/me", handlers.GetCurrentUser(queries))
		}
	}
}
