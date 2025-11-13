package handlers

import (
	"net/http"

	"brewd/internal/db"
	"github.com/gin-gonic/gin"
)

func GetCurrentUser(queries *db.Queries) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		username := c.GetString("username")
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"user_id":  userID,
				"username": username,
			},
		})
	}
}
