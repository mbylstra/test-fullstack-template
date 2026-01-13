# Docker Quick Start

## Quick Commands

### Development (with hot reload)

```bash
# Start everything
make docker-up

# Run migrations
make docker-migrate

# View logs
make docker-logs

# Stop everything
make docker-down
```

### Access Services

- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432

### Common Tasks

```bash
# Rebuild after code changes (in Dockerfile)
make docker-build && make docker-restart

# Run tests
make docker-test

# Open bash in backend container
make docker-shell

# View backend logs only
docker compose logs -f backend

# Restart just backend
make docker-restart
```

## What's Running?

Check service status:

```bash
docker compose ps
```

Expected output:

```
NAME               STATUS                PORTS
test-fullstack-template-backend    Up (healthy)          0.0.0.0:8000->8000/tcp
test-fullstack-template-postgres   Up (healthy)          0.0.0.0:5432->5432/tcp
```

## Development Workflow

1. **Start services**: `make docker-up`
2. **Run migrations**: `make docker-migrate`
3. **Make code changes** - they auto-reload!
4. **View logs**: `make docker-logs`
5. **Stop when done**: `make docker-down`

## Troubleshooting

**Port 8000 already in use?**

```bash
# Stop local dev server if running
# Or change port in docker-compose.yml
```

**Database connection errors?**

```bash
# Ensure postgres is healthy
docker compose ps postgres

# Check postgres logs
docker compose logs postgres
```

**Backend won't start?**

```bash
# View logs
make docker-logs

# Try rebuilding
make docker-build
make docker-up
```

## Production

For production deployment:

```bash
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml exec backend uv run alembic upgrade head
```

See README.docker.md for detailed documentation.
