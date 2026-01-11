.DEFAULT_GOAL := help
.PHONY: help dev-all dev-debug test typecheck customize-template rebase-from-latest-template merge-latest-template track-template-repo api-compile api-watch api-format api-generate

help:
	@echo "Root Level Commands:"
	@echo "  make dev-all      - Start database, backend, and frontend together"
	@echo "  make dev-debug    - Start database and frontend (use VSCode debugger for backend)"
	@echo "  make test         - Run backend tests"
	@echo "  make typecheck    - Typecheck TypeSpec, frontend, and backend"
	@echo ""
	@echo "API Specification Commands:"
	@echo "  make api-compile  - Compile TypeSpec to OpenAPI specification"
	@echo "  make api-generate - Compile API spec + generate Pydantic models + generate frontend client"
	@echo "  make api-watch    - Watch and auto-compile TypeSpec changes"
	@echo "  make api-format   - Format TypeSpec files"
	@echo ""
	@echo "Frontend commands: cd web-frontend && make"
	@echo "Backend commands:  cd backend && make"
	@echo ""
	@echo "Template Commands:"
	@echo "  make customize-template           - Customize template with new app name"
	@echo "  make rebase-from-latest-template  - Rebase current branch on latest template changes"
	@echo "  make merge-latest-template        - Merge latest template changes into current branch"
	@echo "  make track-template-repo          - Set up git remote to track template repository"

dev-all:
	@echo "Starting all services..."
	@echo ""
	@echo "Checking for processes on ports 8000 and 5173..."
	@lsof -ti:8000 | xargs kill -9 2>/dev/null || true
	@lsof -ti:5173 | xargs kill -9 2>/dev/null || true
	@echo ""
	@echo "Starting database and waiting for health check..."
	@cd backend && docker compose -p fllstck-tmplt -f docker-compose.dev.yml up -d --wait
	@echo ""
	@echo "Starting backend and frontend..."
	@echo "Backend will run on http://localhost:8000 (with hot reload)"
	@echo "Frontend will run on http://localhost:5173"
	@echo ""
	@echo "Press Ctrl+C to stop all services"
	@echo ""
	@trap 'echo "Stopping services..."; cd backend && $(MAKE) db-down; exit 0' INT; \
	pnpm exec concurrently \
		--names "backend,frontend" \
		--prefix-colors "blue,magenta" \
		--kill-others \
		"cd backend && $(MAKE) dev" \
		"cd web-frontend && $(MAKE) dev"

dev-debug:
	@echo "Starting services for debugging..."
	@echo ""
	@echo "Checking for processes on ports 8000 and 5173..."
	@lsof -ti:8000 | xargs kill -9 2>/dev/null || true
	@lsof -ti:5173 | xargs kill -9 2>/dev/null || true
	@echo ""
	@echo "Starting database and waiting for health check..."
	@cd backend && docker compose -p fllstck-tmplt -f docker-compose.dev.yml up -d --wait
	@echo ""
	@echo "Starting frontend (Vite dev server)..."
	@trap 'echo "Stopping services..."; cd backend && $(MAKE) db-down; exit 0' INT; \
	cd web-frontend && $(MAKE) dev > /dev/null 2>&1 & \
	FRONTEND_PID=$$!; \
	sleep 2; \
	echo ""; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo "✓ Frontend running on http://localhost:5173"; \
	echo ""; \
	echo "⚠️  Backend NOT started - use VSCode debugger to start with breakpoints:"; \
	echo ""; \
	echo "  1. Open VSCode in this project"; \
	echo "  2. Set breakpoints in Python files (e.g., backend/app/models/todo.py)"; \
	echo "  3. Press F5 (or Run → Start Debugging)"; \
	echo "  4. Select 'FastAPI: Debug' from the dropdown"; \
	echo "  5. Backend will start on http://localhost:8000 with debugger attached"; \
	echo ""; \
	echo "  Your breakpoints will pause execution when hit!"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo ""; \
	echo "Press Ctrl+C to stop services"; \
	echo ""; \
	wait $$FRONTEND_PID

customize-template:
	./scripts/customize-template.sh

rebase-from-latest-template:
	./scripts/rebase-from-latest-template.sh

merge-latest-template:
	./scripts/merge-latest-template.sh

track-template-repo:
	./scripts/track-template-repo.sh

# API Specification Commands
api-compile:
	pnpm exec tsp compile api-design

api-watch:
	pnpm exec tsp compile api-design --watch

api-format:
	pnpm exec tsp format api-design/**/*.tsp

api-generate:
	@echo "Compiling TypeSpec to OpenAPI..."
	@$(MAKE) api-compile
	@echo ""
	@cd backend && $(MAKE) api-generate
	@echo ""
	@cd web-frontend && $(MAKE) api-generate
	@echo ""
	@echo "✓ API generation complete!"

test:
	cd backend && $(MAKE) test

typecheck:
	@echo "Typechecking TypeSpec..."
	@pnpm exec tsp compile api-design --no-emit
	@echo ""
	@echo "Typechecking frontend..."
	@cd web-frontend && $(MAKE) typecheck
	@echo ""
	@echo "Typechecking backend..."
	@cd backend && $(MAKE) typecheck
	@echo ""
	@echo "✓ All typecheck passed!"
