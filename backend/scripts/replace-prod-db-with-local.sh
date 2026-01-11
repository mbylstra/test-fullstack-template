#!/bin/bash

# ============================================================================
# Database Migration Script: Local → Production
# ============================================================================
# This script:
# 1. Dumps the local database
# 2. Backs up the production database
# 3. Copies the local dump to the server
# 4. Restores the local dump to production
#
# ⚠️  WARNING: This REPLACES all production data with local data!
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="local_dump_${TIMESTAMP}.sql"
BACKUP_FILE="prod_backup_${TIMESTAMP}.sql"
TEMP_DIR="${BACKEND_DIR}/db-dumps"

# Local database configuration (from .env or defaults)
if [ -f "${BACKEND_DIR}/.env" ]; then
    source "${BACKEND_DIR}/.env"
fi

# Load .env.local for production server configuration (if exists)
if [ -f "${BACKEND_DIR}/.env.local" ]; then
    source "${BACKEND_DIR}/.env.local"
fi
LOCAL_DB_USER="${DB_USER:-todouser}"
LOCAL_DB_PASSWORD="${DB_PASSWORD:-todopass}"
LOCAL_DB_NAME="${DB_NAME:-tododoo}"
LOCAL_DB_HOST="${DB_HOST:-localhost}"
LOCAL_DB_PORT="${DB_PORT:-5432}"

# Production server configuration
PROD_SERVER="${PROD_SERVER:-}"
PROD_DIR="${PROD_DIR:-~/tododoo/backend}"
PROD_COMPOSE_FILE="docker-compose.prod.yml"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker command not found"
        echo "Please install Docker"
        exit 1
    fi
    print_success "Docker is available"

    # Check if local database is running
    if ! docker ps | grep -q tododoo-postgres; then
        print_error "Local database container is not running"
        echo "Please start it with: make db-up"
        exit 1
    fi
    print_success "Local database container is running"

    # Check SSH access to production server
    if [ -z "$PROD_SERVER" ]; then
        print_error "PROD_SERVER not set"
        echo "Please set PROD_SERVER environment variable or edit .env.local"
        echo "Example: echo 'PROD_SERVER=root@<droplet-ip>' >> .env.local"
        exit 1
    fi

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$PROD_SERVER" exit 2>/dev/null; then
        print_error "Cannot connect to production server: $PROD_SERVER"
        echo "Please check your SSH configuration"
        exit 1
    fi
    print_success "SSH connection to production server verified"

    # Create temp directory
    mkdir -p "$TEMP_DIR"
    print_success "Temporary directory ready: $TEMP_DIR"
}

dump_local_database() {
    print_header "Dumping Local Database"

    print_warning "Dumping database: $LOCAL_DB_NAME (user: $LOCAL_DB_USER)"

    # Use docker compose exec which properly handles environment variables
    cd "$BACKEND_DIR"
    docker compose exec -T postgres pg_dump \
        -U "$LOCAL_DB_USER" \
        -d "$LOCAL_DB_NAME" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        > "${TEMP_DIR}/${DUMP_FILE}"

    DUMP_SIZE=$(du -h "${TEMP_DIR}/${DUMP_FILE}" | cut -f1)
    print_success "Local database dumped: ${DUMP_FILE} (${DUMP_SIZE})"
}

backup_production_database() {
    print_header "Backing Up Production Database"

    print_warning "Creating production database backup on server..."

    ssh "$PROD_SERVER" bash -s << EOF
        cd "${PROD_DIR}"

        # Source the .env file to get database credentials
        if [ -f .env ]; then
            export \$(cat .env | grep -v '^#' | xargs)
        fi

        docker compose -f "${PROD_COMPOSE_FILE}" exec -T postgres \
            pg_dump -U "\${DB_USER}" -d "\${DB_NAME}" \
            --clean \
            --if-exists \
            --no-owner \
            --no-privileges \
            > "${BACKUP_FILE}"
EOF

    print_success "Production database backed up: ${BACKUP_FILE}"
    print_warning "Backup is stored on the server at: ${PROD_DIR}/${BACKUP_FILE}"
}

copy_dump_to_server() {
    print_header "Copying Dump to Production Server"

    scp "${TEMP_DIR}/${DUMP_FILE}" "${PROD_SERVER}:${PROD_DIR}/${DUMP_FILE}"

    print_success "Dump file copied to server"
}

restore_to_production() {
    print_header "Restoring to Production Database"

    print_warning "Dropping and recreating production database..."

    ssh "$PROD_SERVER" bash -s << EOF
        cd "${PROD_DIR}"

        # Source the .env file to get database credentials
        if [ -f .env ]; then
            export \$(cat .env | grep -v '^#' | xargs)
        fi

        # Restore the database from dump
        docker compose -f "${PROD_COMPOSE_FILE}" exec -T postgres \
            psql -U "\${DB_USER}" -d "\${DB_NAME}" < "${DUMP_FILE}"

        # Run migrations to ensure schema is up to date
        echo "Running database migrations..."
        docker compose -f "${PROD_COMPOSE_FILE}" exec -T backend \
            uv run alembic upgrade head

        # Clean up dump file
        rm -f "${DUMP_FILE}"
EOF

    print_success "Database restored and migrations applied"
}

cleanup() {
    print_header "Cleanup"

    if [ -f "${TEMP_DIR}/${DUMP_FILE}" ]; then
        rm -f "${TEMP_DIR}/${DUMP_FILE}"
        print_success "Local dump file removed"
    fi

    print_success "Cleanup complete"
}

verify_production() {
    print_header "Verifying Production"

    echo -e "${BLUE}Testing production API health endpoint...${NC}"
    if curl -sf https://todo-backend.michaelbylstra.com/health > /dev/null; then
        print_success "Production API is responding"
    else
        print_warning "Could not verify production API health"
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║              ⚠️  DATABASE MIGRATION TO PRODUCTION  ⚠️           ║"
    echo "║                                                                ║"
    echo "║  This script will REPLACE all production data with local data ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"

    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Local DB:         ${LOCAL_DB_USER}@${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB_NAME}"
    echo "  Production Server: ${PROD_SERVER}"
    echo "  Production Path:   ${PROD_DIR}"
    echo ""

    read -p "Are you sure you want to continue? (type 'yes' to proceed): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi

    echo ""
    read -p "Type the database name '${LOCAL_DB_NAME}' to confirm: " db_confirm
    if [ "$db_confirm" != "$LOCAL_DB_NAME" ]; then
        echo "Database name mismatch. Aborted."
        exit 0
    fi

    echo ""

    # Execute migration steps
    check_prerequisites
    dump_local_database
    backup_production_database
    copy_dump_to_server
    restore_to_production
    cleanup
    verify_production

    # Final summary
    print_header "Migration Complete!"

    echo -e "${GREEN}✓ Local database successfully migrated to production${NC}"
    echo -e "${YELLOW}⚠ Production backup saved as: ${BACKUP_FILE}${NC}"
    echo -e "${YELLOW}⚠ The backup is stored on the server at: ${PROD_DIR}/${BACKUP_FILE}${NC}"
    echo ""
    echo -e "${BLUE}To rollback, run on the server:${NC}"
    echo -e "  cd ${PROD_DIR}"
    echo -e "  docker compose -f ${PROD_COMPOSE_FILE} exec -T postgres \\"
    echo -e "    psql -U \${DB_USER} -d \${DB_NAME} < ${BACKUP_FILE}"
    echo ""
}

# Run main function
main
