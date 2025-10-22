#!/bin/bash

set -e

echo "Building frontend..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Build Next.js app
echo "Building Next.js app..."
npm run build

echo "Frontend build complete!"
