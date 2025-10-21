#!/bin/bash

set -e

echo "Building Go backend..."
go build -o bin/brewd-backend ./cmd/server

echo "Backend build complete!"