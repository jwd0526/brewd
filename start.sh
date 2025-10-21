#!/bin/bash

set -e

echo "Starting brewd..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build Frontend
echo ""
echo "Step 1/4: Building Frontend..."
cd ./frontend
./build.sh
cd ..

# Build Backend
echo ""
echo "Step 2/4: Building Backend..."
cd ./backend
./build.sh
cd ..

# Build Docker Images
echo ""
echo "Step 3/4: Building Docker images..."
docker compose build

# Start Services
echo ""
echo "Step 4/4: Starting services with Docker Compose..."
docker compose up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check service health
echo ""
echo "Service Status:"
docker compose ps

echo "Services:"
echo "  - Frontend: http://localhost:3000"
echo "  - Backend API: http://localhost:8080"
echo "  - PostgreSQL: localhost:5432"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"