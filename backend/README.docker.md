# Docker Setup Guide

This guide covers running the Tododoo backend with Docker.

## Overview

The backend includes Docker configuration for both development and production:

- `Dockerfile` - Development image with hot reload
- `Dockerfile.prod` - Production-optimized multi-stage build
- `docker-compose.yml` - Development stack (backend + PostgreSQL)
- `docker-compose.prod.yml` - Production stack

## Development with Docker

### Quick Start

1. **Ensure you have a .env file** (copy from .env.example if needed):
   ```bash
   cp .env.example .env
   ```

2. **Build and start all services**:
   ```bash
   make docker-up
   ```

3. **Run database migrations**:
   ```bash
   make docker-migrate
   ```

4. **View logs**:
   ```bash
   make docker-logs
   ```

The API will be available at `http://localhost:8000`

### Development Workflow

- **Code changes** are automatically reloaded (volume mounted)
- **View logs**: `make docker-logs`
- **Run tests**: `make docker-test`
- **Access backend shell**: `make docker-shell`
- **Restart backend**: `make docker-restart`
- **Stop services**: `make docker-down`

### Database Access

Connect to PostgreSQL:
```bash
make db-shell
```

Or from outside Docker:
```bash
psql -h localhost -U todouser -d tododoo
```

## Production Deployment

### Using docker-compose (production mode)

1. **Set environment variables**:
   Create a `.env` file with production values:
   ```bash
   DB_USER=todouser
   DB_PASSWORD=<strong-password>
   DB_NAME=tododoo
   SECRET_KEY=<strong-secret-key>
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   ```

2. **Deploy**:
   ```bash
   docker compose -f docker-compose.prod.yml up -d
   ```

3. **Run migrations**:
   ```bash
   docker compose -f docker-compose.prod.yml exec backend uv run alembic upgrade head
   ```

### Production Features

The production Dockerfile includes:
- Multi-stage build for smaller image size
- Non-root user for security
- 4 Uvicorn workers for better performance
- Health checks
- No development dependencies

## Architecture

### Development Stack
```
┌─────────────────────────────────────────┐
│  Docker Compose Network                 │
│                                          │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Backend    │───▶│  PostgreSQL  │  │
│  │   :8000      │    │   :5432      │  │
│  │  (hot reload)│    │              │  │
│  └──────────────┘    └──────────────┘  │
│        ▲                                 │
│        │ volume mount                    │
│        │ (./:/app)                       │
└────────┼─────────────────────────────────┘
         │
    Local Files
```

### Key Configuration

- **Backend container**: Runs FastAPI with Uvicorn
- **PostgreSQL container**: PostgreSQL 16 Alpine
- **Network**: Shared bridge network for inter-container communication
- **Volumes**:
  - Code mounted for hot reload in dev
  - PostgreSQL data persisted in named volume

### Environment Variables

The backend container automatically sets `DB_HOST=postgres` to connect to the database container. All other environment variables come from your `.env` file.

## Troubleshooting

### Backend won't start
- Check logs: `make docker-logs`
- Ensure database is healthy: `docker compose ps`
- Verify .env file exists and has correct values

### Database connection errors
- Ensure PostgreSQL container is running: `docker compose ps postgres`
- Check database health: `docker compose logs postgres`
- Verify DB_HOST is set to `postgres` (not `localhost`)

### Port already in use
- Stop conflicting services on ports 8000 or 5432
- Or change ports in docker-compose.yml

### Migrations fail
- Ensure database is running and healthy
- Check if migrations were already applied: `make docker-shell` then `uv run alembic current`

## Common Tasks

### View all running containers
```bash
docker compose ps
```

### Rebuild after dependency changes
```bash
make docker-build
make docker-restart
```

### Reset database completely
```bash
make docker-down
docker volume rm backend_postgres_data
make docker-up
make docker-migrate
```

### Access Python REPL in container
```bash
make docker-shell
uv run python
```

## Performance Notes

- **Development**: Single worker with hot reload, code mounted as volume
- **Production**: 4 workers, optimized image, no volume mounts
- Database connection pooling handled by SQLAlchemy
- Health checks ensure services are ready before accepting traffic
