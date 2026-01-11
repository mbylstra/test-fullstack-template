#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo "Docker Credential Helper Setup"
echo "=========================================="
echo ""

# Check if running on production server
if [ -z "$PROD_SERVER" ]; then
    echo "WARNING: This script is intended for production servers."
    echo "Set PROD_SERVER=1 environment variable to proceed."
    echo ""
    echo "Example: PROD_SERVER=1 ./scripts/setup-docker-credentials.sh"
    exit 1
fi

# Detect OS
OS=$(uname -s)
echo "Detected OS: $OS"
echo ""

# Install docker-credential-pass on Linux
if [ "$OS" = "Linux" ]; then
    echo "Setting up docker-credential-pass for Linux..."
    echo ""

    # Check if pass is installed
    if ! command -v pass &> /dev/null; then
        echo "Installing pass (password store)..."

        # Detect package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y pass gpg
        elif command -v yum &> /dev/null; then
            sudo yum install -y pass gpg
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y pass gpg
        else
            echo "ERROR: Unsupported package manager. Please install 'pass' and 'gpg' manually."
            exit 1
        fi

        echo "✓ pass installed"
    else
        echo "✓ pass already installed"
    fi
    echo ""

    # Check if GPG key exists
    if ! gpg --list-keys | grep -q "uid"; then
        echo "No GPG key found. Generating GPG key..."
        echo "Please follow the prompts to create a GPG key."
        echo ""

        # Generate GPG key non-interactively
        cat > /tmp/gpg-batch <<EOF
%echo Generating Docker credentials GPG key
Key-Type: RSA
Key-Length: 2048
Name-Real: Docker Credentials
Name-Email: docker@$(hostname)
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

        gpg --batch --generate-key /tmp/gpg-batch
        rm /tmp/gpg-batch

        echo "✓ GPG key generated"
    else
        echo "✓ GPG key already exists"
    fi
    echo ""

    # Initialize pass
    GPG_ID=$(gpg --list-keys --keyid-format LONG | grep "uid" -B 1 | grep "pub" | head -1 | awk '{print $2}' | cut -d'/' -f2)

    if [ -z "$GPG_ID" ]; then
        echo "ERROR: Could not find GPG key ID"
        exit 1
    fi

    echo "Initializing password store with GPG key: $GPG_ID"
    # Force initialization (will succeed even if already exists)
    pass init "$GPG_ID" 2>&1 | grep -v "does not exist and so cannot be removed" || true
    echo "✓ Password store initialized"
    echo ""

    # Download docker-credential-pass
    if ! command -v docker-credential-pass &> /dev/null; then
        echo "Installing docker-credential-pass..."

        CREDENTIAL_HELPER_VERSION="v0.8.2"
        CREDENTIAL_HELPER_URL="https://github.com/docker/docker-credential-helpers/releases/download/${CREDENTIAL_HELPER_VERSION}/docker-credential-pass-${CREDENTIAL_HELPER_VERSION}.linux-amd64"

        sudo curl -fsSL "$CREDENTIAL_HELPER_URL" -o /usr/local/bin/docker-credential-pass
        sudo chmod +x /usr/local/bin/docker-credential-pass

        echo "✓ docker-credential-pass installed"
    else
        echo "✓ docker-credential-pass already installed"
    fi
    echo ""

    # Configure Docker to use credential helper
    mkdir -p ~/.docker

    if [ -f ~/.docker/config.json ]; then
        # Backup existing config
        cp ~/.docker/config.json ~/.docker/config.json.backup
        echo "✓ Backed up existing Docker config"
    fi

    # Update or create config.json
    cat > ~/.docker/config.json <<EOF
{
    "credsStore": "pass"
}
EOF

    echo "✓ Docker configured to use pass credential store"
    echo ""

    # Verify setup
    echo "Verifying credential helper setup..."
    if docker-credential-pass list > /dev/null 2>&1; then
        echo "✓ Credential helper is working correctly"
    else
        echo "⚠ Credential helper test failed. You may need to re-login to Docker."
    fi

elif [ "$OS" = "Darwin" ]; then
    echo "macOS detected. Using osxkeychain credential helper..."
    echo ""

    # macOS should have osxkeychain by default with Docker Desktop
    mkdir -p ~/.docker

    if [ -f ~/.docker/config.json ]; then
        cp ~/.docker/config.json ~/.docker/config.json.backup
        echo "✓ Backed up existing Docker config"
    fi

    cat > ~/.docker/config.json <<EOF
{
    "credsStore": "osxkeychain"
}
EOF

    echo "✓ Docker configured to use osxkeychain"

else
    echo "ERROR: Unsupported operating system: $OS"
    exit 1
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Docker credentials will now be stored securely."
echo ""
echo "Next steps:"
echo "1. Re-login to Docker registries:"
echo "   docker logout ghcr.io"
echo "   echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GITHUB_USER --password-stdin"
echo ""
echo "2. Verify credentials are stored securely:"
echo "   cat ~/.docker/config.json"
echo "   (Should show 'credsStore' instead of plain 'auths')"
echo ""
