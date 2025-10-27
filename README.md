# Brewed

A mobile app for coffee enthusiasts to assist them in perfecting their brew, and helping other people craft their perfect cup.

## Architecture

- **Frontend**: React Native with Expo (Mobile)
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

2. **Build and start backend services**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

   This will:
   - Build the Go backend
   - Start backend and PostgreSQL in Docker
   - Display instructions for starting the mobile app

3. **Start the mobile app**
   ```bash
   cd frontend/brewd-mobile
   npm install
   npm start
   ```

   Then scan the QR code with the Expo Go app on your device.

### Scripts

- **`./build.sh`**: Build and deploy backend + PostgreSQL
- **`./clean.sh`**: Remove all build artifacts and Docker containers

### Access Points

- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Project Structure

```
brewd/
├── backend/              # Go/Gin API server
├── frontend/
│   └── brewd-mobile/    # React Native (Expo)
├── compose.yaml          # Docker Compose config
├── build.sh              # Build and deploy script
└── clean.sh              # Cleanup script
```

## Frontend

### Mobile App - `frontend/brewd-mobile/`

**React Native with Expo**

**Development:**
```bash
cd frontend/brewd-mobile
npm start
```

**Tech Stack:**
- React Native
- Expo SDK 54
- TypeScript
- ESLint with Expo config

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

Services include health checks:
- **Database**: `pg_isready` check every 30s
- **Backend**: HTTP check at `/health` every 30s

## Workflow

See [DEVELOPMENT_INITIATIVE.md](./DEVELOPMENT_INITIATIVE.md) for the current development plan and Phase 1 features.
## Development

**Kanban**: [Miro Board](https://miro.com/welcomeonboard/ZkFZMTc5MFRaS0ljVXpzQU95dk1sRFBQT1FRRU9ra3BtRFZ0bzRCS0lQczMwQ3ZaRWVaZm50elVlTlJEdlFERkxPV1Zib0lFZnZpN24yWkEzNDZwN1V4UlhhUGZmV2JrR2dsbk1pbDNhakVVSGQyR2NjVDF6eFlYSHJiZkgvamh0R2lncW1vRmFBVnlLcVJzTmdFdlNRPT0hdjE=?share_link_id=424561643597) 
