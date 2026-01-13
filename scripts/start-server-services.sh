#!/bin/bash

# Get the directory where this script is located (scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Start Server Services Script${NC}"
echo "=============================="
echo

# Default to flipper2.michaelbylstra.com if SERVER_HOST not set
SERVER_HOST=${SERVER_HOST:-"flipper2.michaelbylstra.com"}

# Default project directory on server
SERVER_PROJECT_DIR=${SERVER_PROJECT_DIR:-"~/projects/fllstck-tmplt"}

# Optional: Path to docker-compose file on server
SERVER_COMPOSE_PATH=${SERVER_COMPOSE_PATH:-"${SERVER_PROJECT_DIR}/backend/docker-compose.prod.yml"}

echo -e "${YELLOW}Server:${NC} $SERVER_HOST"
echo -e "${YELLOW}Compose file:${NC} $SERVER_COMPOSE_PATH"
echo

# Confirm with user
read -p "Start services on this server? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo
echo -e "${GREEN}Starting services on server...${NC}"

# SSH into server and start services
ssh "$SERVER_HOST" << 'EOF'
    set -e

    echo "Starting backend and database services..."

    # Navigate to backend directory
    cd ~/projects/fllstck-tmplt/backend || { echo "Error: ~/projects/fllstck-tmplt/backend directory not found"; exit 1; }

    # Pull latest images
    echo "Pulling latest images..."
    docker compose -p fllstck-tmplt -f docker-compose.prod.yml pull

    # Start services
    echo "Starting services..."
    docker compose -p fllstck-tmplt -f docker-compose.prod.yml up -d --wait

    echo "✓ Services started successfully"
    echo ""
    echo "Service status:"
    docker compose -p fllstck-tmplt -f docker-compose.prod.yml ps
EOF

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}✓ Services started successfully on server${NC}"
    echo
    echo -e "${YELLOW}To check logs, SSH into the server and run:${NC}"
    echo "  cd ~/projects/fllstck-tmplt/backend && docker compose -p fllstck-tmplt -f docker-compose.prod.yml logs -f"
else
    echo
    echo -e "${RED}✗ Failed to start services${NC}"
    exit 1
fi
