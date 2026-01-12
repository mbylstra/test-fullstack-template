#!/bin/bash
# setup-automated-deployment.sh
# Automates the deployment setup for the full-stack-template project
#
# Prerequisites:
# - GitHub CLI (gh) installed and authenticated
# - Digital Ocean CLI (doctl) installed and authenticated
# - SSH access to the droplet
# - Docker installed on the droplet (already done)
#
# Can be run from any directory - automatically detects project root

set -e  # Exit on error

# ============================================================================
# PATH DETECTION - Determine script and project root directories
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get the project root (two levels up from scripts/automated-deployment/)
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/../.." && pwd )"

# Define key directories
FRONTEND_DIR="${PROJECT_ROOT}/web-frontend"
BACKEND_DIR="${PROJECT_ROOT}/backend"

# ============================================================================
# CONFIGURATION - Update these values for your setup
# ============================================================================

# Droplet Configuration
DROPLET_HOST="flipper2.michaelbylstra.com"
DROPLET_USER="root"
DROPLET_SSH_PORT="22"

# GitHub Configuration
GITHUB_REPO="mbylstra/fllstck-tmplt"
GITHUB_USERNAME="mbylstra"

# Project Configuration
PROJECT_NAME="fllstck-tmplt"

# Digital Ocean DNS Configuration
DO_DOMAIN="michaelbylstra.com"
BACKEND_SUBDOMAIN="${PROJECT_NAME}-backend"
FRONTEND_SUBDOMAIN="${PROJECT_NAME}"
PROJECT_DIR_ON_DROPLET="~/projects/${PROJECT_NAME}"

# Database Configuration
DB_USER="${PROJECT_NAME}-user"
DB_NAME="${PROJECT_NAME}"
DB_HOST="postgres"
DB_PORT="5432"

# Backend Configuration
API_DOMAIN="${BACKEND_SUBDOMAIN}.${DO_DOMAIN}"
FRONTEND_DOMAIN="${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"
CORS_ORIGINS="https://${FRONTEND_DOMAIN},https://${NETLIFY_SITE_NAME}.netlify.app"

# Netlify Configuration
NETLIFY_SITE_NAME="mb-${PROJECT_NAME}"  # Your Netlify site name with mb- prefix (e.g., mb-fllstck-tmplt.netlify.app)
NETLIFY_CUSTOM_DOMAIN="${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"  # Custom domain
NETLIFY_ACCESS_TOKEN=""  # Set via prompt during setup (get from https://app.netlify.com/user/access-tokens)

# DNS TTL Configuration
DNS_TTL_INITIAL=60  # Low TTL for initial testing (60 seconds = 1 minute)
DNS_TTL_PRODUCTION=3600  # Higher TTL for production (3600 seconds = 1 hour) for Netlify

# SSH Key Configuration
SSH_KEY_PATH="${HOME}/.ssh/github_actions_deploy_${PROJECT_NAME}"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  ${1}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

log_section "Pre-flight Checks"

# Verify project structure
log_info "Detected project root: ${PROJECT_ROOT}"

if [ ! -d "${FRONTEND_DIR}" ]; then
    log_error "Frontend directory not found: ${FRONTEND_DIR}"
    log_error "This script must be run from within the full-stack-template project"
    log_error "Make sure you're running: /path/to/project/scripts/automated-deployment/setup-automated-deployment.sh"
    exit 1
fi

if [ ! -d "${BACKEND_DIR}" ]; then
    log_error "Backend directory not found: ${BACKEND_DIR}"
    log_error "This script must be run from within the full-stack-template project"
    exit 1
fi

log_success "Project structure verified (frontend and backend directories found)"

# Check if gh is installed and authenticated
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI is not authenticated. Run: gh auth login"
    exit 1
fi
log_success "GitHub CLI is installed and authenticated"

# Check if doctl is installed and authenticated
if ! command -v doctl &> /dev/null; then
    log_warning "Digital Ocean CLI (doctl) is not installed. DNS setup will be skipped."
    log_warning "Install from: https://docs.digitalocean.com/reference/doctl/how-to/install/"
    SKIP_DNS=true
else
    if ! doctl account get &> /dev/null; then
        log_warning "Digital Ocean CLI is not authenticated. DNS setup will be skipped."
        log_warning "Run: doctl auth init"
        SKIP_DNS=true
    else
        log_success "Digital Ocean CLI is installed and authenticated"
        SKIP_DNS=false
    fi
fi

# Check if netlify CLI is installed and authenticated
if ! command -v netlify &> /dev/null; then
    log_warning "Netlify CLI is not installed. Netlify setup will be skipped."
    log_warning "Install with: npm install -g netlify-cli"
    SKIP_NETLIFY=true
else
    # Check authentication by looking for user info in status output
    # netlify status returns non-zero when not in a linked directory, but that's OK
    NETLIFY_STATUS_OUTPUT=$(netlify status 2>&1 || true)
    if echo "$NETLIFY_STATUS_OUTPUT" | grep -q "Current Netlify User"; then
        log_success "Netlify CLI is installed and authenticated"
        SKIP_NETLIFY=false
    else
        log_warning "Netlify CLI is not authenticated. Netlify setup will be skipped."
        log_warning "Run: netlify login"
        SKIP_NETLIFY=true
    fi
fi

# Prompt for Netlify access token if not set (needed for API calls)
if [ -z "$NETLIFY_ACCESS_TOKEN" ]; then
    echo ""
    log_info "Netlify Access Token is needed to add custom domain via API"
    log_info "Get your token from: https://app.netlify.com/user/access-tokens"
    read -p "Enter your Netlify Access Token (or press Enter to skip): " NETLIFY_ACCESS_TOKEN
    echo ""
fi

# Check SSH access to droplet
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes ${DROPLET_USER}@${DROPLET_HOST} exit &> /dev/null; then
    log_warning "Cannot connect to droplet via SSH with current credentials"
    log_warning "You may need to enter a password during setup"
fi

# Check if droplet has SSH access to GitHub
log_info "Checking if droplet has SSH access to GitHub..."
if ssh -o ConnectTimeout=5 ${DROPLET_USER}@${DROPLET_HOST} "ssh -T git@github.com 2>&1 | grep -q 'successfully authenticated'" &> /dev/null; then
    log_success "Droplet has SSH access to GitHub"
else
    log_warning "Droplet does not have SSH access to GitHub"
    log_warning "You'll need to set up SSH keys on the droplet for GitHub access"
    log_info "Instructions will be provided if needed during setup"
    DROPLET_NEEDS_GITHUB_SSH=true
fi

log_success "Pre-flight checks complete"

# ============================================================================
# STEP 1: GENERATE SSH KEY FOR GITHUB ACTIONS
# ============================================================================

log_section "Step 1: Generate SSH Key for GitHub Actions"

if [ -f "${SSH_KEY_PATH}" ]; then
    log_warning "SSH key already exists at ${SSH_KEY_PATH}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Using existing SSH key"
    else
        rm -f "${SSH_KEY_PATH}" "${SSH_KEY_PATH}.pub"
        ssh-keygen -t ed25519 -C "github-actions-deploy-${PROJECT_NAME}" -f "${SSH_KEY_PATH}" -N ""
        log_success "Generated new SSH key pair"
    fi
else
    ssh-keygen -t ed25519 -C "github-actions-deploy-${PROJECT_NAME}" -f "${SSH_KEY_PATH}" -N ""
    log_success "Generated new SSH key pair"
fi

log_info "Public key location: ${SSH_KEY_PATH}.pub"
log_info "Private key location: ${SSH_KEY_PATH}"

# ============================================================================
# STEP 2: ADD SSH PUBLIC KEY TO DROPLET
# ============================================================================

log_section "Step 2: Add SSH Public Key to Droplet"

log_info "Adding public key to droplet's authorized_keys..."

# Copy the public key to the droplet
ssh-copy-id -i "${SSH_KEY_PATH}.pub" "${DROPLET_USER}@${DROPLET_HOST}" || {
    log_error "Failed to copy SSH key to droplet"
    log_info "You may need to manually add the public key:"
    log_info "  cat ${SSH_KEY_PATH}.pub"
    log_info "Then on the droplet:"
    log_info "  echo 'PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys"
    log_info "  chmod 600 ~/.ssh/authorized_keys"
    exit 1
}

# Test the SSH connection with the new key
if ssh -i "${SSH_KEY_PATH}" -o ConnectTimeout=5 ${DROPLET_USER}@${DROPLET_HOST} exit; then
    log_success "SSH key successfully added to droplet"
else
    log_error "Failed to authenticate with new SSH key"
    exit 1
fi

# ============================================================================
# STEP 3: CONFIGURE GITHUB SECRETS
# ============================================================================

log_section "Step 3: Configure GitHub Secrets"

log_info "Setting DROPLET_HOST..."
gh secret set DROPLET_HOST --body "${DROPLET_HOST}" --repo "${GITHUB_REPO}"
log_success "Set DROPLET_HOST"

log_info "Setting DROPLET_USER..."
gh secret set DROPLET_USER --body "${DROPLET_USER}" --repo "${GITHUB_REPO}"
log_success "Set DROPLET_USER"

log_info "Setting DROPLET_SSH_KEY..."
gh secret set DROPLET_SSH_KEY < "${SSH_KEY_PATH}" --repo "${GITHUB_REPO}"
log_success "Set DROPLET_SSH_KEY"

log_success "All GitHub secrets configured"

# Verify secrets
echo ""
log_info "Current GitHub secrets:"
gh secret list --repo "${GITHUB_REPO}"

# ============================================================================
# STEP 4: CONFIGURE DNS RECORDS
# ============================================================================

log_section "Step 4: Configure DNS Records"

if [ "$SKIP_DNS" = true ]; then
    log_warning "Skipping DNS configuration"
    log_info "You'll need to manually create DNS records:"
    log_info "  A record: ${BACKEND_SUBDOMAIN}.${DO_DOMAIN} -> ${DROPLET_HOST}"
    log_info "  A record: ${FRONTEND_SUBDOMAIN}.${DO_DOMAIN} -> ${DROPLET_HOST}"
else
    # Get droplet IP address
    DROPLET_IP=$(dig +short ${DROPLET_HOST} | head -n 1)

    if [ -z "$DROPLET_IP" ]; then
        log_error "Could not resolve droplet IP address"
        exit 1
    fi

    log_info "Droplet IP address: ${DROPLET_IP}"

    # Create backend A record
    log_info "Creating DNS record for backend: ${BACKEND_SUBDOMAIN}.${DO_DOMAIN}"

    # Check if record already exists
    EXISTING_RECORD=$(doctl compute domain records list ${DO_DOMAIN} --format Name,Type,Data --no-header | grep "^${BACKEND_SUBDOMAIN} A" || true)

    if [ -n "$EXISTING_RECORD" ]; then
        log_warning "DNS record already exists for ${BACKEND_SUBDOMAIN}"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            RECORD_ID=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type --no-header | grep "${BACKEND_SUBDOMAIN} A" | awk '{print $1}')
            doctl compute domain records update ${DO_DOMAIN} --record-id ${RECORD_ID} --record-data ${DROPLET_IP}
            log_success "Updated DNS record for backend"
        fi
    else
        doctl compute domain records create ${DO_DOMAIN} \
            --record-type A \
            --record-name ${BACKEND_SUBDOMAIN} \
            --record-data ${DROPLET_IP} \
            --record-ttl ${DNS_TTL_INITIAL}
        log_success "Created DNS record for backend (TTL: ${DNS_TTL_INITIAL}s for testing)"
        log_info "Note: Increase TTL to ${DNS_TTL_PRODUCTION}s once domain is working"
    fi

    log_success "Backend DNS configuration complete"
    log_info "Backend URL: https://${API_DOMAIN}"
    log_info "DNS propagation may take a few minutes"
fi

# ============================================================================
# STEP 5: CONFIGURE NETLIFY CUSTOM DOMAIN
# ============================================================================

log_section "Step 5: Configure Netlify Custom Domain"

if [ "$SKIP_NETLIFY" = true ]; then
    log_warning "Skipping Netlify configuration (CLI not installed/authenticated)"
    log_info "To set up manually:"
    log_info "  1. Go to your Netlify site dashboard"
    log_info "  2. Navigate to Domain management > Domains"
    log_info "  3. Add custom domain: ${NETLIFY_CUSTOM_DOMAIN}"
    log_info "  4. Netlify will provide DNS instructions"
    log_info "  5. SSL certificate will be provisioned automatically"
else
    log_info "Configuring Netlify site with custom domain..."

    # Check if site exists
    log_info "Checking for Netlify site: ${NETLIFY_SITE_NAME}"

    # List all sites and check if one matches our site name
    # Use 'set +e' temporarily to prevent script exit on command failure
    set +e
    SITE_LIST_OUTPUT=$(netlify api listSites 2>&1)
    SITE_LIST_EXIT_CODE=$?
    set -e

    # Try to find a site with matching name and extract its ID
    FOUND_SITE_ID=""
    if [ $SITE_LIST_EXIT_CODE -eq 0 ]; then
        # Look for a site with name matching NETLIFY_SITE_NAME
        # The output is JSON array, so we need to parse it carefully
        # Use jq if available, otherwise fall back to grep
        if command -v jq &> /dev/null; then
            FOUND_SITE_ID=$(echo "$SITE_LIST_OUTPUT" | jq -r ".[] | select(.name == \"${NETLIFY_SITE_NAME}\") | .id" | head -1)
        else
            # Fallback: use grep to find the site
            # Match pattern: {..., "name":"site-name", ..., "id":"uuid", ...}
            # We look for lines containing both name and extract id from the same object
            FOUND_SITE_ID=$(echo "$SITE_LIST_OUTPUT" | grep -o "{[^}]*\"name\":\"${NETLIFY_SITE_NAME}\"[^}]*}" | grep -o "\"id\":\"[^\"]*\"" | head -1 | cut -d'"' -f4)
        fi
    fi

    if [ -n "$FOUND_SITE_ID" ]; then
        log_success "Found Netlify site: ${NETLIFY_SITE_NAME} (ID: ${FOUND_SITE_ID})"

        # Add custom domain to Netlify site
        log_info "Adding custom domain: ${NETLIFY_CUSTOM_DOMAIN}"

        # Get current site info to check if domain is already set
        set +e
        SITE_INFO=$(netlify api getSite --data "{\"site_id\": \"${FOUND_SITE_ID}\"}" 2>&1)
        set -e

        # Check if this domain is already configured
        if echo "$SITE_INFO" | grep -q "\"custom_domain\":\"${NETLIFY_CUSTOM_DOMAIN}\""; then
            log_success "Custom domain already configured: ${NETLIFY_CUSTOM_DOMAIN}"
        elif echo "$SITE_INFO" | grep -q "\"domain_aliases\".*\"${NETLIFY_CUSTOM_DOMAIN}\""; then
            log_success "Custom domain already configured as alias: ${NETLIFY_CUSTOM_DOMAIN}"
        else
            # Add custom domain using Netlify API
            log_info "Adding custom domain: ${NETLIFY_CUSTOM_DOMAIN}"
            set +e
            DOMAIN_ADD_OUTPUT=$(curl -s -X PATCH \
                "https://api.netlify.com/api/v1/sites/${FOUND_SITE_ID}" \
                -H "Authorization: Bearer ${NETLIFY_ACCESS_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"custom_domain\": \"${NETLIFY_CUSTOM_DOMAIN}\"}" 2>&1)
            DOMAIN_ADD_EXIT_CODE=$?
            set -e

            if [ $DOMAIN_ADD_EXIT_CODE -eq 0 ]; then
                log_success "Custom domain added to Netlify"
            else
                log_warning "Could not add domain via API"
                echo ""
                log_error "Error output:"
                echo "$DOMAIN_ADD_OUTPUT"
                echo ""
                log_info "Add the domain manually in Netlify UI:"
                log_info "  https://app.netlify.com/sites/${NETLIFY_SITE_NAME}/settings/domain"
            fi
        fi

        # Configure DNS CNAME record if doctl is available
        if [ "$SKIP_DNS" = false ]; then
            log_info "Configuring CNAME record in Digital Ocean DNS..."

            # Check if CNAME already exists (with more flexible matching)
            EXISTING_CNAME=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type,Data --no-header | grep -E "^[0-9]+\s+${FRONTEND_SUBDOMAIN}\s+CNAME" || true)

            if [ -n "$EXISTING_CNAME" ]; then
                # Extract the current target
                CURRENT_TARGET=$(echo "$EXISTING_CNAME" | awk '{print $4}')
                EXPECTED_TARGET="${NETLIFY_SITE_NAME}.netlify.app"

                if [ "$CURRENT_TARGET" = "$EXPECTED_TARGET" ] || [ "$CURRENT_TARGET" = "${EXPECTED_TARGET}." ]; then
                    log_success "CNAME record already correctly configured: ${FRONTEND_SUBDOMAIN} -> ${CURRENT_TARGET}"
                else
                    log_warning "CNAME record exists but points to wrong target: ${CURRENT_TARGET}"
                    log_info "Updating to: ${EXPECTED_TARGET}"
                    RECORD_ID=$(echo "$EXISTING_CNAME" | awk '{print $1}')
                    doctl compute domain records update ${DO_DOMAIN} --record-id ${RECORD_ID} --record-data "${EXPECTED_TARGET}."
                    log_success "Updated CNAME record"
                fi
            else
                # Check if there's ANY record (not just CNAME) with this name
                CONFLICTING_RECORD=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type --no-header | grep -E "^[0-9]+\s+${FRONTEND_SUBDOMAIN}\s+" || true)

                if [ -n "$CONFLICTING_RECORD" ]; then
                    log_error "Conflicting DNS record exists for ${FRONTEND_SUBDOMAIN}:"
                    echo "$CONFLICTING_RECORD"
                    log_warning "CNAME records cannot coexist with other record types"
                    log_info "Please delete the conflicting record first, then re-run the script"
                    log_info "  doctl compute domain records delete ${DO_DOMAIN} <RECORD_ID>"
                else
                    # No conflicts, create the CNAME
                    set +e
                    CREATE_OUTPUT=$(doctl compute domain records create ${DO_DOMAIN} \
                        --record-type CNAME \
                        --record-name ${FRONTEND_SUBDOMAIN} \
                        --record-data "${NETLIFY_SITE_NAME}.netlify.app." \
                        --record-ttl ${DNS_TTL_INITIAL} 2>&1)
                    CREATE_EXIT_CODE=$?
                    set -e

                    if [ $CREATE_EXIT_CODE -eq 0 ]; then
                        log_success "Created CNAME record: ${FRONTEND_SUBDOMAIN} -> ${NETLIFY_SITE_NAME}.netlify.app (TTL: ${DNS_TTL_INITIAL}s)"
                        log_info "Note: Increase TTL to ${DNS_TTL_PRODUCTION}s once domain is working"
                    else
                        log_error "Failed to create CNAME record"
                        echo "$CREATE_OUTPUT"
                    fi
                fi
            fi

            log_info "DNS CNAME: ${NETLIFY_CUSTOM_DOMAIN} -> ${NETLIFY_SITE_NAME}.netlify.app"
        else
            log_warning "Digital Ocean CLI not available. Create CNAME manually:"
            log_info "  Host: ${FRONTEND_SUBDOMAIN}"
            log_info "  Points to: ${NETLIFY_SITE_NAME}.netlify.app"
            log_info "  TTL: ${DNS_TTL_INITIAL} (increase to ${DNS_TTL_PRODUCTION} once working)"
        fi

        # Provision SSL certificate
        log_info "Netlify will automatically provision SSL certificate for ${NETLIFY_CUSTOM_DOMAIN}"
        log_info "This may take a few minutes after DNS propagates"

        log_success "Netlify custom domain configuration complete"
        log_info "Frontend URL: https://${NETLIFY_CUSTOM_DOMAIN}"
        log_info "Netlify URL: https://${NETLIFY_SITE_NAME}.netlify.app"

        # Check if GitHub continuous deployment is configured
        echo ""
        log_info "Checking GitHub continuous deployment configuration..."
        set +e
        SITE_DETAILS=$(netlify api getSite --data "{\"site_id\": \"${FOUND_SITE_ID}\"}" 2>&1)
        set -e
        if echo "$SITE_DETAILS" | grep -q '"build_settings".*"repo_url"'; then
            log_success "GitHub continuous deployment is already configured"
        else
            log_warning "GitHub continuous deployment is NOT configured"
            log_info "This site is currently set to 'Manual Deploys'"
            echo ""
            log_info "You need to set up GitHub continuous deployment manually"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_info "MANUAL STEP REQUIRED:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            log_info "1. Open a NEW terminal window/tab (keep this script running)"
            log_info "2. Navigate to the frontend directory:"
            echo "   cd ${FRONTEND_DIR}"
            log_info "3. Run the Netlify init command:"
            echo "   netlify init --force --git-remote-name origin"
            log_info "4. Follow the prompts that appear:"
            echo "   - Authorize with GitHub through app.netlify.com"
            echo "   - Build command: npm run build"
            echo "   - Publish directory: dist"
            echo "   - Branch to deploy: main"
            log_info "5. Wait for the command to complete successfully"
            log_info "6. Return to THIS terminal and press Enter to continue"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            read -p "Press Enter once you've completed the Netlify init command..."
            echo ""
            log_success "Continuing with script..."
        fi

    else
        log_warning "Netlify site not found: ${NETLIFY_SITE_NAME}"
        if [ $SITE_LIST_EXIT_CODE -ne 0 ]; then
            log_info "Error listing sites:"
            echo "$SITE_LIST_OUTPUT"
            echo ""
        fi
        log_info "Would you like to create it automatically?"
        echo ""
        log_info "This will:"
        log_info "  1. Create a new Netlify site named '${NETLIFY_SITE_NAME}'"
        log_info "  2. Link it to your GitHub repository for auto-deploys"
        log_info "  3. Deploy the frontend code"
        log_info "  4. Configure custom domain and SSL"
        echo ""
        read -p "Create Netlify site automatically? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Creating Netlify site..."

            # Check if frontend directory exists
            if [ ! -d "${FRONTEND_DIR}" ]; then
                log_error "Frontend directory not found: ${FRONTEND_DIR}"
                log_error "Make sure you're running this from the full-stack-template project"
                log_error "Project root detected as: ${PROJECT_ROOT}"
                exit 1
            fi

            # Create site
            log_info "Creating site: ${NETLIFY_SITE_NAME}"
            cd "${FRONTEND_DIR}"

            # Create the site with the specified name
            # Capture both stdout and stderr
            # Use 'set +e' temporarily to prevent script exit on command failure
            set +e
            NETLIFY_OUTPUT=$(netlify sites:create --name "${NETLIFY_SITE_NAME}" 2>&1)
            CREATE_EXIT_CODE=$?
            set -e

            # Parse Site ID from output (format: "Site ID: <uuid>") or from state file
            if [ $CREATE_EXIT_CODE -eq 0 ]; then
                # Try to get Site ID from the output
                SITE_ID=$(echo "$NETLIFY_OUTPUT" | grep -i "Site ID:" | awk '{print $NF}')

                # If not found in output, check .netlify/state.json
                if [ -z "$SITE_ID" ] && [ -f ".netlify/state.json" ]; then
                    if command -v jq &> /dev/null; then
                        SITE_ID=$(jq -r '.siteId' .netlify/state.json 2>/dev/null)
                    else
                        SITE_ID=$(grep -o '"siteId":"[^"]*"' .netlify/state.json | cut -d'"' -f4)
                    fi
                fi
            else
                SITE_ID=""
            fi

            if [ -z "$SITE_ID" ]; then
                log_error "Failed to create Netlify site"
                echo ""
                log_error "Netlify CLI output:"
                echo "$NETLIFY_OUTPUT"
                echo ""
                log_info "Possible reasons:"
                log_info "  - Site name '${NETLIFY_SITE_NAME}' may already be taken"
                log_info "  - You may not have permission to create sites in this team"
                log_info "  - Network or authentication issue"
                log_info ""
                log_info "Try manually creating at: https://app.netlify.com/start"
                cd - > /dev/null
                exit 1
            fi

            log_success "Created Netlify site: ${NETLIFY_SITE_NAME}"
            log_info "Site ID: ${SITE_ID}"

            # Link local directory to site for initial deploy
            log_info "Linking local directory to Netlify site..."
            netlify link --id "${SITE_ID}" || {
                log_warning "Could not link site"
                log_info "You may need to link manually: netlify link --id ${SITE_ID}"
            }

            # Deploy the site
            log_info "Deploying frontend to Netlify..."
            log_info "This may take a few minutes..."

            if netlify deploy --prod --dir=dist --site="${SITE_ID}"; then
                log_success "Frontend deployed successfully!"
                log_info "Site URL: https://${NETLIFY_SITE_NAME}.netlify.app"
            else
                log_error "Deployment failed"
                log_info "You may need to build the frontend first:"
                log_info "  cd ${FRONTEND_DIR}"
                log_info "  npm run build"
                log_info "  netlify deploy --prod"
                cd - > /dev/null
                exit 1
            fi

            cd - > /dev/null

            # Set up GitHub continuous deployment
            log_info "Setting up GitHub continuous deployment..."
            log_warning "This will configure automatic deploys from your GitHub repository"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_info "MANUAL STEP REQUIRED:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            log_info "1. Open a NEW terminal window/tab (keep this script running)"
            log_info "2. Navigate to the frontend directory:"
            echo "   cd ${FRONTEND_DIR}"
            log_info "3. Run the Netlify init command:"
            echo "   netlify init --force --git-remote-name origin"
            log_info "4. Follow the prompts that appear:"
            echo "   - Authorize with GitHub through app.netlify.com"
            echo "   - Build command: npm run build"
            echo "   - Publish directory: dist"
            echo "   - Branch to deploy: main"
            log_info "5. Wait for the command to complete successfully"
            log_info "6. Return to THIS terminal and press Enter to continue"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            read -p "Press Enter once you've completed the Netlify init command..."
            echo ""
            log_success "GitHub continuous deployment should now be configured"
            log_info "Netlify will automatically deploy when you push to main branch"

            # Now configure custom domain
            log_info "Adding custom domain: ${NETLIFY_CUSTOM_DOMAIN}"

            # Add custom domain using Netlify API
            set +e
            DOMAIN_ADD_OUTPUT=$(curl -s -X PATCH \
                "https://api.netlify.com/api/v1/sites/${SITE_ID}" \
                -H "Authorization: Bearer ${NETLIFY_ACCESS_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{\"custom_domain\": \"${NETLIFY_CUSTOM_DOMAIN}\"}" 2>&1)
            DOMAIN_ADD_EXIT_CODE=$?
            set -e

            if [ $DOMAIN_ADD_EXIT_CODE -eq 0 ]; then
                log_success "Custom domain added to Netlify"
            else
                log_warning "Could not add domain via API"
                echo ""
                log_error "Error output:"
                echo "$DOMAIN_ADD_OUTPUT"
                echo ""
                log_info "Add the domain manually in Netlify UI:"
                log_info "  https://app.netlify.com/sites/${NETLIFY_SITE_NAME}/settings/domain"
            fi

            # Configure DNS CNAME record if doctl is available
            if [ "$SKIP_DNS" = false ]; then
                log_info "Configuring CNAME record in Digital Ocean DNS..."

                # Check if CNAME already exists
                EXISTING_CNAME=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type,Data --no-header | grep -E "^[0-9]+\s+${FRONTEND_SUBDOMAIN}\s+CNAME" || true)

                if [ -n "$EXISTING_CNAME" ]; then
                    log_success "CNAME record already exists for ${FRONTEND_SUBDOMAIN}"
                else
                    set +e
                    CREATE_OUTPUT=$(doctl compute domain records create ${DO_DOMAIN} \
                        --record-type CNAME \
                        --record-name ${FRONTEND_SUBDOMAIN} \
                        --record-data "${NETLIFY_SITE_NAME}.netlify.app." \
                        --record-ttl ${DNS_TTL_INITIAL} 2>&1)
                    CREATE_EXIT_CODE=$?
                    set -e

                    if [ $CREATE_EXIT_CODE -eq 0 ]; then
                        log_success "Created CNAME record: ${FRONTEND_SUBDOMAIN} -> ${NETLIFY_SITE_NAME}.netlify.app (TTL: ${DNS_TTL_INITIAL}s)"
                        log_info "Note: Increase TTL to ${DNS_TTL_PRODUCTION}s once domain is working"
                    else
                        log_error "Failed to create CNAME record"
                        echo "$CREATE_OUTPUT"
                    fi
                fi
            fi

            log_success "Netlify site creation and configuration complete!"
            log_info "Frontend URL: https://${NETLIFY_CUSTOM_DOMAIN}"
            log_info "Netlify URL: https://${NETLIFY_SITE_NAME}.netlify.app"
        else
            log_warning "Skipping Netlify site creation"
            log_info "Create manually at: https://app.netlify.com/start"
            log_info "Then re-run this script to configure custom domain"
        fi
    fi
fi

# ============================================================================
# STEP 6: SETUP PROJECT ON DROPLET
# ============================================================================

log_section "Step 6: Setup Project on Droplet"

# Check if we need to set up GitHub SSH access
if [ "${DROPLET_NEEDS_GITHUB_SSH}" = true ]; then
    log_warning "Droplet needs SSH access to GitHub to clone the repository"
    echo ""
    log_info "Setting up GitHub SSH key on droplet..."
    echo ""
    log_info "This will:"
    log_info "  1. Generate an SSH key on the droplet"
    log_info "  2. Display the public key for you to add to GitHub"
    echo ""
    read -p "Continue with GitHub SSH setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Generate SSH key on droplet and get the public key
        DROPLET_GITHUB_SSH_KEY=$(ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} bash <<'EOF'
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "droplet-github-access" -f ~/.ssh/id_ed25519 -N ""
fi
cat ~/.ssh/id_ed25519.pub
EOF
)
        echo ""
        log_info "Public key generated on droplet:"
        echo ""
        echo "${DROPLET_GITHUB_SSH_KEY}"
        echo ""
        log_info "Add this SSH key to your GitHub account:"
        log_info "  1. Go to: https://github.com/settings/ssh/new"
        log_info "  2. Title: ${DROPLET_HOST}"
        log_info "  3. Paste the public key above"
        log_info "  4. Click 'Add SSH key'"
        echo ""
        read -p "Press Enter once you've added the key to GitHub..."
        echo ""

        # Test GitHub SSH access
        if ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} "ssh -T git@github.com 2>&1 | grep -q 'successfully authenticated'"; then
            log_success "Droplet can now access GitHub via SSH"
        else
            log_error "GitHub SSH access test failed"
            log_info "Please verify the key was added correctly and try again"
            exit 1
        fi
    else
        log_error "GitHub SSH access is required to clone the repository"
        exit 1
    fi
fi

log_info "Connecting to droplet and setting up project..."

# Generate random database password
DB_PASSWORD=$(openssl rand -base64 32)

# Generate SECRET_KEY (we'll do this on the droplet)
log_info "Setting up project directory and configuration..."

ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} bash <<EOF
set -e

# Create projects directory if it doesn't exist
mkdir -p ~/projects

# Check if project already exists (expand tilde on remote)
if [ -d ~/projects/${PROJECT_NAME} ]; then
    echo "Project directory already exists. Pulling latest changes..."
    cd ~/projects/${PROJECT_NAME}
    git pull origin main
else
    echo "Cloning repository..."
    cd ~/projects
    git clone git@github.com:${GITHUB_REPO}.git ${PROJECT_NAME}
fi

cd ~/projects/${PROJECT_NAME}/backend

# Generate SECRET_KEY
echo "Generating SECRET_KEY..."
SECRET_KEY=\$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Create .env file
echo "Creating .env file..."
cat > .env <<ENVFILE
# Database Configuration
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}

# JWT Authentication
SECRET_KEY=\${SECRET_KEY}
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Production Deployment (Traefik)
API_DOMAIN=${API_DOMAIN}
CORS_ORIGINS=${CORS_ORIGINS}
ENVFILE

echo "✓ Environment file created"

# Set proper permissions
chmod 600 .env

echo "✓ Project setup complete on droplet"
EOF

log_success "Project setup complete on droplet"

# ============================================================================
# STEP 7: AUTHENTICATE WITH GITHUB CONTAINER REGISTRY
# ============================================================================

log_section "Step 7: Authenticate Droplet with GitHub Container Registry"

log_info "Setting up GitHub Container Registry authentication..."
log_warning "This requires a GitHub Personal Access Token with 'read:packages' scope"
log_info "Create one at: https://github.com/settings/tokens"
echo ""

read -p "Enter your GitHub Personal Access Token (or press Enter to skip): " GITHUB_PAT

if [ -n "$GITHUB_PAT" ]; then
    ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} bash <<EOF
echo "${GITHUB_PAT}" | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin
EOF
    log_success "Authenticated with GitHub Container Registry"
else
    log_warning "Skipped GHCR authentication"
    log_info "You'll need to manually authenticate later or make your package public"
fi

# ============================================================================
# STEP 8: TRIGGER GITHUB ACTIONS TO BUILD AND PUSH DOCKER IMAGES
# ============================================================================

log_section "Step 8: Build and Push Docker Images"

log_info "Triggering GitHub Actions workflow to build Docker images..."
log_info "This will build the backend Docker image and push it to GitHub Container Registry"
echo ""

# Trigger the workflow
if gh workflow run build-push-images.yml --repo "${GITHUB_REPO}"; then
    log_success "Workflow triggered successfully"
    echo ""
    log_info "Waiting for workflow to start..."
    sleep 5

    # Get the latest workflow run
    log_info "Monitoring workflow progress..."
    log_info "View detailed logs at: https://github.com/${GITHUB_REPO}/actions"
    echo ""

    # Wait for the workflow to complete (with timeout)
    log_info "Waiting for build to complete (this may take 5-10 minutes)..."
    WAIT_COUNT=0
    MAX_WAIT=60  # 10 minutes (60 * 10 seconds)

    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        # Get the status of the most recent workflow run
        WORKFLOW_STATUS=$(gh run list --repo "${GITHUB_REPO}" --workflow=build-push-images.yml --limit=1 --json status --jq '.[0].status')

        if [ "$WORKFLOW_STATUS" = "completed" ]; then
            # Check if it succeeded
            WORKFLOW_CONCLUSION=$(gh run list --repo "${GITHUB_REPO}" --workflow=build-push-images.yml --limit=1 --json conclusion --jq '.[0].conclusion')
            if [ "$WORKFLOW_CONCLUSION" = "success" ]; then
                log_success "Docker image built and pushed successfully!"
                break
            else
                log_error "Workflow failed with status: ${WORKFLOW_CONCLUSION}"
                log_info "Check logs at: https://github.com/${GITHUB_REPO}/actions"
                exit 1
            fi
        fi

        echo -n "."
        sleep 10
        WAIT_COUNT=$((WAIT_COUNT + 1))
    done

    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo ""
        log_warning "Workflow is still running after 10 minutes"
        log_info "You can monitor it at: https://github.com/${GITHUB_REPO}/actions"
        log_info "Continue with deployment once the build completes"
        echo ""
        read -p "Press Enter to continue anyway, or Ctrl+C to exit..."
    fi
else
    log_error "Failed to trigger workflow"
    log_info "You can manually trigger it at: https://github.com/${GITHUB_REPO}/actions"
    exit 1
fi

echo ""

log_info "The GitHub Actions workflow will now deploy the application to your droplet"
log_info "This includes pulling the Docker image and starting the services"

# Test the API after giving it time to deploy
log_info "Waiting for deployment to complete and API to become available..."
log_info "This may take a few minutes for containers to start and SSL certificates to provision..."
sleep 30

# Try to reach the API with retries
MAX_RETRIES=10
RETRY_COUNT=0
API_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f https://${API_DOMAIN}/health > /dev/null 2>&1; then
        log_success "API is responding at https://${API_DOMAIN}/health"
        API_READY=true
        break
    fi
    echo -n "."
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo ""
if [ "$API_READY" = false ]; then
    log_warning "API is not yet responding"
    log_info "This is normal - SSL certificate provisioning can take a few minutes"
    log_info "Check status with: curl https://${API_DOMAIN}/health"
fi

# ============================================================================
# SUMMARY
# ============================================================================

log_section "Setup Complete! 🎉"

echo ""
echo "Summary of what was configured:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_success "1. SSH key generated and added to droplet"
log_info "   Private key: ${SSH_KEY_PATH}"
log_info "   Public key: ${SSH_KEY_PATH}.pub"
echo ""
log_success "2. GitHub secrets configured"
log_info "   Repository: ${GITHUB_REPO}"
log_info "   Secrets: DROPLET_HOST, DROPLET_USER, DROPLET_SSH_KEY"
echo ""
if [ "$SKIP_DNS" = false ]; then
    log_success "3. DNS records configured"
    log_info "   Backend: https://${API_DOMAIN}"
else
    log_warning "3. DNS records NOT configured - do this manually"
fi
echo ""
if [ "$SKIP_NETLIFY" = false ]; then
    log_success "4. Netlify custom domain configured"
    log_info "   Frontend: https://${NETLIFY_CUSTOM_DOMAIN}"
    log_info "   Netlify URL: https://${NETLIFY_SITE_NAME}.netlify.app"
    log_info "   SSL will be provisioned automatically"
else
    log_warning "4. Netlify NOT configured - do this manually"
    log_info "   Go to: https://app.netlify.com/sites/${NETLIFY_SITE_NAME}/settings/domain"
fi
echo ""
log_success "5. Project initialized on droplet"
log_info "   Location: ${PROJECT_DIR_ON_DROPLET}"
log_info "   Environment file: ${PROJECT_DIR_ON_DROPLET}/backend/.env"
echo ""
log_success "6. Docker image built and deployed via GitHub Actions"
echo ""
log_success "7. Ready for automated deployments!"
echo ""
echo "Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Verify your application is running:"
echo "   Backend:  https://${API_DOMAIN}/health"
echo "   Frontend: https://${NETLIFY_CUSTOM_DOMAIN}"
echo ""
echo "2. Once domains are working, increase DNS TTL for better performance:"
echo "   ./scripts/increase-dns-ttl.sh"
echo ""
echo "3. Future deployments are automatic!"
echo "   - Make changes to your code"
echo "   - Commit and push to main branch:"
echo "     git add ."
echo "     git commit -m 'Your changes'"
echo "     git push origin main"
echo "   - GitHub Actions will automatically build and deploy"
echo ""
echo "4. Monitor your deployments:"
echo "   GitHub Actions: https://github.com/${GITHUB_REPO}/actions"
echo "   Droplet logs:   ssh ${DROPLET_USER}@${DROPLET_HOST}"
echo "                   cd ${PROJECT_DIR_ON_DROPLET}/backend"
echo "                   docker compose -f docker-compose.prod.yml logs -f"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
