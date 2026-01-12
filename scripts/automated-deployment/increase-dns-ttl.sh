#!/bin/bash
# increase-dns-ttl.sh
# Increases DNS TTL for production after initial testing
#
# Run this script after verifying your domains are working correctly.
# Low TTL is useful for testing but increases DNS query load.
# Higher TTL improves performance and reduces DNS costs.

set -e

# ============================================================================
# CONFIGURATION - Must match setup-automated-deployment.sh
# ============================================================================

DO_DOMAIN="michaelbylstra.com"
BACKEND_SUBDOMAIN="fllstck-tmplt-backend"
FRONTEND_SUBDOMAIN="fllstck-tmplt-frontend"

# TTL Configuration
NEW_TTL=3600  # 1 hour - good balance between performance and flexibility

# ============================================================================
# COLOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

log_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Increase DNS TTL for Production${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if doctl is installed and authenticated
if ! command -v doctl &> /dev/null; then
    log_error "Digital Ocean CLI (doctl) is not installed"
    exit 1
fi

if ! doctl account get &> /dev/null; then
    log_error "Digital Ocean CLI is not authenticated. Run: doctl auth init"
    exit 1
fi

log_info "This script will increase DNS TTL to ${NEW_TTL} seconds ($(($NEW_TTL / 60)) minutes)"
log_warning "Only do this AFTER verifying your domains are working correctly!"
echo ""

read -p "Have you verified both domains are working? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled. Test your domains first:"
    log_info "  Backend:  https://${BACKEND_SUBDOMAIN}.${DO_DOMAIN}/health"
    log_info "  Frontend: https://${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"
    exit 0
fi

# Update Backend A record TTL
log_info "Updating TTL for backend A record..."

BACKEND_RECORD=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type --no-header | grep "${BACKEND_SUBDOMAIN} A")

if [ -n "$BACKEND_RECORD" ]; then
    RECORD_ID=$(echo "$BACKEND_RECORD" | awk '{print $1}')
    RECORD_DATA=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Data --no-header | grep "^${RECORD_ID}" | awk '{print $2}')

    doctl compute domain records update ${DO_DOMAIN} \
        --record-id ${RECORD_ID} \
        --record-data ${RECORD_DATA} \
        --record-ttl ${NEW_TTL}

    log_success "Updated backend DNS record TTL to ${NEW_TTL}s"
else
    log_warning "Backend A record not found, skipping"
fi

# Update Frontend CNAME record TTL
log_info "Updating TTL for frontend CNAME record..."

FRONTEND_RECORD=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type --no-header | grep "${FRONTEND_SUBDOMAIN} CNAME")

if [ -n "$FRONTEND_RECORD" ]; then
    RECORD_ID=$(echo "$FRONTEND_RECORD" | awk '{print $1}')
    RECORD_DATA=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Data --no-header | grep "^${RECORD_ID}" | awk '{print $2}')

    doctl compute domain records update ${DO_DOMAIN} \
        --record-id ${RECORD_ID} \
        --record-data ${RECORD_DATA} \
        --record-ttl ${NEW_TTL}

    log_success "Updated frontend DNS record TTL to ${NEW_TTL}s"
else
    log_warning "Frontend CNAME record not found, skipping"
fi

echo ""
log_success "DNS TTL update complete!"
echo ""
log_info "Current DNS records:"
doctl compute domain records list ${DO_DOMAIN} | grep -E "${BACKEND_SUBDOMAIN}|${FRONTEND_SUBDOMAIN}"
echo ""
log_info "Note: Changes take effect immediately, but cached DNS entries"
log_info "with the old TTL may persist until they expire."
echo ""
