---
name: docker-patterns
description: Multi-stage Dockerfiles for Astro + NestJS, docker-compose for SQLite/PostgreSQL + Redis, Caddy 2 reverse proxy with automatic HTTPS. Use when containerizing the stack or setting up a single-node deploy.
---

# Docker Patterns

> Targets the stack defined in [`AGENTS.md`](../AGENTS.md) §3: **Astro + Svelte 5 frontend, NestJS backend, SQLite/PostgreSQL, Redis, Caddy 2**.

## NestJS Multi-Stage Dockerfile

```dockerfile
# apps/api/Dockerfile
# syntax=docker/dockerfile:1.7

FROM node:24-alpine AS base
WORKDIR /app
RUN corepack enable

# ─── deps ────────────────────────────────────────────────────
FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ─── build ───────────────────────────────────────────────────
FROM deps AS build
COPY . .
RUN pnpm exec prisma generate
RUN pnpm run build

# ─── production ──────────────────────────────────────────────
FROM base AS production
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser  --system --uid 1001 nestjs

COPY --from=deps  --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nestjs:nodejs /app/dist          ./dist
COPY --from=build --chown=nestjs:nodejs /app/prisma        ./prisma
COPY --from=build --chown=nestjs:nodejs /app/package.json  ./package.json

USER nestjs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:3000/health/liveness || exit 1

CMD ["node", "dist/main"]
```

## Astro Multi-Stage Dockerfile (Node adapter)

```dockerfile
# apps/web/Dockerfile
# syntax=docker/dockerfile:1.7

FROM node:24-alpine AS base
WORKDIR /app
RUN corepack enable

# ─── deps ────────────────────────────────────────────────────
FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ─── build ───────────────────────────────────────────────────
FROM deps AS build
COPY . .
RUN pnpm run build       # produces dist/server/entry.mjs + dist/client/

# ─── production ──────────────────────────────────────────────
FROM base AS runner
ENV NODE_ENV=production HOST=0.0.0.0 PORT=4321

RUN addgroup --system --gid 1001 nodejs && \
    adduser  --system --uid 1001 astro

COPY --from=build --chown=astro:nodejs /app/dist ./dist
COPY --from=deps  --chown=astro:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=astro:nodejs /app/package.json ./package.json

USER astro
EXPOSE 4321

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:4321/ >/dev/null || exit 1

CMD ["node", "./dist/server/entry.mjs"]
```

Set the Node adapter in `astro.config.ts`:

```typescript
import { defineConfig } from 'astro/config'
import node from '@astrojs/node'

export default defineConfig({
  output: 'server',
  adapter: node({ mode: 'standalone' }),
})
```

## `.dockerignore`

```
node_modules
dist
.svelte-kit
.astro
.git
.gitignore
*.md
.env*
!.env.example
coverage
playwright-report
test-results
*.log
.DS_Store
*.db
*.db-journal
```

## docker-compose — Development

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB:       ${POSTGRES_DB:-app}
      POSTGRES_USER:     ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 5

  api:
    build:
      context: ./apps/api
      target: deps               # use deps stage for hot reload
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    environment:
      NODE_ENV:     development
      DATABASE_URL: postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}@postgres:5432/${POSTGRES_DB:-app}
      REDIS_URL:    redis://redis:6379
    ports:
      - "3000:3000"
      - "9229:9229"              # debug
    volumes:
      - ./apps/api/src:/app/src:ro
      - ./apps/api/prisma:/app/prisma:ro
    command: pnpm run start:dev

  web:
    build:
      context: ./apps/web
      target: deps
    restart: unless-stopped
    depends_on: [api]
    environment:
      PUBLIC_API_URL: http://localhost:3000
    ports:
      - "4321:4321"
    volumes:
      - ./apps/web/src:/app/src:ro
      - ./apps/web/public:/app/public:ro
    command: pnpm run dev

volumes:
  postgres_data:
  redis_data:
```

### SQLite variant (skip Postgres service)

Drop the `postgres` service entirely. Mount a volume for the SQLite file:

```yaml
  api:
    environment:
      DATABASE_URL: file:/data/app.db
    volumes:
      - sqlite_data:/data
volumes:
  sqlite_data:
```

## docker-compose — Production Override (with Caddy)

```yaml
# docker-compose.prod.yml
services:
  api:
    build:
      target: production
    restart: always
    environment:
      NODE_ENV: production
    volumes: []
    command: node dist/main

  web:
    build:
      target: runner
    restart: always
    volumes: []
    command: node ./dist/server/entry.mjs

  caddy:
    image: caddy:2-alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on: [web, api]

volumes:
  caddy_data:
  caddy_config:
```

## Caddyfile (Caddy 2)

Automatic HTTPS via Let's Encrypt — no certificate config needed for a real domain.

```caddyfile
# Caddyfile
example.com, www.example.com {
    encode zstd gzip

    # Backend API
    handle /api/* {
        reverse_proxy api:3000
    }

    # Frontend (Astro SSR)
    handle {
        reverse_proxy web:4321
    }

    log {
        output stdout
        format console
    }
}
```

Local dev / staging without DNS — use `:80` and `tls internal`:

```caddyfile
:80 {
    handle /api/* { reverse_proxy api:3000 }
    handle       { reverse_proxy web:4321 }
}
```

## Useful Commands

```bash
# Build + run dev stack
docker compose up -d --build

# View logs (follow / tail)
docker compose logs -f api
docker compose logs --tail=100 web

# Exec into container
docker compose exec api sh
docker compose exec postgres psql -U postgres app

# Run a Prisma migration inside the container
docker compose exec api npx prisma migrate deploy

# Rebuild one service
docker compose up -d --build api

# Production deploy (compose merges files left-to-right)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Tear down (also remove volumes)
docker compose down -v --remove-orphans
```

## Secrets

Prefer Docker secrets or mounted files over env literals in compose:

```yaml
services:
  api:
    environment:
      DATABASE_URL_FILE: /run/secrets/database_url
      JWT_SECRET_FILE:   /run/secrets/jwt_secret
    secrets:
      - database_url
      - jwt_secret

secrets:
  database_url: { file: ./secrets/database_url.txt }
  jwt_secret:   { file: ./secrets/jwt_secret.txt }
```

App code reads `process.env.DATABASE_URL_FILE` then loads the file contents.

## Forbidden Patterns

- Never run containers as `root` in production — always create a non-root user
- Never bake secrets into the image (`COPY .env` / `ENV SECRET=...`) — they persist in layer history
- Never use `latest` tag for base images — pin to `node:24-alpine`, `postgres:16-alpine`, etc.
- Never skip `.dockerignore` — sending `node_modules/` to the daemon wastes minutes
- Never run `pnpm install` in the production stage — install once in deps, copy artifacts
- Never expose debug ports (9229) in production compose files
- Never commit `docker-compose.override.yml` with credentials
- Never share a single SQLite file across multiple writers in production — switch to PostgreSQL
