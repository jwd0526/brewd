package utils

import (
	"crypto/rand"
	"fmt"
	"strings"
	"time"
	"unicode"

	"github.com/oklog/ulid/v2"
)

// ValidatePassword checks if password meets complexity requirements
func ValidatePassword(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}

	var (
		hasUpper  bool
		hasLower  bool
		hasSymbol bool
	)

	for _, char := range password {
		switch {
		case unicode.IsUpper(char):
			hasUpper = true
		case unicode.IsLower(char):
			hasLower = true
		case unicode.IsPunct(char) || unicode.IsSymbol(char):
			hasSymbol = true
		}
	}

	if !hasUpper {
		return fmt.Errorf("password must contain at least one uppercase letter")
	}
	if !hasLower {
		return fmt.Errorf("password must contain at least one lowercase letter")
	}
	if !hasSymbol {
		return fmt.Errorf("password must contain at least one symbol")
	}

	return nil
}

// NormalizeEmail normalizes email to lowercase and trims whitespace
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// NormalizeUsername trims whitespace from username
func NormalizeUsername(username string) string {
	return strings.TrimSpace(username)
}

// GenerateID generates a new ULID for use as a unique identifier
func GenerateID() string {
	return ulid.MustNew(ulid.Timestamp(time.Now()), rand.Reader).String()
}
