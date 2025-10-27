#!/bin/bash

set -e

echo "========================================="
echo "Cleaning build artifacts and containers"
echo "========================================="

# Stop and remove Docker containers and volumes
echo ""
echo "Stopping and removing Docker containers..."
docker compose down -v --remove-orphans 2>/dev/null || true

# Remove Docker images for this project
echo ""
echo "Removing Docker images..."
docker compose rm -f 2>/dev/null || true

# Clean backend
echo ""
echo "Cleaning backend build artifacts..."
rm -rf ./backend/bin

echo ""
echo "========================================="
echo "Clean complete!"
echo "========================================="
