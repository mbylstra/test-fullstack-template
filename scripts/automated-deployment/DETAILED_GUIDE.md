# Deployment Automation Scripts

## setup-automated-deployment.sh

This script automates the entire deployment setup process for your full-stack application.

**Can be run from any directory** - The script automatically detects the project root using `${BASH_SOURCE[0]}` and finds all necessary directories (frontend, backend) relative to that.

### What It Does

1. **Generates SSH Keys**: Creates a dedicated SSH key pair for GitHub Actions deployments
2. **Configures Droplet Access**: Adds the SSH public key to your existing droplet
3. **Sets GitHub Secrets**: Automatically configures repository secrets using GitHub CLI
4. **Configures DNS**: Creates DNS A records for your backend using Digital Ocean CLI
5. **Configures Netlify**: Sets up custom domain on Netlify with automatic SSL provisioning
6. **Initializes Project**: Sets up the project directory on the droplet with proper configuration
7. **Authenticates with GHCR**: Configures Docker to pull images from GitHub Container Registry
8. **Optional Initial Deploy**: Can trigger the first deployment manually

### Prerequisites

Before running this script, ensure you have:

- [ ] **Docker** installed
- [ ] **GitHub CLI (`gh`)** installed and authenticated
- [ ] **Digital Ocean CLI (`doctl`)** installed and authenticated (optional, for DNS automation)
- [ ] **Netlify CLI** installed and authenticated (optional, for frontend domain automation)
- [ ] **SSH access** to your droplet
- [ ] **GitHub Personal Access Token** with `read:packages` scope (for GHCR authentication)

### Installation

#### Install Digital Ocean CLI (Optional)

**macOS:**
```bash
brew install doctl
```

**Linux:**
```bash
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.98.1/doctl-1.98.1-linux-amd64.tar.gz
tar xf ~/doctl-1.98.1-linux-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin
```

**Authenticate:**
```bash
doctl auth init
# Enter your Digital Ocean API token when prompted
# Get token from: https://cloud.digitalocean.com/account/api/tokens
```

#### Install Netlify CLI (Optional)

**Using npm:**
```bash
npm install -g netlify-cli
```

**Using yarn:**
```bash
yarn global add netlify-cli
```

**Authenticate:**
```bash
netlify login
# Opens browser for authentication
# You'll be redirected to grant access to Netlify CLI

# Verify authentication
netlify status
```

### How Netlify Domain & SSL Works

The script sets up your custom domain on Netlify using Digital Ocean DNS:

1. **Adds custom domain to Netlify**: Configures `test-fullstack-template-frontend.michaelbylstra.com` on your Netlify site
2. **Creates CNAME record**: Points your subdomain to `test-fullstack-template.netlify.app` in Digital Ocean DNS
3. **Automatic SSL**: Netlify automatically provisions a Let's Encrypt SSL certificate (takes 1-5 minutes)
4. **No manual work**: Everything is configured automatically via APIs

**DNS Flow:**
```
test-fullstack-template-frontend.michaelbylstra.com (your domain)
  → CNAME → test-fullstack-template.netlify.app (Netlify's domain)
  → Netlify CDN → Your site with SSL
```

**Netlify Site Creation:**

The script can automatically create your Netlify site if it doesn't exist! You have two options:

**Option A: Automatic (Recommended)**
- Script detects site doesn't exist
- Prompts to create it automatically
- Creates site, links to GitHub, deploys frontend
- No manual Netlify dashboard work needed

**Option B: Manual**
- Create site manually at https://app.netlify.com/start
- Deploy your frontend once
- Then run the script to configure custom domain

**Requirements:**
- Netlify CLI authenticated (`netlify login`)
- Frontend built (`npm run build` in web-frontend directory)
- Digital Ocean DNS management (optional, but recommended)

### Configuration

Edit the constants at the top of `setup-automated-deployment.sh` to match your setup:

```bash
# Droplet Configuration
DROPLET_HOST="flipper2.michaelbylstra.com"  # Your droplet hostname
DROPLET_USER="root"                          # SSH user
DROPLET_SSH_PORT="22"                        # SSH port

# GitHub Configuration
GITHUB_REPO="mbylstra/test-fullstack-template"        # Your repository
GITHUB_USERNAME="mbylstra"                   # Your GitHub username

# Digital Ocean DNS Configuration
DO_DOMAIN="michaelbylstra.com"              # Your domain
BACKEND_SUBDOMAIN="test-fullstack-template-backend"   # Backend subdomain
FRONTEND_SUBDOMAIN="test-fullstack-template-frontend" # Frontend subdomain

# Netlify Configuration
NETLIFY_SITE_NAME="mb-test-fullstack-template"        # Your Netlify site name with mb- prefix (from *.netlify.app)
NETLIFY_CUSTOM_DOMAIN="${FRONTEND_SUBDOMAIN}.${DO_DOMAIN}"  # Custom domain

# DNS TTL Configuration
DNS_TTL_INITIAL=60                           # Low TTL for initial testing (60 seconds)
DNS_TTL_PRODUCTION=3600                      # Higher TTL for production (1 hour)

# Project Configuration
PROJECT_NAME="test-fullstack-template"                # Project name
```

### Usage

Run the script from any directory:

```bash
# From project root
./scripts/automated-deployment/setup-automated-deployment.sh

# From scripts directory
cd scripts/automated-deployment
./setup-automated-deployment.sh

# From anywhere (using absolute path)
/path/to/project/scripts/automated-deployment/setup-automated-deployment.sh
```

The script will:
1. Run pre-flight checks to verify required tools are installed
2. Guide you through each step with colored output
3. Ask for confirmation before destructive operations
4. Provide helpful error messages if something goes wrong

### What the Script Does NOT Do

- ❌ Does NOT create a new Digital Ocean droplet (uses your existing one)
- ❌ Does NOT install Docker or other software on the droplet (assumes already installed)
- ❌ Does NOT modify your Traefik configuration
- ❌ Does NOT run if you don't confirm destructive operations

### DNS TTL Strategy

The script uses a **low TTL initially** for quick testing and iteration:

- **Initial TTL**: 60 seconds (1 minute)
  - Allows quick DNS changes if something is wrong
  - Lets you see new domains working faster
  - Good for troubleshooting

- **Production TTL**: 3600 seconds (1 hour)
  - Better performance (fewer DNS queries)
  - Lower costs (DNS queries cost money at scale)
  - Standard production practice

**Workflow:**

1. Script creates DNS records with **60 second TTL**
2. Test your domains work correctly
3. Run `./scripts/increase-dns-ttl.sh` to increase to **1 hour TTL**

### Netlify Site Naming Convention

The script uses the `mb-` prefix for Netlify site names:

- **Pattern**: `mb-{project-name}.netlify.app`
- **Example**: `mb-test-fullstack-template.netlify.app`
- **Purpose**: Avoid naming conflicts with other projects

This matches your existing setup (e.g., `mb-tododoo.netlify.app`).

### After Running the Script

Once the script completes successfully:

1. **Test Your Domains**: Verify both are working
   ```bash
   # Backend health check
   curl https://test-fullstack-template-backend.michaelbylstra.com/health

   # Frontend (open in browser)
   open https://test-fullstack-template-frontend.michaelbylstra.com
   ```

2. **Increase DNS TTL**: Once domains are working, improve performance
   ```bash
   ./scripts/increase-dns-ttl.sh
   ```

3. **Test Your Setup**: Push a commit to the `main` branch
   ```bash
   git add .
   git commit -m "Test automated deployment"
   git push origin main
   ```

4. **Monitor Deployment**: Watch GitHub Actions
   - Go to: https://github.com/mbylstra/test-fullstack-template/actions
   - Watch the build-and-push and deploy jobs

5. **View Logs**: SSH into your droplet
   ```bash
   ssh root@flipper2.michaelbylstra.com
   cd ~/projects/test-fullstack-template/backend
   docker compose -f docker-compose.prod.yml logs -f
   ```

### Troubleshooting

#### "GitHub CLI is not authenticated"
```bash
gh auth login
# Follow the prompts to authenticate
```

#### "Digital Ocean CLI is not authenticated"
```bash
doctl auth init
# Enter your Digital Ocean API token
# Get token from: https://cloud.digitalocean.com/account/api/tokens
```

#### "Netlify CLI is not authenticated"
```bash
netlify login
# Opens browser for authentication

# Verify authentication
netlify status
```

#### "Could not find Netlify site"
Make sure:
1. Your site exists on Netlify
2. The site name matches (check at https://app.netlify.com)
3. You have access to the site (check team permissions)

```bash
# List your Netlify sites
netlify sites:list

# Link to a site if needed
netlify link
```

#### "Netlify SSL certificate not provisioning"
SSL certificates usually provision in 1-5 minutes. If it takes longer:

1. **Verify DNS is correct:**
   ```bash
   dig test-fullstack-template-frontend.michaelbylstra.com
   # Should show CNAME pointing to *.netlify.app
   ```

2. **Check Netlify domain status:**
   - Go to: https://app.netlify.com/sites/test-fullstack-template/settings/domain
   - Look for any error messages or warnings

3. **Common issues:**
   - DNS not propagated yet (wait up to 24 hours, usually much faster)
   - CNAME pointing to wrong target
   - Domain already claimed by another Netlify site

4. **Force certificate renewal:**
   ```bash
   netlify api provisionSiteTLSCertificate --data '{"site_id": "test-fullstack-template"}'
   ```

#### "Cannot connect to droplet via SSH"
Make sure you have SSH access:
```bash
ssh root@flipper2.michaelbylstra.com
```

If you can't connect, check:
- Firewall rules allow SSH (port 22)
- Your IP address is not blocked
- SSH service is running on the droplet

#### "Failed to copy SSH key to droplet"
Manually copy the public key:
```bash
# On your local machine, copy the public key
cat ~/.ssh/github_actions_deploy_test-fullstack-template.pub

# SSH into the droplet
ssh root@flipper2.michaelbylstra.com

# Add the key
echo 'PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Manual Steps if Netlify Automation is Skipped

If you don't have Netlify CLI or it fails, you can set up the custom domain manually:

#### Option 1: Via Netlify Dashboard (Recommended)

1. Go to your Netlify site: https://app.netlify.com/sites/test-fullstack-template
2. Navigate to **Domain management** → **Domains**
3. Click **Add custom domain**
4. Enter: `test-fullstack-template-frontend.michaelbylstra.com`
5. Netlify will show you DNS instructions
6. Add the CNAME record to Digital Ocean DNS (see below)

#### Option 2: Manual DNS Configuration

1. **Add CNAME in Digital Ocean:**
   - Go to: https://cloud.digitalocean.com/networking/domains
   - Select domain: `michaelbylstra.com`
   - Add CNAME record:
     - **Hostname**: `test-fullstack-template-frontend`
     - **Is an alias of**: `test-fullstack-template.netlify.app.` (note the trailing dot)
     - **TTL**: 3600 seconds

2. **Configure in Netlify:**
   - Go to: https://app.netlify.com/sites/test-fullstack-template/settings/domain
   - Click **Add custom domain**
   - Enter: `test-fullstack-template-frontend.michaelbylstra.com`
   - Netlify will verify DNS and provision SSL automatically

3. **Wait for SSL:**
   - SSL certificate provisioning takes 1-5 minutes
   - Check status at: https://app.netlify.com/sites/test-fullstack-template/settings/domain

### Manual Steps if DNS Automation is Skipped

If you don't have `doctl` installed, you'll need to manually create DNS records:

1. Go to Digital Ocean control panel: https://cloud.digitalocean.com/networking/domains
2. Select your domain: `michaelbylstra.com`
3. Add an A record:
   - **Hostname**: `test-fullstack-template-backend`
   - **Will Direct To**: Get IP of `flipper2.michaelbylstra.com` (run `dig +short flipper2.michaelbylstra.com`)
   - **TTL**: 3600 seconds

### Security Notes

- The generated SSH key is dedicated to GitHub Actions deployments only
- Private key is stored locally and as a GitHub secret
- Public key is added to the droplet's authorized_keys
- Database password is randomly generated (32 characters)
- JWT secret key is randomly generated on the droplet
- `.env` file has restricted permissions (600)

### Customization

You can customize the script by editing the configuration constants at the top of the file. All deployment settings are centralized there for easy modification.
