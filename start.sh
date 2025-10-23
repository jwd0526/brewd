#!/bin/bash

set -e

# Parse arguments
MODE=""
CLEAN_MODE=false

print_usage() {
    echo "Usage: ./start.sh [--web|--native] [--clean]"
    echo ""
    echo "Options:"
    echo "  --web       Start web frontend only (Next.js + Backend + DB)"
    echo "  --native    Start native development only (Expo + Backend + DB)"
    echo "  --clean     Remove all build artifacts and Docker containers before starting"
    echo "  (none)      Start both web and native (default)"
    echo ""
    echo "If no option is provided, both environments are built"
}

clean_all() {
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

    # Clean frontend web
    echo ""
    echo "Cleaning frontend web build artifacts..."
    rm -rf ./frontend/web/out
    rm -rf ./frontend/web/.next

    # Clean frontend packages
    echo ""
    echo "Cleaning frontend packages build artifacts..."
    rm -rf ./frontend/packages/*/dist

    echo ""
    echo "========================================="
    echo "Clean complete!"
    echo "========================================="
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --web)
            MODE="web"
            shift
            ;;
        --native)
            MODE="native"
            shift
            ;;
        --clean)
            CLEAN_MODE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Default to both if no mode specified
if [ -z "$MODE" ]; then
    MODE="both"
fi

# Run clean if requested
if [ "$CLEAN_MODE" = true ]; then
    clean_all
    echo ""
fi

echo "========================================="
echo "Brewd - Starting in $MODE mode"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Step 1: Build shared packages (always required)
echo ""
echo "Step 1: Building shared packages..."
cd ./frontend/packages
./build-all.sh
cd ../..

# Step 2: Build Backend (always required)
echo ""
echo "Step 2: Building Backend..."
cd ./backend
./build.sh
cd ..

if [ "$MODE" == "web" ]; then
    # Web mode: Build web frontend and start Docker services
    echo ""
    echo "Step 3: Building Frontend (Web)..."
    cd ./frontend/web
    ./build.sh
    cd ../..

    echo ""
    echo "Step 4: Building Docker images..."
    docker compose build

    echo ""
    echo "Step 5: Starting services with Docker Compose..."
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
    echo "Brewd Web is running!"
    echo "========================================="
    echo ""
    echo "Services:"
    echo "  - Web Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8080"
    echo "  - PostgreSQL: localhost:5432"
    echo ""
    echo "To view logs: docker compose logs -f"
    echo "To stop: docker compose down"
    echo "========================================="

elif [ "$MODE" == "native" ]; then
    # Native mode: Start backend + DB in Docker, but run Expo dev server locally
    echo ""
    echo "Step 3: Starting Backend and Database..."
    docker compose up -d db backend

    # Wait for backend to be healthy
    echo ""
    echo "Waiting for backend to be healthy..."
    sleep 5

    echo ""
    echo "========================================="
    echo "Brewd Native Development Ready!"
    echo "========================================="
    echo ""
    echo "Backend Services:"
    echo "  - Backend API: http://localhost:8080"
    echo "  - PostgreSQL: localhost:5432"
    echo ""
    echo "To start the native app:"
    echo "  cd frontend/brewd-mobile"
    echo "  npm start"
    echo ""
    echo "To view backend logs: docker compose logs -f backend"
    echo "To stop backend: docker compose down"
    echo "========================================="

elif [ "$MODE" == "both" ]; then
    # Both mode: Build web and prepare native, start all Docker services
    echo ""
    echo "Step 3: Building Frontend (Web)..."
    cd ./frontend/web
    ./build.sh
    cd ../..

    echo ""
    echo "Step 4: Preparing Native environment..."
    cd ./frontend/brewd-mobile
    ./build.sh
    cd ../..

    echo ""
    echo "Step 5: Building Docker images..."
    docker compose build

    echo ""
    echo "Step 6: Starting services with Docker Compose..."
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
    echo "Brewd - All Environments Ready!"
    echo "========================================="
    echo ""
    echo "Web Services:"
    echo "  - Web Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8080"
    echo "  - PostgreSQL: localhost:5432"
    echo ""
    echo "Native Development:"
    echo "  cd frontend/brewd-mobile"
    echo "  npm start"
    echo ""
    echo "Commands:"
    echo "  View logs: docker compose logs -f"
    echo "  Stop all: docker compose down"
    echo "========================================="
fi