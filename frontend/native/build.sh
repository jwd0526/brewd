#!/bin/bash

set -e

echo "Setting up React Native development environment..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

echo ""
echo "React Native development environment ready!"
echo ""
echo "To start the Expo dev server:"
echo "  npm start"
echo ""
echo "Or use specific platforms:"
echo "  npm run ios     - Start iOS simulator"
echo "  npm run android - Start Android emulator"
echo "  npm run web     - Start web version (for testing)"
