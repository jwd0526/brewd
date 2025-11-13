package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"brewd/internal/logger"
)

// Returns a Gin middleware that logs HTTP requests and responses
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate unique request ID for tracing
		requestID := uuid.New().String()
		c.Set("request_id", requestID)

		// Start timer
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		// Process request
		c.Next()

		// Calculate duration
		duration := time.Since(start)
		statusCode := c.Writer.Status()

		// Determine log level based on status code
		if statusCode >= 500 {
			logger.Error("HTTP request",
				"request_id", requestID,
				"method", method,
				"path", path,
				"status", statusCode,
				"duration_ms", duration.Milliseconds(),
				"client_ip", c.ClientIP(),
			)
		} else if statusCode >= 400 {
			logger.Warn("HTTP request",
				"request_id", requestID,
				"method", method,
				"path", path,
				"status", statusCode,
				"duration_ms", duration.Milliseconds(),
				"client_ip", c.ClientIP(),
			)
		} else {
			logger.Info("HTTP request",
				"request_id", requestID,
				"method", method,
				"path", path,
				"status", statusCode,
				"duration_ms", duration.Milliseconds(),
				"client_ip", c.ClientIP(),
			)
		}

		// Log any errors that occurred during request processing
		if len(c.Errors) > 0 {
			for _, err := range c.Errors {
				logger.Error("Request error",
					"request_id", requestID,
					"error", err.Error(),
				)
			}
		}
	}
}
