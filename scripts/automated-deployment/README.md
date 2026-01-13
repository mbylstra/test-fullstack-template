# Automated Deployment Setup

This directory contains scripts to fully automate your deployment infrastructure setup.

**What gets automated:**

- SSH keys → GitHub secrets → Droplet
- DNS configuration (backend + frontend)
- Netlify site creation + custom domain + SSL
- Docker registry authentication
- Project initialization on droplet

**Time:** ~10 minutes (vs ~70 minutes manual setup)

---

## Quick Start

```bash
# 1. Complete one-time setup (see below)

# 2. Build your frontend
cd web-frontend && npm run build && cd ..

# 3. Run the automation script (from any directory)
./scripts/automated-deployment/setup-automated-deployment.sh

# 4. Test domains, then increase TTL (from any directory)
./scripts/automated-deployment/increase-dns-ttl.sh
```

**Note:** Both scripts can be run from any directory - they automatically detect the project root.

---

## Required One-Time Setup

Complete these steps once, then you can use the automation for all your projects.

### Step 1: Install CLI Tools

#### GitHub CLI (Required)

**macOS:**

```bash
brew install gh
```

**Linux:**

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

#### Digital Ocean CLI (Highly Recommended)

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

#### Netlify CLI (Highly Recommended)

```bash
npm install -g netlify-cli
```

### Step 2: Authenticate CLI Tools

#### GitHub CLI

```bash
gh auth login
```

Follow the prompts:

1. Select "GitHub.com"
2. Select "HTTPS" or "SSH"
3. Authenticate via web browser
4. Complete authentication

Verify:

```bash
gh auth status
```

#### Digital Ocean CLI

```bash
doctl auth init
```

You'll need to provide your Digital Ocean API token:

1. Go to https://cloud.digitalocean.com/account/api/tokens
2. Click "Generate New Token"
3. Name it "CLI Access"
4. Select "Read" and "Write" scopes
5. Copy the token and paste it when prompted

Verify:

```bash
doctl account get
```

#### Netlify CLI

```bash
netlify login
```

This will:

1. Open your browser
2. Prompt you to authorize Netlify CLI
3. Redirect back when complete

Verify:

```bash
netlify status
```

### Step 3: Create GitHub Personal Access Token

You'll need this during script execution for Docker registry access.

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name it "GHCR Access"
4. Select scope: **`read:packages`**
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

Keep this token handy - the script will prompt for it.

### Step 4: Verify SSH Access to Droplet

Make sure you can SSH into your droplet:

```bash
ssh root@flipper2.michaelbylstra.com
```

If you can't connect:

- Check firewall rules allow SSH (port 22)
- Verify your IP isn't blocked
- Ensure SSH service is running

---

## Per-Project Configuration

Before running the automation, configure it for your project.

### Edit Configuration

Open `setup-automated-deployment.sh` and update these constants:

```bash
# Project Configuration
PROJECT_NAME="test-fullstack-template"                # Change this for your project

# GitHub Configuration
GITHUB_REPO="mbylstra/test-fullstack-template"        # Your repository
GITHUB_USERNAME="mbylstra"                   # Your GitHub username

# Droplet Configuration
DROPLET_HOST="flipper2.michaelbylstra.com"  # Your droplet (usually stays the same)

# Digital Ocean DNS Configuration
DO_DOMAIN="michaelbylstra.com"              # Your domain (usually stays the same)
BACKEND_SUBDOMAIN="test-fullstack-template-backend"   # Change this for your project
FRONTEND_SUBDOMAIN="test-fullstack-template-frontend" # Change this for your project

# Netlify Configuration
NETLIFY_SITE_NAME="mb-test-fullstack-template"        # Change this (use mb- prefix)
```

**Naming Convention:**

- **Backend subdomain**: `{project-name}-backend`
- **Frontend subdomain**: `{project-name}-frontend`
- **Netlify site**: `mb-{project-name}`

### Build Frontend

The script can deploy to Netlify, but you need to build first:

```bash
cd web-frontend
npm run build
cd ..
```

This creates the `dist/` directory that gets deployed.

---

## Running the Automation

### Main Setup Script

The script can be run from any directory:

```bash
# From project root
./scripts/automated-deployment/setup-automated-deployment.sh

# From scripts directory
cd scripts/automated-deployment
./setup-automated-deployment.sh

# From anywhere (using absolute path)
/path/to/project/scripts/automated-deployment/setup-automated-deployment.sh
```

The script automatically detects the project root and finds all necessary directories.

**What it does:**

1. **Generates SSH key** for GitHub Actions deployments
2. **Adds SSH key** to droplet's authorized_keys
3. **Configures GitHub secrets** (DROPLET_HOST, DROPLET_USER, DROPLET_SSH_KEY)
4. **Creates DNS records**:
   - Backend: A record → droplet IP (TTL: 60s)
   - Frontend: CNAME → Netlify (TTL: 60s)
5. **Sets up Netlify**:
   - Creates site if doesn't exist
   - Links to GitHub for auto-deploys
   - Deploys frontend
   - Configures custom domain
   - SSL provisioned automatically
6. **Initializes project on droplet**:
   - Clones repository
   - Generates secure secrets (DB password, JWT key)
   - Creates .env file
7. **Authenticates with GitHub Container Registry** (you'll paste your PAT)
8. **Optional initial deployment** (can test backend immediately)

**Interactive prompts:**

- SSH key overwrite (if exists)
- Update DNS records (if exist)
- Create Netlify site (if doesn't exist)
- Manual deployment (optional)
- GitHub PAT (for GHCR access)

**Duration:** ~2-5 minutes (mostly waiting for API calls)

### After Setup: Increase DNS TTL

Once you've verified both domains work:

```bash
./scripts/automated-deployment/increase-dns-ttl.sh
```

This increases TTL from 60s → 3600s (1 hour) for better performance.

---

## Verifying the Setup

### Test Backend

```bash
curl https://{project-name}-backend.michaelbylstra.com/health
```

Expected response:

```json
{ "status": "ok" }
```

### Test Frontend

```bash
open https://{project-name}-frontend.michaelbylstra.com
```

Should show your deployed frontend with valid HTTPS.

### Check GitHub Actions

Push a commit to trigger automated deployment:

```bash
git add .
git commit -m "Test automated deployment"
git push origin main
```

Watch at: `https://github.com/{username}/{repo}/actions`

### Monitor Droplet

SSH into droplet and check logs:

```bash
ssh root@flipper2.michaelbylstra.com
cd ~/projects/{project-name}/backend
docker compose -f docker-compose.prod.yml logs -f
```

---

## Manual Steps Summary

Here's everything you need to do manually (can't be automated):

### One-Time (All Projects)

- [ ] Install GitHub CLI (`gh`)
- [ ] Install Digital Ocean CLI (`doctl`)
- [ ] Install Netlify CLI (`netlify-cli`)
- [ ] Authenticate `gh` with GitHub
- [ ] Authenticate `doctl` with Digital Ocean API token
- [ ] Authenticate `netlify` with Netlify account
- [ ] Create GitHub Personal Access Token with `read:packages` scope
- [ ] Verify SSH access to droplet

**Estimated time:** 15-20 minutes

### Per-Project

- [ ] Edit configuration in `setup-automated-deployment.sh`
- [ ] Build frontend: `cd web-frontend && npm run build`
- [ ] Run `./scripts/automated-deployment/setup-automated-deployment.sh`
- [ ] Paste GitHub PAT when prompted
- [ ] Test domains work correctly
- [ ] Run `./scripts/automated-deployment/increase-dns-ttl.sh`

**Estimated time:** 5-10 minutes per project

---

## Troubleshooting

### "GitHub CLI is not authenticated"

```bash
gh auth login
# Follow prompts to authenticate
gh auth status  # Verify
```

### "Digital Ocean CLI is not authenticated"

```bash
doctl auth init
# Paste your DO API token
doctl account get  # Verify
```

### "Netlify CLI is not authenticated"

```bash
netlify login
# Opens browser for authentication
netlify status  # Verify
```

### "Cannot connect to droplet via SSH"

Check you can connect:

```bash
ssh root@flipper2.michaelbylstra.com
```

If not:

- Verify firewall allows SSH (port 22)
- Check your IP isn't blocked
- Ensure SSH service is running

### "Failed to copy SSH key to droplet"

Manually add the public key:

```bash
# On your machine, copy the public key
cat ~/.ssh/github_actions_deploy_{project-name}.pub

# SSH into droplet
ssh root@flipper2.michaelbylstra.com

# Add the key
echo 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### "Could not find Netlify site"

The script will offer to create it automatically. If you prefer manual:

```bash
cd web-frontend
netlify deploy --prod
```

Or create at: https://app.netlify.com/start

### "SSL certificate not provisioning"

Wait 5-10 minutes for DNS to propagate, then check:

```bash
dig {project-name}-frontend.michaelbylstra.com
# Should show CNAME to Netlify
```

Visit Netlify dashboard to see SSL status:

- https://app.netlify.com/sites/mb-{project-name}/settings/domain

Force renewal if needed:

```bash
netlify api provisionSiteTLSCertificate --data '{"site_id": "mb-{project-name}"}'
```

---

## What Gets Automated vs Manual

### ✅ Fully Automated

- SSH key generation and distribution
- GitHub secrets configuration
- DNS record creation (A and CNAME)
- Netlify site creation
- Netlify custom domain setup
- SSL certificate provisioning
- Droplet project initialization
- Environment file generation with secure secrets
- Docker registry authentication
- Initial deployment (optional)

### ⚠️ Manual (One-Time)

- CLI tools installation
- CLI tools authentication
- Creating GitHub PAT
- Creating Digital Ocean API token
- Verifying droplet SSH access

### ⚠️ Manual (Per-Project)

- Editing configuration
- Building frontend
- Running the script
- Pasting GitHub PAT
- Testing domains
- Increasing TTL after verification

---

## Files in This Directory

- **`README.md`** (this file) - Manual steps and quick start
- **`setup-automated-deployment.sh`** - Main automation script
- **`increase-dns-ttl.sh`** - Increase DNS TTL after testing
- **`DETAILED_GUIDE.md`** - Comprehensive documentation
- **`NETLIFY_SETUP.md`** - Deep dive on Netlify configuration
- **`AUTOMATION_SUMMARY.md`** - Overview of what's automated

---

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Read `DETAILED_GUIDE.md` for more details
3. Check `NETLIFY_SETUP.md` for Netlify-specific issues
4. Verify all CLI tools are authenticated
5. Check the script's error messages (usually helpful)

---

## Next Steps After Setup

Once automation is complete:

1. **Push to main** to test automated deployment
2. **Monitor GitHub Actions** for build/deploy success
3. **Check backend logs** on droplet
4. **Verify frontend** loads correctly
5. **Test API calls** from frontend to backend

Your full production deployment is now automated! 🎉
