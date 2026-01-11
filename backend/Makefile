.DEFAULT_GOAL := help
.PHONY: help dev install sync test test-verbose test-cov typecheck db-up db-down db-logs db-reset db-shell db-dump db-migrate db-generate-migration db-migrate-downgrade db-migrate-history setup env-check format lint clean docker-build docker-up docker-down docker-logs docker-restart docker-shell docker-test docker-migrate docker-reset-password api-generate replace-prod-db-with-local replace-local-db-with-prod

help:
	@echo "Development Commands:"
	@echo "  make dev           - Run FastAPI development server with hot reload (local, use with db-up)"
	@echo "  make install       - Install dependencies"
	@echo "  make sync          - Sync dependencies from pyproject.toml"
	@echo "  make setup         - Complete setup: install deps, create .env, start DB, run migrations"
	@echo "  make env-check     - Check if .env file exists and show configuration"
	@echo "  make format        - Format code with ruff"
	@echo "  make lint          - Lint code with ruff"
	@echo "  make typecheck     - Type check code with pyright"
	@echo "  make clean         - Remove Python cache files and directories"
	@echo ""
	@echo "Code Generation Commands:"
	@echo "  make api-generate  - Generate Pydantic models from OpenAPI spec"
	@echo ""
	@echo "Docker Commands (for full containerized deployment):"
	@echo "  make docker-build  - Build Docker image for backend"
	@echo "  make docker-up     - Start all services (backend + database) with Docker"
	@echo "  make docker-down   - Stop all Docker services"
	@echo "  make docker-logs   - View Docker logs for all services"
	@echo "  make docker-restart- Restart Docker services"
	@echo "  make docker-shell  - Open shell in backend container"
	@echo "  make docker-test   - Run tests in Docker container"
	@echo "  make docker-migrate- Run database migrations in Docker container"
	@echo "  make docker-reset-password EMAIL=user@example.com PASS=newpass - Reset user password in Docker"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test          - Run tests"
	@echo "  make test-verbose  - Run tests with verbose output"
	@echo "  make test-cov      - Run tests with coverage report"
	@echo ""
	@echo "Database Commands (PostgreSQL only for local dev):"
	@echo "  make db-up         - Start PostgreSQL database only (for local dev)"
	@echo "  make db-down       - Stop PostgreSQL database"
	@echo "  make db-logs       - View database logs"
	@echo "  make db-reset      - Stop database and remove data volume"
	@echo "  make db-shell      - Connect to PostgreSQL shell"
	@echo "  make db-dump       - Dump local database to db-dumps/ directory"
	@echo ""
	@echo "Migration Commands:"
	@echo "  make db-migrate            - Apply pending migrations (local)"
	@echo "  make db-generate-migration - Generate migration from model changes (does not apply)"
	@echo "  make db-migrate-downgrade  - Rollback last migration"
	@echo "  make db-migrate-history    - Show migration history"
	@echo ""
	@echo "Production Deployment Commands:"
	@echo "  make replace-prod-db-with-local       - Migrate local database to production (DESTRUCTIVE!)"
	@echo "  make replace-local-db-with-prod     - Migrate production database to local (DESTRUCTIVE!)"

# Development Commands
dev:
	uv run python main.py

install:
	uv sync

sync:
	uv sync

setup:
	@echo "Setting up backend environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "✓ Created .env file - please review and update SECRET_KEY"; \
	else \
		echo "✓ .env file already exists"; \
	fi
	@echo "Installing dependencies..."
	@$(MAKE) install
	@echo "Starting database..."
	@$(MAKE) db-up
	@echo "Waiting for database to be ready..."
	@sleep 3
	@echo "Running migrations..."
	@$(MAKE) db-migrate
	@echo ""
	@echo "✓ Setup complete! Run 'make dev' to start the server"

env-check:
	@if [ -f .env ]; then \
		echo "✓ .env file exists"; \
		echo ""; \
		echo "Current configuration:"; \
		grep -v "SECRET_KEY\|PASSWORD" .env || true; \
	else \
		echo "✗ .env file not found"; \
		echo "Run 'cp .env.example .env' to create it"; \
		exit 1; \
	fi

format:
	uv run ruff format .

lint:
	uv run ruff check .

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Testing Commands
test:
	uv run pytest

test-verbose:
	uv run pytest -v

test-cov:
	uv run pytest --cov=app --cov-report=term-missing --cov-report=html

typecheck:
	uv run pyright

# Database Commands
db-up:
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml up -d

db-down:
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml down

db-logs:
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml logs -f postgres

db-reset:
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml down -v

db-shell:
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml exec postgres psql -U $${DB_USER:-fllstck-tmplt-user} -d $${DB_NAME:-fllstck-tmplt}

db-dump:
	@mkdir -p db-dumps
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	DUMP_FILE="db-dumps/local_dump_$${TIMESTAMP}.sql"; \
	echo "Dumping local database to $${DUMP_FILE}..."; \
	docker compose -p fllstck-tmplt -f docker-compose.dev.yml exec -T postgres pg_dump \
		-U $${DB_USER:-fllstck-tmplt-user} \
		-d $${DB_NAME:-fllstck-tmplt} \
		--clean \
		--if-exists \
		--no-owner \
		--no-privileges \
		> "$${DUMP_FILE}"; \
	DUMP_SIZE=$$(du -h "$${DUMP_FILE}" | cut -f1); \
	echo "✓ Database dumped: $${DUMP_FILE} ($${DUMP_SIZE})"

# Migration Commands
db-migrate:
	uv run alembic upgrade head

db-generate-migration:
	@read -p "Enter migration description: " desc; \
	uv run alembic revision --autogenerate -m "$$desc"

db-migrate-downgrade:
	uv run alembic downgrade -1

db-migrate-history:
	uv run alembic history --verbose

# Docker Commands
docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-restart:
	docker compose restart backend

docker-shell:
	docker compose exec backend /bin/bash

docker-test:
	docker compose exec backend uv run pytest

docker-migrate:
	docker compose exec backend uv run alembic upgrade head

docker-reset-password:
	@if [ -z "$(EMAIL)" ] || [ -z "$(PASS)" ]; then \
		echo "Usage: make docker-reset-password EMAIL=user@example.com PASS=newpassword"; \
		exit 1; \
	fi
	docker compose exec backend uv run python scripts/reset-user-password.py "$(EMAIL)" "$(PASS)"

# Production Deployment Commands
replace-prod-db-with-local:
	@./scripts/replace-prod-db-with-local.sh

replace-local-db-with-prod:
	@./scripts/replace-local-db-with-prod.sh

# Code Generation Commands
api-generate:
	@echo "Generating Pydantic models for backend..."
	@uvx --from datamodel-code-generator datamodel-codegen --input ../api-design/autogenerated/openapi.yaml --output app/autogenerated/pydantic_models.py --output-model-type pydantic_v2.BaseModel --use-annotated --extra-fields=forbid
	@echo "✓ Backend Pydantic models generated!"
