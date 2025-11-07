package config

import (
	"os"
	"fmt"
	"strconv"
)

type Config struct {
	DBConnectionString string
	JWTSecret string
	Environment string
	LogLevel string
	Port string
	BcryptCost int
	JWTExpirationHrs int
}

func LoadConfig() *Config {
	return &Config{
		DBConnectionString: mustGetEnv("DB_CONNECTION_STRING"),
		JWTSecret: mustGetEnv("JWT_SECRET"),
		Environment: getEnvOrDefault("ENVIRONMENT", "development"),
		LogLevel: getEnvOrDefault("LOG_LEVEL", "INFO"),
		Port: getEnvOrDefault("PORT", "8080"),
		BcryptCost: strToInt(getEnvOrDefault("BCRYPT_COST", "10")),
		JWTExpirationHrs: strToInt(getEnvOrDefault("JWT_EXPIRATION_HRS", "24")),
	}
}

func mustGetEnv(key string) string {
	if val := os.Getenv(key); val == "" {
		fmt.Fprintf(os.Stderr, "ERROR: Required environment variable not set: %s\n", key)
		panic(fmt.Sprintf("Missing required env var: %s", key))
	} else {
		return val
	}
}

func getEnvOrDefault(key string, defaultValue string) string {
	if val := os.Getenv(key); val == "" {
		fmt.Fprintf(os.Stderr, "WARN: Using default for env var %s: %s\n", key, defaultValue)
		return defaultValue
	} else {
		return val
	}
}

func strToInt(val string) int {
	if intVal, err := strconv.Atoi(val); err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to convert environment variable to int: %v\n", err)
		panic(err)
	} else {
		return intVal
	}
}