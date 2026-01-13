# Automated Deployment Setup

This guide explains how to set up automated deployment to your Digital Ocean droplet using GitHub Actions.

## Overview

When you push to the `main` branch:

1. GitHub Actions builds a Docker image
2. Image is pushed to GitHub Container Registry (GHCR)
3. Deployment job SSHs into your droplet
4. Droplet pulls the new image and restarts services
5. Database migrations run automatically

## One-Time Setup

### Step 1: Configure GitHub Secrets

You need to add three secrets to your GitHub repository:

#### 1.1 Generate SSH Key on Your Local Machine

```bash
# Generate a new SSH key specifically for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This creates two files:
# - ~/.ssh/github_actions_deploy (private key)
# - ~/.ssh/github_actions_deploy.pub (public key)
```

#### 1.2 Add Public Key to Droplet

```bash
# Copy the public key
cat ~/.ssh/github_actions_deploy.pub

# SSH into your droplet
ssh root@<your-droplet-ip>

# Add the public key to authorized_keys
echo "PUBLIC_KEY_CONTENT_HERE" >> ~/.ssh/authorized_keys

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys
```

#### 1.3 Add Secrets to GitHub Repository

Go to your GitHub repository:

- Navigate to **Settings** → **Secrets and variables** → **Actions**
- Click **New repository secret**

Add these three secrets:

| Secret Name       | Value                   | Description                               |
| ----------------- | ----------------------- | ----------------------------------------- |
| `DROPLET_HOST`    | Your droplet IP address | e.g., `134.209.123.45`                    |
| `DROPLET_USER`    | SSH user                | Usually `root`                            |
| `DROPLET_SSH_KEY` | Private key content     | Content of `~/.ssh/github_actions_deploy` |

**To get the private key content:**

```bash
cat ~/.ssh/github_actions_deploy
```

Copy the entire output including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`.

### Step 2: Initial Deployment to Droplet

Before automated deployments work, you need to set up the application on the droplet once.

#### 2.1 SSH into Droplet

```bash
ssh root@<your-droplet-ip>
```

#### 2.2 Clone Repository

```bash
cd ~
git clone https://github.com/mbylstra/test-fullstack-template.git
cd test-fullstack-template/backend
```

#### 2.3 Create Environment File

```bash
cp .env.example .env
nano .env
```

Update with production values:

```env
# Database Configuration
DB_USER=test-fullstack-template-user
DB_PASSWORD=<strong-password>
DB_NAME=test-fullstack-template
DB_HOST=postgres
DB_PORT=5432

# JWT Authentication
SECRET_KEY=<generate-with-command-below>
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Production Deployment (Traefik)
API_DOMAIN=test-fullstack-template-backend.michaelbylstra.com
CORS_ORIGINS=https://test-fullstack-template-frontend.michaelbylstra.com,https://test-fullstack-template.netlify.app
```

**Generate SECRET_KEY:**

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### 2.4 Authenticate with GitHub Container Registry

The droplet needs to authenticate with GHCR to pull images:

```bash
# Create a Personal Access Token (PAT) on GitHub:
# 1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. Generate new token with 'read:packages' scope
# 3. Copy the token

# Login to GHCR on the droplet
echo "YOUR_GITHUB_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

#### 2.5 Run Initial Deployment

```bash
cd ~/test-fullstack-template/backend
./deploy.sh
```

This will:

- Pull the Docker image from GHCR
- Start the database and backend services
- Run database migrations

#### 2.6 Verify Deployment

```bash
# Check containers are running
docker ps

# Check logs
docker compose -f docker-compose.prod.yml logs -f

# Test the API
curl https://test-fullstack-template-backend.michaelbylstra.com/health
```

Expected response:

```json
{ "status": "ok" }
```

## Using Automated Deployment

### Deploy Changes

Once setup is complete, deployment is automatic:

```bash
# Make changes to your code
git add .
git commit -m "Your changes"
git push origin main
```

GitHub Actions will automatically:

1. Build the Docker image
2. Push to GHCR
3. Deploy to your droplet
4. Run migrations

### Monitor Deployment

#### View GitHub Actions

- Go to your repository on GitHub
- Click the **Actions** tab
- Click on the latest workflow run
- Watch the **build-and-push** and **deploy** jobs

#### View Droplet Logs

```bash
# SSH into droplet
ssh root@<your-droplet-ip>

# View backend logs
cd ~/test-fullstack-template/backend
docker compose -f docker-compose.prod.yml logs -f backend

# View all logs
docker compose -f docker-compose.prod.yml logs -f
```

## Manual Deployment (if needed)

If you need to deploy manually without pushing to GitHub:

```bash
# SSH into droplet
ssh root@<your-droplet-ip>

# Navigate to backend directory
cd ~/test-fullstack-template/backend

# Run deployment script
./deploy.sh
```

## Troubleshooting

### Deployment Fails: "Permission denied (publickey)"

**Cause:** SSH key not properly configured

**Solution:**

1. Verify the public key is in `~/.ssh/authorized_keys` on the droplet
2. Check the private key is correctly added to `DROPLET_SSH_KEY` secret
3. Ensure the key format is correct (should be OpenSSH format)

### Deployment Fails: "docker login" Authentication Failed

**Cause:** GitHub token doesn't have package read permissions

**Solution:**
The deployment uses the automatic `GITHUB_TOKEN` which should have permissions. If it fails:

1. Go to repo Settings → Actions → General
2. Scroll to "Workflow permissions"
3. Select "Read and write permissions"
4. Save

### Migration Fails

**Cause:** Database schema conflicts

**Solution:**

```bash
# SSH into droplet
ssh root@<your-droplet-ip>
cd ~/test-fullstack-template/backend

# Check migration status
docker compose -f docker-compose.prod.yml exec backend uv run alembic current

# View migration history
docker compose -f docker-compose.prod.yml exec backend uv run alembic history

# Manually run migrations
docker compose -f docker-compose.prod.yml exec backend uv run alembic upgrade head
```

### Image Pull Fails: "manifest unknown"

**Cause:** Image not built or not pushed to GHCR

**Solution:**

1. Check GitHub Actions completed successfully
2. Verify image exists at: https://github.com/mbylstra/test-fullstack-template/pkgs/container/test-fullstack-template%2Fbackend
3. Ensure image is public or droplet has GHCR authentication

To make GHCR package public:

1. Go to the package page on GitHub
2. Click **Package settings**
3. Scroll to **Danger Zone**
4. Click **Change visibility** → **Public**

### Service Unhealthy After Deployment

**Cause:** Various issues (env vars, database connection, etc.)

**Solution:**

```bash
# Check container status
docker ps -a

# View detailed logs
docker compose -f docker-compose.prod.yml logs backend

# Check database connectivity
docker compose -f docker-compose.prod.yml exec backend ping postgres

# Restart services
docker compose -f docker-compose.prod.yml restart
```

## Deployment Workflow Details

### GitHub Actions Workflow

Located at `.github/workflows/build-push-images.yml`

**Jobs:**

1. **build-and-push**: Builds Docker image and pushes to GHCR
    - Triggers on push to `main` or when `backend/**` files change
    - Uses Docker Buildx for multi-platform builds
    - Caches layers for faster builds
    - Tags with `latest` and git SHA

2. **deploy**: Deploys to droplet (only on `main` branch)
    - Waits for build-and-push to complete
    - SSHs into droplet using stored secrets
    - Pulls latest image
    - Restarts services
    - Runs database migrations
    - Cleans up old images

### Docker Compose Configuration

**Production:** `docker-compose.prod.yml`

- Uses image from GHCR (not building locally)
- Connected to `traefik-network` for HTTPS
- Postgres on internal network only
- Always pulls latest image

## Security Best Practices

1. **SSH Key**: Use a dedicated key for deployments, not your personal key
2. **GitHub Secrets**: Never commit secrets to the repository
3. **Database Passwords**: Use strong, randomly generated passwords
4. **SECRET_KEY**: Generate with `secrets.token_urlsafe(32)`
5. **GHCR Access**: Consider making package private and using PAT for droplet access
6. **Firewall**: Only allow ports 22 (SSH), 80 (HTTP), and 443 (HTTPS)

## Rollback Strategy

If a deployment breaks production:

### Quick Rollback

```bash
# SSH into droplet
ssh root@<your-droplet-ip>
cd ~/test-fullstack-template/backend

# Pull a specific version (use git SHA from previous working deployment)
docker pull ghcr.io/mbylstra/test-fullstack-template/backend:sha-abc123

# Update docker-compose to use specific tag
nano docker-compose.prod.yml
# Change: ghcr.io/mbylstra/test-fullstack-template/backend:latest
# To: ghcr.io/mbylstra/test-fullstack-template/backend:sha-abc123

# Restart
docker compose -f docker-compose.prod.yml up -d

# If needed, rollback migrations
docker compose -f docker-compose.prod.yml exec backend uv run alembic downgrade -1
```

### Proper Rollback

```bash
# Revert the problematic commit locally
git revert <commit-sha>
git push origin main

# This will trigger a new deployment with the reverted code
```

## Next Steps

Consider adding:

- **Staging environment**: Deploy to staging before production
- **Health checks**: Add pre-deployment and post-deployment health checks
- **Slack notifications**: Get notified when deployments complete
- **Database backups**: Automated backups before migrations
- **Blue-green deployments**: Zero-downtime deployments
