#!/bin/bash
# setup-automated-deployment.sh
# Automates the deployment setup for the full-stack-template project
#
# Prerequisites:
# - GitHub CLI (gh) installed and authenticated
# - Digital Ocean CLI (doctl) installed and authenticated
# - SSH access to the droplet
# - Docker installed on the droplet (already done)

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

# Digital Ocean DNS Configuration
DO_DOMAIN="michaelbylstra.com"
BACKEND_SUBDOMAIN="fllstck-tmplt-backend"
FRONTEND_SUBDOMAIN="fllstck-tmplt-frontend"

# Project Configuration
PROJECT_NAME="fllstck-tmplt"
PROJECT_DIR_ON_DROPLET="~/projects/${PROJECT_NAME}"

# Database Configuration
DB_USER="${PROJECT_NAME}-user"
DB_NAME="${PROJECT_NAME}"
DB_HOST="postgres"
DB_PORT="5432"

# Backend Configuration
API_DOMAIN="${BACKEND_SUBDOMAIN}.${DO_DOMAIN}"
FRONTEND_DOMAIN="${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"
CORS_ORIGINS="https://${FRONTEND_DOMAIN},https://${PROJECT_NAME}.netlify.app"

# Netlify Configuration
NETLIFY_SITE_NAME="mb-${PROJECT_NAME}"  # Your Netlify site name with mb- prefix (e.g., mb-fllstck-tmplt.netlify.app)
NETLIFY_CUSTOM_DOMAIN="${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"  # Custom domain

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
    if ! netlify status &> /dev/null; then
        log_warning "Netlify CLI is not authenticated. Netlify setup will be skipped."
        log_warning "Run: netlify login"
        SKIP_NETLIFY=true
    else
        log_success "Netlify CLI is installed and authenticated"
        SKIP_NETLIFY=false
    fi
fi

# Check SSH access to droplet
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes ${DROPLET_USER}@${DROPLET_HOST} exit &> /dev/null; then
    log_warning "Cannot connect to droplet via SSH with current credentials"
    log_warning "You may need to enter a password during setup"
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

    # Try to get site info
    if netlify api getSite --data "{\"site_id\": \"${NETLIFY_SITE_NAME}\"}" &> /dev/null; then
        log_success "Found Netlify site: ${NETLIFY_SITE_NAME}"

        # Add custom domain to Netlify site
        log_info "Adding custom domain: ${NETLIFY_CUSTOM_DOMAIN}"

        # Check if domain already exists on site
        EXISTING_DOMAIN=$(netlify api listSiteDomains --data "{\"site_id\": \"${NETLIFY_SITE_NAME}\"}" 2>/dev/null | grep -o "\"${NETLIFY_CUSTOM_DOMAIN}\"" || true)

        if [ -n "$EXISTING_DOMAIN" ]; then
            log_warning "Custom domain already configured on Netlify"
        else
            netlify api createSiteDomain --data "{\"site_id\": \"${NETLIFY_SITE_NAME}\", \"domain\": \"${NETLIFY_CUSTOM_DOMAIN}\"}" &> /dev/null || {
                log_warning "Could not add domain via API. Try manual configuration:"
                log_info "  netlify domains:add ${NETLIFY_CUSTOM_DOMAIN} --site ${NETLIFY_SITE_NAME}"
            }
            log_success "Custom domain added to Netlify"
        fi

        # Configure DNS CNAME record if doctl is available
        if [ "$SKIP_DNS" = false ]; then
            log_info "Creating CNAME record in Digital Ocean DNS..."

            # Check if CNAME already exists
            EXISTING_CNAME=$(doctl compute domain records list ${DO_DOMAIN} --format Name,Type,Data --no-header | grep "^${FRONTEND_SUBDOMAIN} CNAME" || true)

            if [ -n "$EXISTING_CNAME" ]; then
                log_warning "CNAME record already exists for ${FRONTEND_SUBDOMAIN}"
                read -p "Do you want to update it? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    RECORD_ID=$(doctl compute domain records list ${DO_DOMAIN} --format ID,Name,Type --no-header | grep "${FRONTEND_SUBDOMAIN} CNAME" | awk '{print $1}')
                    doctl compute domain records update ${DO_DOMAIN} --record-id ${RECORD_ID} --record-data "${NETLIFY_SITE_NAME}.netlify.app."
                    log_success "Updated CNAME record"
                fi
            else
                doctl compute domain records create ${DO_DOMAIN} \
                    --record-type CNAME \
                    --record-name ${FRONTEND_SUBDOMAIN} \
                    --record-data "${NETLIFY_SITE_NAME}.netlify.app." \
                    --record-ttl ${DNS_TTL_INITIAL}
                log_success "Created CNAME record: ${FRONTEND_SUBDOMAIN} -> ${NETLIFY_SITE_NAME}.netlify.app (TTL: ${DNS_TTL_INITIAL}s)"
                log_info "Note: Increase TTL to ${DNS_TTL_PRODUCTION}s once domain is working"
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

    else
        log_warning "Netlify site not found: ${NETLIFY_SITE_NAME}"
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
            SITE_ID=$(netlify sites:create --name "${NETLIFY_SITE_NAME}" --json 2>/dev/null | grep -o '"site_id":"[^"]*"' | cut -d'"' -f4)

            if [ -z "$SITE_ID" ]; then
                log_error "Failed to create Netlify site"
                log_warning "The site name may already be taken"
                log_info "Try manually creating at: https://app.netlify.com/start"
                cd - > /dev/null
                exit 1
            fi

            log_success "Created Netlify site: ${NETLIFY_SITE_NAME}"
            log_info "Site ID: ${SITE_ID}"

            # Link to repository for auto-deploys
            log_info "Linking to GitHub repository for auto-deploys..."
            log_warning "You'll need to authorize Netlify to access your GitHub repository"
            log_info "This will open in your browser..."
            sleep 2

            netlify link --id "${SITE_ID}" || {
                log_warning "Could not link to GitHub automatically"
                log_info "You can link manually at: https://app.netlify.com/sites/${NETLIFY_SITE_NAME}/settings/deploys"
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

            # Now configure custom domain
            log_info "Adding custom domain: ${NETLIFY_CUSTOM_DOMAIN}"

            netlify api createSiteDomain --data "{\"site_id\": \"${NETLIFY_SITE_NAME}\", \"domain\": \"${NETLIFY_CUSTOM_DOMAIN}\"}" &> /dev/null || {
                log_warning "Could not add domain via API"
                log_info "Add manually: netlify domains:add ${NETLIFY_CUSTOM_DOMAIN} --site ${NETLIFY_SITE_NAME}"
            }
            log_success "Custom domain added to Netlify"

            # Configure DNS CNAME record if doctl is available
            if [ "$SKIP_DNS" = false ]; then
                log_info "Creating CNAME record in Digital Ocean DNS..."

                EXISTING_CNAME=$(doctl compute domain records list ${DO_DOMAIN} --format Name,Type,Data --no-header | grep "^${FRONTEND_SUBDOMAIN} CNAME" || true)

                if [ -n "$EXISTING_CNAME" ]; then
                    log_warning "CNAME record already exists for ${FRONTEND_SUBDOMAIN}"
                else
                    doctl compute domain records create ${DO_DOMAIN} \
                        --record-type CNAME \
                        --record-name ${FRONTEND_SUBDOMAIN} \
                        --record-data "${NETLIFY_SITE_NAME}.netlify.app." \
                        --record-ttl ${DNS_TTL_INITIAL}
                    log_success "Created CNAME record: ${FRONTEND_SUBDOMAIN} -> ${NETLIFY_SITE_NAME}.netlify.app (TTL: ${DNS_TTL_INITIAL}s)"
                    log_info "Note: Increase TTL to ${DNS_TTL_PRODUCTION}s once domain is working"
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

log_info "Connecting to droplet and setting up project..."

# Generate random database password
DB_PASSWORD=$(openssl rand -base64 32)

# Generate SECRET_KEY (we'll do this on the droplet)
log_info "Setting up project directory and configuration..."

ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} bash <<EOF
set -e

# Create projects directory if it doesn't exist
mkdir -p ~/projects

# Check if project already exists
if [ -d "${PROJECT_DIR_ON_DROPLET}" ]; then
    echo "Project directory already exists. Pulling latest changes..."
    cd ${PROJECT_DIR_ON_DROPLET}
    git pull origin main
else
    echo "Cloning repository..."
    cd ~/projects
    git clone https://github.com/${GITHUB_REPO}.git ${PROJECT_NAME}
fi

cd ${PROJECT_DIR_ON_DROPLET}/backend

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
# STEP 8: RUN INITIAL DEPLOYMENT
# ============================================================================

log_section "Step 8: Run Initial Deployment"

log_info "The next step is to trigger a deployment..."
log_warning "This will be done automatically when you push to the main branch"

read -p "Do you want to manually run the deployment script now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Running deployment script on droplet..."

    ssh -i "${SSH_KEY_PATH}" ${DROPLET_USER}@${DROPLET_HOST} bash <<'EOF'
cd ${PROJECT_DIR_ON_DROPLET}/backend
./deploy.sh
EOF

    log_success "Deployment complete"

    # Test the API
    log_info "Testing API endpoint..."
    sleep 5
    if curl -s -f https://${API_DOMAIN}/health > /dev/null; then
        log_success "API is responding at https://${API_DOMAIN}/health"
    else
        log_warning "API is not yet responding. It may take a few minutes for Traefik to provision SSL certificates."
    fi
else
    log_info "Skipped manual deployment"
    log_info "Push to main branch to trigger automated deployment"
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
log_success "6. Ready for automated deployments!"
echo ""
echo "Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Test your domains:"
echo "   Backend:  https://${API_DOMAIN}/health"
echo "   Frontend: https://${NETLIFY_CUSTOM_DOMAIN}"
echo ""
echo "2. Once domains are working, increase DNS TTL for better performance:"
echo "   ./scripts/increase-dns-ttl.sh"
echo ""
echo "3. Make changes to your code"
echo "4. Commit and push to main branch:"
echo "   git add ."
echo "   git commit -m 'Your changes'"
echo "   git push origin main"
echo ""
echo "5. Watch deployment in GitHub Actions:"
echo "   https://github.com/${GITHUB_REPO}/actions"
echo ""
echo "6. Monitor droplet logs:"
echo "   ssh ${DROPLET_USER}@${DROPLET_HOST}"
echo "   cd ${PROJECT_DIR_ON_DROPLET}/backend"
echo "   docker compose -f docker-compose.prod.yml logs -f"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
