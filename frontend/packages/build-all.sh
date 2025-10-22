#!/bin/bash

set -e

echo "Building shared packages..."

# Build in dependency order
packages=("types" "utils" "api-client" "components")

for package in "${packages[@]}"; do
    echo "Building @brewd/$package..."
    cd "$package"
    if [ -f "package.json" ]; then
        npm run build --if-present
    fi
    cd ..
done

echo "All packages built successfully!"
