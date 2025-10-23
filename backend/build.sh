#!/bin/bash

set -e

echo "Generating sqlc code..."

sqlc compile

sqlc generate

echo "Building backend..."

go build -o bin/brewd-backend ./cmd/server

echo "Backend build complete!"