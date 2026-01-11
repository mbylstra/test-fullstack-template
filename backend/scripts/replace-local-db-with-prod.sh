#!/bin/bash

# ============================================================================
# Database Migration Script: Production → Local
# ============================================================================
# This script:
# 1. Dumps the production database
# 2. Backs up the local database
# 3. Copies the production dump to local machine
# 4. Restores the production dump to local database
#
# ⚠️  WARNING: This REPLACES all local data with production data!
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
DUMP_FILE="prod_dump_${TIMESTAMP}.sql"
BACKUP_FILE="local_backup_${TIMESTAMP}.sql"
TEMP_DIR="${BACKEND_DIR}/db-dumps"

# Local database configuration (from .env or defaults)
if [ -f "${BACKEND_DIR}/.env" ]; then
    source "${BACKEND_DIR}/.env"
fi

# Load .env.local for production server configuration (if exists)
if [ -f "${BACKEND_DIR}/.env.local" ]; then
    source "${BACKEND_DIR}/.env.local"
fi
LOCAL_DB_USER="${DB_USER:-fllstck-tmplt-user}"
LOCAL_DB_PASSWORD="${DB_PASSWORD:-fllstck-tmplt-pass}"
LOCAL_DB_NAME="${DB_NAME:-fllstck-tmplt}"
LOCAL_DB_HOST="${DB_HOST:-localhost}"
LOCAL_DB_PORT="${DB_PORT:-5432}"

# Local user credentials for password reset
LOCAL_MAIN_USER_EMAIL="${LOCAL_MAIN_USER_EMAIL:-}"
LOCAL_MAIN_USER_PASSWORD="${LOCAL_MAIN_USER_PASSWORD:-}"

# Production server configuration
PROD_SERVER="${PROD_SERVER:-}"
PROD_DIR="${PROD_DIR:-~/fllstck-tmplt/backend}"
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
    if ! docker ps | grep -q fllstck-tmplt-postgres; then
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

dump_production_database() {
    print_header "Dumping Production Database"

    print_warning "Creating production database dump on server..."

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
            > "${DUMP_FILE}"
EOF

    print_success "Production database dumped: ${DUMP_FILE}"
}

copy_dump_from_server() {
    print_header "Copying Dump from Production Server"

    scp "${PROD_SERVER}:${PROD_DIR}/${DUMP_FILE}" "${TEMP_DIR}/${DUMP_FILE}"

    DUMP_SIZE=$(du -h "${TEMP_DIR}/${DUMP_FILE}" | cut -f1)
    print_success "Dump file copied from server (${DUMP_SIZE})"

    # Clean up dump file on server
    ssh "$PROD_SERVER" "rm -f ${PROD_DIR}/${DUMP_FILE}"
    print_success "Dump file removed from server"
}

backup_local_database() {
    print_header "Backing Up Local Database"

    print_warning "Creating local database backup..."

    # Use docker compose exec which properly handles environment variables
    cd "$BACKEND_DIR"
    docker compose exec -T postgres pg_dump \
        -U "$LOCAL_DB_USER" \
        -d "$LOCAL_DB_NAME" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        > "${TEMP_DIR}/${BACKUP_FILE}"

    BACKUP_SIZE=$(du -h "${TEMP_DIR}/${BACKUP_FILE}" | cut -f1)
    print_success "Local database backed up: ${BACKUP_FILE} (${BACKUP_SIZE})"
}

restore_to_local() {
    print_header "Restoring to Local Database"

    print_warning "Restoring production dump to local database..."

    cd "$BACKEND_DIR"
    docker compose exec -T postgres \
        psql -U "$LOCAL_DB_USER" -d "$LOCAL_DB_NAME" < "${TEMP_DIR}/${DUMP_FILE}"

    print_success "Database restored from production dump"

    # Run migrations to ensure schema is up to date
    echo "Running database migrations..."
    uv run alembic upgrade head

    print_success "Migrations applied"
}

reset_local_user_password() {
    print_header "Resetting Local User Password"

    if [ -z "$LOCAL_MAIN_USER_EMAIL" ] || [ -z "$LOCAL_MAIN_USER_PASSWORD" ]; then
        print_warning "LOCAL_MAIN_USER_EMAIL or LOCAL_MAIN_USER_PASSWORD not set"
        print_warning "Skipping password reset. Set these in .env.local to enable."
        return 0
    fi

    print_warning "Resetting password for: ${LOCAL_MAIN_USER_EMAIL}"

    cd "$BACKEND_DIR"
    if uv run python scripts/reset-user-password.py "$LOCAL_MAIN_USER_EMAIL" "$LOCAL_MAIN_USER_PASSWORD"; then
        print_success "Local user password reset successfully"
    else
        print_warning "Failed to reset local user password"
        print_warning "You may need to reset it manually"
    fi
}

cleanup() {
    print_header "Cleanup"

    if [ -f "${TEMP_DIR}/${DUMP_FILE}" ]; then
        rm -f "${TEMP_DIR}/${DUMP_FILE}"
        print_success "Production dump file removed"
    fi

    print_success "Cleanup complete"
}

verify_local() {
    print_header "Verifying Local Database"

    echo -e "${BLUE}Checking database connection...${NC}"
    cd "$BACKEND_DIR"
    if docker compose exec -T postgres psql -U "$LOCAL_DB_USER" -d "$LOCAL_DB_NAME" -c "SELECT COUNT(*) FROM fllstck-tmplt-s;" > /dev/null 2>&1; then
        print_success "Local database is accessible"
    else
        print_warning "Could not verify local database"
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║              ⚠️  DATABASE MIGRATION FROM PRODUCTION  ⚠️         ║"
    echo "║                                                                ║"
    echo "║  This script will REPLACE all local data with production data ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"

    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Production Server: ${PROD_SERVER}"
    echo "  Production Path:   ${PROD_DIR}"
    echo "  Local DB:         ${LOCAL_DB_USER}@${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB_NAME}"
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
    dump_production_database
    copy_dump_from_server
    backup_local_database
    restore_to_local
    reset_local_user_password
    cleanup
    verify_local

    # Final summary
    print_header "Migration Complete!"

    echo -e "${GREEN}✓ Production database successfully migrated to local${NC}"
    echo -e "${YELLOW}⚠ Local backup saved as: ${BACKUP_FILE}${NC}"
    echo -e "${YELLOW}⚠ The backup is stored at: ${TEMP_DIR}/${BACKUP_FILE}${NC}"
    echo ""
    echo -e "${BLUE}To rollback, run:${NC}"
    echo -e "  cd ${BACKEND_DIR}"
    echo -e "  docker compose exec -T postgres \\"
    echo -e "    psql -U ${LOCAL_DB_USER} -d ${LOCAL_DB_NAME} < ${TEMP_DIR}/${BACKUP_FILE}"
    echo ""
}

# Run main function
main
