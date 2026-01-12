#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo "Fllstck Tmplt Backend Deployment"
echo "=========================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found!"
    echo "Please create a .env file based on .env.example"
    exit 1
fi

echo "✓ Environment file found"
echo ""

# Check Docker credential storage configuration
if [ -f ~/.docker/config.json ]; then
    if grep -q '"auths".*":"' ~/.docker/config.json 2>/dev/null; then
        echo "⚠ WARNING: Docker credentials are stored unencrypted!"
        echo "  Run: PROD_SERVER=1 ./scripts/setup-docker-credentials.sh"
        echo "  This will configure secure credential storage."
        echo ""
    elif ! grep -q 'credsStore' ~/.docker/config.json 2>/dev/null; then
        echo "⚠ WARNING: No credential helper configured."
        echo "  Run: PROD_SERVER=1 ./scripts/setup-docker-credentials.sh"
        echo ""
    else
        echo "✓ Docker credential helper configured"
        echo ""
    fi
fi

# Pull latest code
echo "Pulling latest code from GitHub..."
git pull origin main
echo "✓ Code updated"
echo ""

# Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
if [ -z "$GITHUB_TOKEN" ]; then
    echo "WARNING: GITHUB_TOKEN not set. You may need to authenticate manually."
    echo "Run: echo YOUR_GITHUB_PAT | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
else
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
    echo "✓ Logged in to GHCR"
fi
echo ""

# Pull latest Docker image
echo "Pulling latest Docker image..."
docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml pull
echo "✓ Image pulled"
echo ""

# Stop and remove old containers
echo "Stopping old containers..."
docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml down --remove-orphans
echo "✓ Containers stopped"
echo ""

# Start services
echo "Starting services..."
docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml up -d
echo "✓ Services started"
echo ""

# Wait for backend to be healthy
echo "Waiting for backend to be ready..."
sleep 5

# Run database migrations
echo "Running database migrations..."
docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml exec -T backend uv run alembic upgrade head
echo "✓ Migrations completed"
echo ""

# Clean up old images
echo "Cleaning up old Docker images..."
docker image prune -f
echo "✓ Cleanup completed"
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend is running at: https://fllstck-tmplt-backend.michaelbylstra.com"
echo ""
echo "To view logs:"
echo "  docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml logs -f"
echo ""
echo "To check status:"
echo "  docker compose -p fllstck-tmplt-prod -f docker-compose.prod.yml ps"
echo ""
