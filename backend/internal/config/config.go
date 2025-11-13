package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	JWTSecret        string
	Environment      string
	LogLevel         string
	Port             string
	BcryptCost       int
	JWTExpirationHrs int
}

func LoadConfig() (*Config, error) {
	jwtSecret, err := mustGetEnv("JWT_SECRET")
	if err != nil {
		return nil, err
	}

	bcryptCostStr := getEnvOrDefault("BCRYPT_COST", "10")
	bcryptCost, err := strToInt(bcryptCostStr)
	if err != nil {
		return nil, fmt.Errorf("invalid BCRYPT_COST value '%s': %w", bcryptCostStr, err)
	}

	jwtExpirationStr := getEnvOrDefault("JWT_EXPIRATION_HRS", "24")
	jwtExpiration, err := strToInt(jwtExpirationStr)
	if err != nil {
		return nil, fmt.Errorf("invalid JWT_EXPIRATION_HRS value '%s': %w", jwtExpirationStr, err)
	}

	return &Config{
		JWTSecret:        jwtSecret,
		Environment:      getEnvOrDefault("ENVIRONMENT", "development"),
		LogLevel:         getEnvOrDefault("LOG_LEVEL", "INFO"),
		Port:             getEnvOrDefault("PORT", "8080"),
		BcryptCost:       bcryptCost,
		JWTExpirationHrs: jwtExpiration,
	}, nil
}

// Retrieve mandatory variables or return error
func mustGetEnv(key string) (string, error) {
	val := os.Getenv(key)
	if val == "" {
		return "", fmt.Errorf("required environment variable not set: %s", key)
	}
	return val, nil
}

// Retrieve variables (if present) or use defaults
func getEnvOrDefault(key string, defaultValue string) string {
	if val := os.Getenv(key); val == "" {
		fmt.Fprintf(os.Stderr, "WARN: Using default for env var %s: %s\n", key, defaultValue)
		return defaultValue
	} else {
		return val
	}
}

// Convert string to int
func strToInt(val string) (int, error) {
	intVal, err := strconv.Atoi(val)
	if err != nil {
		return 0, fmt.Errorf("failed to convert to int: %w", err)
	}
	return intVal, nil
}
