package handlers

import (
	"net/http"

	"brewd/pkg/database"
	"github.com/gin-gonic/gin"
)

// HealthCheck returns basic API health status (deprecated, use HealthCheckWithDB)
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"status": "healthy",
		},
	})
}

// HealthCheckWithDB returns a handler that checks both API and database health
func HealthCheckWithDB(pool *database.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Use the pool's built-in health check with metrics and stats
		healthStatus := pool.HealthCheck(c.Request.Context())

		// Return 503 if database is unhealthy
		if !healthStatus.Healthy {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"success": false,
				"data": gin.H{
					"api_status": "healthy",
					"db_status":  "unhealthy",
					"db_error":   healthStatus.Error,
					"response_time_ms": healthStatus.ResponseTime.Milliseconds(),
					"pool_stats": healthStatus.Stats,
				},
			})
			return
		}

		// Return 200 with full health details
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"api_status": "healthy",
				"db_status":  "healthy",
				"response_time_ms": healthStatus.ResponseTime.Milliseconds(),
				"pool_stats": healthStatus.Stats,
			},
		})
	}
}