#!/bin/bash

# Migration helper script for Brewd backend
# Uses golang-migrate CLI to manage database migrations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
MIGRATIONS_DIR="./db/migrations"
DB_URL="${DATABASE_URL:-postgres://admin:admin@localhost:5432/brewd-db?sslmode=disable}"

# Show usage
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  up              Apply all pending migrations"
    echo "  down            Rollback the last migration"
    echo "  drop            Drop everything in the database (DESTRUCTIVE!)"
    echo "  version         Show current migration version"
    echo "  force <version> Force set migration version (use with caution)"
    echo "  create <name>   Create a new migration file"
    echo "  help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DATABASE_URL    Database connection string (default: postgres://admin:admin@localhost:5432/brewd-db?sslmode=disable)"
    exit 1
}

# Check if migrate CLI is installed
if ! command -v migrate &> /dev/null; then
    echo -e "${RED}Error: golang-migrate CLI not found${NC}"
    echo "Install it with: brew install golang-migrate"
    exit 1
fi

# Parse command
COMMAND=${1:-help}

case "$COMMAND" in
    up)
        echo -e "${GREEN}Applying migrations...${NC}"
        migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" up
        echo -e "${GREEN}✓ Migrations applied successfully${NC}"
        ;;

    down)
        echo -e "${YELLOW}Rolling back last migration...${NC}"
        migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" down 1
        echo -e "${GREEN}✓ Migration rolled back${NC}"
        ;;

    drop)
        echo -e "${RED}WARNING: This will drop all tables in the database!${NC}"
        read -p "Are you sure? (yes/no): " -r
        if [[ $REPLY == "yes" ]]; then
            migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" drop -f
            echo -e "${GREEN}✓ Database dropped${NC}"
        else
            echo "Aborted"
        fi
        ;;

    version)
        echo -e "${GREEN}Current migration version:${NC}"
        migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" version
        ;;

    force)
        VERSION=$2
        if [ -z "$VERSION" ]; then
            echo -e "${RED}Error: Please specify a version number${NC}"
            echo "Usage: $0 force <version>"
            exit 1
        fi
        echo -e "${YELLOW}Force setting migration version to $VERSION...${NC}"
        migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" force "$VERSION"
        echo -e "${GREEN}✓ Version set to $VERSION${NC}"
        ;;

    create)
        NAME=$2
        if [ -z "$NAME" ]; then
            echo -e "${RED}Error: Please specify a migration name${NC}"
            echo "Usage: $0 create <name>"
            exit 1
        fi
        migrate create -ext sql -dir "$MIGRATIONS_DIR" -seq "$NAME"
        echo -e "${GREEN}✓ Migration files created${NC}"
        ;;

    help|*)
        usage
        ;;
esac
