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

echo -e "${GREEN}Stop Server Services Script${NC}"
echo "============================="
echo

# Check for required environment variables
if [ -z "$SERVER_HOST" ]; then
    echo -e "${RED}Error: SERVER_HOST environment variable not set${NC}"
    echo "Please set SERVER_HOST to your server address (e.g., user@example.com)"
    exit 1
fi

# Optional: Path to docker-compose file on server (defaults to ~/backend/docker-compose.prod.yml)
SERVER_COMPOSE_PATH=${SERVER_COMPOSE_PATH:-"~/backend/docker-compose.prod.yml"}

echo -e "${YELLOW}Server:${NC} $SERVER_HOST"
echo -e "${YELLOW}Compose file:${NC} $SERVER_COMPOSE_PATH"
echo

# Confirm with user
read -p "Stop services on this server? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo
echo -e "${GREEN}Stopping services on server...${NC}"

# SSH into server and stop services
ssh "$SERVER_HOST" << 'EOF'
    set -e

    echo "Stopping backend and database services..."

    # Navigate to backend directory
    cd ~/backend || { echo "Error: ~/backend directory not found"; exit 1; }

    # Stop services without removing volumes
    docker compose -p fllstck-tmplt -f docker-compose.prod.yml down

    echo "✓ Services stopped successfully"
    echo "Note: Database volume preserved - data will be available when services restart"
EOF

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}✓ Services stopped successfully on server${NC}"
    echo
    echo -e "${YELLOW}To restart services, SSH into the server and run:${NC}"
    echo "  cd ~/backend && docker compose -p fllstck-tmplt -f docker-compose.prod.yml up -d"
else
    echo
    echo -e "${RED}✗ Failed to stop services${NC}"
    exit 1
fi
