#!/bin/bash

set -e

echo "========================================="
echo "Brewd - Building and Deploying"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Step 1: Build Backend
echo ""
echo "Step 1: Building Backend..."
cd ./backend
./build.sh
cd ..

# Step 2: Build Docker images
echo ""
echo "Step 2: Building Docker images..."
docker compose build

# Step 3: Start services with Docker Compose
echo ""
echo "Step 3: Starting services with Docker Compose..."
docker compose up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check service health
echo ""
echo "Service Status:"
docker compose ps

echo ""
echo "========================================="
echo "Brewd Backend is running!"
echo "========================================="
echo ""
echo "Services:"
echo "  - Backend API: http://localhost:8080"
echo "  - PostgreSQL: localhost:5432"
echo ""
echo "To start the Expo mobile app:"
echo "  cd frontend/brewd-mobile"
echo "  npm start"
echo ""
echo "Commands:"
echo "  View logs: docker compose logs -f"
echo "  Stop all: docker compose down"
echo "========================================="
