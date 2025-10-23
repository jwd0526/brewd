# Brewed

A webapp for coffee enthusiasts to assist them in perfecting their brew, and helping other people craft their perfect cup.

## Architecture

- **Frontend**:
  - **Native** (Primary): React Native with Expo
  - **Web** (Secondary): Next.js (Static Export) served by Nginx
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

2. **Install frontend dependencies**
   ```bash
   cd frontend
   npm install
   cd ..
   ```

3. **Make the start script executable**
   ```bash
   chmod +x start.sh
   ```

4. **Run the application**
   ```bash
   # Start both web and native (default)
   ./start.sh

   # Or start specific mode
   ./start.sh --web      # Web only (Next.js + Backend + DB)
   ./start.sh --native   # Native dev (Backend + DB only)

   # Clean build artifacts before starting
   ./start.sh --clean --web
   ```

### Start Script Options

The `./start.sh` script supports the following options:

- **`./start.sh`** (no flags): Builds and starts both web and native environments
- **`--web`**: Starts web frontend only (Next.js) with backend and database in Docker
- **`--native`**: Starts backend and database in Docker for native app development (Expo runs locally)
- **`--clean`**: Removes all build artifacts and Docker containers before starting
  - Deletes `backend/bin/`
  - Deletes `frontend/web/out/` and `frontend/web/.next/`
  - Deletes `frontend/packages/*/dist/`
  - Stops and removes all Docker containers and volumes

### What Gets Built

The start script will:
1. Build shared packages (`frontend/packages/*`)
2. Build the Go backend (`backend/bin/brewd-backend`)
3. Build the appropriate frontend (web and/or native)
4. Create Docker images (for web mode)
5. Start services with Docker Compose

### Access Points

Once complete, access:
- **Web Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432

For native app:
```bash
cd frontend/brewd-mobile
npm start
```

## Project Structure

```
brewd/
├── backend/              # Go/Gin API server
├── frontend/
│   ├── native/          # React Native (Expo) - PRIMARY
│   ├── web/             # Next.js static site - SECONDARY
│   └── packages/        # Shared code between native/web
│       ├── api-client/  # API client wrapper
│       ├── types/       # Shared TypeScript types
│       ├── utils/       # Shared utilities
│       └── components/  # Shared React components
├── compose.yaml         # Docker Compose config
└── package.json         # Root workspace config
```

## Frontend

The frontend is structured as a monorepo with npm workspaces:

### Native App (Primary) - `frontend/brewd-mobile/`

**React Native with Expo** - The primary development focus.

**Development:**
```bash
npm run dev:native
# or
cd frontend/brewd-mobile
npm start
```

**Tech Stack:**
- React Native
- Expo
- TypeScript
- NativeWind (Tailwind CSS v3 for React Native)
- Shared packages from `frontend/packages/`

### Web App (Secondary) - `frontend/web/`

**Next.js Static Export** - Afterthought, lower priority.

**Development:**
```bash
npm run dev:web
# or
cd frontend/web
npm run dev
```

**Production Build:**
```bash
cd frontend/web
npm run build  # Outputs to out/
```

**Tech Stack:**
- Next.js 16 (Static Export)
- React 19
- TypeScript
- Tailwind CSS v4
- Nginx (Docker deployment)

### Shared Packages - `frontend/packages/`

Code shared between native and web apps:
- **api-client**: API communication layer
- **types**: TypeScript type definitions
- **utils**: Shared utility functions
- **components**: Platform-agnostic React components (styled with Tailwind CSS v4)

### Styling

The project uses Tailwind CSS for consistent styling across platforms:

- **Web & Shared Components**: Tailwind CSS v4 with PostCSS
  - `frontend/web/` uses `@tailwindcss/postcss`
  - `frontend/packages/components/` uses `@tailwindcss/postcss`

- **Native**: NativeWind v4 (Tailwind CSS v3 for React Native)
  - `frontend/brewd-mobile/` uses NativeWind with Tailwind v3
  - Provides Tailwind utilities via `className` prop on React Native components

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

See [DEVELOPMENT_INITIATIVE.md](./DEVELOPMENT_INITIATIVE.md) for the current development plan and Phase 1 features.
## Development

**Kanban**: [Miro Board](https://miro.com/welcomeonboard/ZkFZMTc5MFRaS0ljVXpzQU95dk1sRFBQT1FRRU9ra3BtRFZ0bzRCS0lQczMwQ3ZaRWVaZm50elVlTlJEdlFERkxPV1Zib0lFZnZpN24yWkEzNDZwN1V4UlhhUGZmV2JrR2dsbk1pbDNhakVVSGQyR2NjVDF6eFlYSHJiZkgvamh0R2lncW1vRmFBVnlLcVJzTmdFdlNRPT0hdjE=?share_link_id=424561643597) 
