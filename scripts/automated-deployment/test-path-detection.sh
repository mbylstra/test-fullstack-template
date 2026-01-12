#!/bin/bash
# test-path-detection.sh
# Tests that path detection works from any directory

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Testing path detection for setup-automated-deployment.sh"
echo ""

# Get script location (same logic as main script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/../.." && pwd )"
FRONTEND_DIR="${PROJECT_ROOT}/web-frontend"
BACKEND_DIR="${PROJECT_ROOT}/backend"

echo "Script directory: ${SCRIPT_DIR}"
echo "Project root: ${PROJECT_ROOT}"
echo "Frontend directory: ${FRONTEND_DIR}"
echo "Backend directory: ${BACKEND_DIR}"
echo ""

# Check directories exist
if [ -d "${FRONTEND_DIR}" ]; then
    echo -e "${GREEN}✓ Frontend directory exists${NC}"
else
    echo -e "${RED}✗ Frontend directory NOT found${NC}"
    exit 1
fi

if [ -d "${BACKEND_DIR}" ]; then
    echo -e "${GREEN}✓ Backend directory exists${NC}"
else
    echo -e "${RED}✗ Backend directory NOT found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ All path detection tests passed!${NC}"
echo ""
echo "The script can be run from any directory and will correctly find:"
echo "  - Frontend: ${FRONTEND_DIR}"
echo "  - Backend: ${BACKEND_DIR}"
