# Brewd Frontend

Monorepo for Brewd's frontend applications and shared code.

## Architecture

### Applications

**Native (Primary)** - `./native/`

- React Native with Expo
- Primary development focus
- iOS, Android, and web platforms

**Web (Secondary)** - `./web/`

- Next.js (Static Export)
- Served by Nginx in Docker
- Lower priority, afterthought

### Shared Packages - `./packages/`

- **types** - Shared TypeScript type definitions
- **utils** - Shared utility functions
- **api-client** - API communication layer
- **components** - Platform-agnostic React components

## Development

```bash
# Install all dependencies (run from frontend/)
npm install

# Run native app
npm run dev:native

# Run web app
npm run dev:web

# Build shared packages
npm run build:packages
```

## Workspace Structure

This is an npm workspace. Dependencies are hoisted to `frontend/node_modules/` except for React Native which requires local `native/node_modules/`.

## Build Order

1. Shared packages (always built first)
2. Native or Web (uses built packages)

Enforced by `./packages/build-all.sh` which builds in dependency order:
`types` → `utils` → `api-client` → `components`
