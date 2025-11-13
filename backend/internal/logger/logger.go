package logger

import (
	"os"
	"strings"

	"github.com/rs/zerolog"
)

// Define log levels
type LogLevel string

const (
	DEBUG   LogLevel = "DEBUG"
	INFO    LogLevel = "INFO"
	WARN    LogLevel = "WARN"
	ERROR   LogLevel = "ERROR"
	SUCCESS LogLevel = "SUCCESS"
)

// Global logger instance
var log zerolog.Logger

// Init global logger with the specified log level
func Init(level string) {
	// json to stdout
	log = zerolog.New(os.Stdout).With().Timestamp().Logger()

	// Parse log level
	switch strings.ToUpper(level) {
	case "DEBUG":
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	case "INFO":
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	case "WARN":
		zerolog.SetGlobalLevel(zerolog.WarnLevel)
	case "ERROR":
		zerolog.SetGlobalLevel(zerolog.ErrorLevel)
	default:
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	}
}

// Logs with optional fields

// Debug log
func Debug(msg string, keysAndValues ...interface{}) {
	logWithFields(log.Debug(), msg, keysAndValues...)
}

// Info log
func Info(msg string, keysAndValues ...interface{}) {
	logWithFields(log.Info(), msg, keysAndValues...)
}

// Adds a success field to SUCCESS logs
func Success(msg string, keysAndValues ...interface{}) {
	event := log.Info().Str("status", "success")
	logWithFields(event, msg, keysAndValues...)
}

// Warn log
func Warn(msg string, keysAndValues ...interface{}) {
	logWithFields(log.Warn(), msg, keysAndValues...)
}

// Error log
func Error(msg string, keysAndValues ...interface{}) {
	logWithFields(log.Error(), msg, keysAndValues...)
}

// Returns a new logger with the given key-value pair attached
// Useful for adding context
func With(key string, value interface{}) *zerolog.Logger {
	newLog := log.With().Interface(key, value).Logger()
	return &newLog
}

// Attaches key-value pairs and sends the log
func logWithFields(event *zerolog.Event, msg string, keysAndValues ...interface{}) {
	// Add key-value pairs if provided
	for i := 0; i < len(keysAndValues); i += 2 {
		if i+1 < len(keysAndValues) {
			key, ok := keysAndValues[i].(string)
			if ok {
				event = event.Interface(key, keysAndValues[i+1])
			}
		}
	}
	event.Msg(msg)
}

// Returns the zerolog.Logger
func GetLogger() *zerolog.Logger {
	return &log
}
