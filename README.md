# Brewed

A webapp for coffee enthusiasts to assist them in perfecting their brew, and helping other people craft their perfect cup.

## Architecture

- **Frontend**: Next.js (Static Export) served by Nginx
- **Backend**: Go with Gin framework
- **Database**: PostgreSQL 15
- **Infrastructure**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose
- Node.js 24+ (for local frontend development)
- Go 1.24+ (for local backend development)
- Git

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd brewd
   ```

2. **Make the start script executable**
   ```bash
   chmod +x start.sh
   ```

3. **Run the application**
   ```bash
   ./start.sh
   ```

This will:
- Install frontend dependencies
- Build the Next.js application
- Build the Go backend
- Create Docker images
- Start all services

Once complete, access:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Frontend

**Directory**: [Frontend Location](./frontend)

## Backend

**Directory**: [Backend Location](./backend)

### Database Connection

The backend expects the following environment variables (set in compose.yaml):
- `DB_HOST`: Database host (defaults to `db` in Docker network)
- `DB_PORT`: Database port (5432)
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name

Access at http://localhost:8080

## Docker Services

### View Logs
```bash
docker compose logs -f
```

### Stop Services
```bash
docker compose down
```

### Stop and Remove Volumes
```bash
docker compose down -v
```

### Rebuild Services
```bash
docker compose build --no-cache
docker compose up -d
```

## Environment Variables

Copy `.env.example` to `.env` and customize as needed:

```bash
cp .env.example .env
```

## Database

PSQL runs in docker with persistent storage

**Connection Details**:
- Host: localhost
- Port: 5432
- Database: brewd-db

### Connect to Database
```bash
docker exec -it brewd-db psql -U username -d brewd-db
```

## Health Checks

All services include health checks:
- **Database**: `pg_isready` check every 30s
- **Backend**: HTTP check at `/health` every 30s
- **Frontend**: HTTP check at root every 30s

## Workflow

See [CURRENT_INITIATIVE.md](./CURRENT_INITIATIVE.md) for the current development plan and Phase 1 features.