# Frontend 

Frontend README

## Docker

The `build.sh` script will:
1. Install dependencies
2. Build the Next.js app (outputs to `out/` directory)
3. Build the Docker image

```bash
./build.sh
```

## Docker Details

The Dockerfile:
1. Uses `node:24-alpine` as base
2. Copies the built `out/` directory to nginx
3. Serves static files with nginx on port 3000
4. Includes health check endpoint

## Notes

- The app must be built as a static export (`output: 'export'`)
- No server side features
- All API calls will go to `NEXT_PUBLIC_API_URL`
