# Docker Credential Storage Security

This document explains how to securely store Docker credentials on your production server to avoid the warning:

```
WARNING! Your credentials are stored unencrypted in '/***/.docker/config.json'.
Configure a credential helper to remove this warning.
```

## Problem

By default, Docker stores authentication credentials in plain text in `~/.docker/config.json`. This is a security risk, especially on production servers where credentials for private registries (like GitHub Container Registry) are stored.

## Solution

Use a Docker credential helper to store credentials securely in your operating system's credential store:

- **Linux**: Uses `pass` (the standard Unix password manager) with GPG encryption
- **macOS**: Uses the system Keychain (usually configured automatically with Docker Desktop)

## Setup on Production Server (Linux)

### Automated Setup

Run the provided setup script:

```bash
cd backend
PROD_SERVER=1 ./scripts/setup-docker-credentials.sh
```

This script will:

1. Install `pass` and `gpg` if not already installed
2. Generate a GPG key for encrypting credentials
3. Initialize the password store
4. Download and install `docker-credential-pass`
5. Configure Docker to use the credential helper

### Manual Setup

If you prefer to set this up manually:

1. **Install dependencies:**

   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y pass gpg

   # CentOS/RHEL
   sudo yum install -y pass gpg
   ```

2. **Generate a GPG key:**

   ```bash
   gpg --generate-key
   # Follow the prompts
   ```

3. **Initialize pass:**

   ```bash
   pass init <your-gpg-key-id>
   ```

4. **Install docker-credential-pass:**

   ```bash
   VERSION="v0.8.2"
   sudo curl -fsSL \
     "https://github.com/docker/docker-credential-helpers/releases/download/${VERSION}/docker-credential-pass-${VERSION}.linux-amd64" \
     -o /usr/local/bin/docker-credential-pass
   sudo chmod +x /usr/local/bin/docker-credential-pass
   ```

5. **Configure Docker:**

   ```bash
   mkdir -p ~/.docker
   cat > ~/.docker/config.json <<EOF
   {
       "credsStore": "pass"
   }
   EOF
   ```

6. **Re-login to registries:**
   ```bash
   docker logout ghcr.io
   echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
   ```

## Verification

After setup, verify that credentials are stored securely:

1. **Check Docker config:**

   ```bash
   cat ~/.docker/config.json
   ```

   Should show:

   ```json
   {
       "credsStore": "pass"
   }
   ```

   ✓ Good: No plain text credentials in `auths` section

2. **Test credential helper:**

   ```bash
   docker-credential-pass list
   ```

   Should list your registries without errors.

3. **Check stored credentials:**
   ```bash
   pass
   ```
   Should show encrypted credential entries.

## Deployment Integration

The `deploy.sh` script now automatically checks your Docker credential configuration and warns if credentials are stored insecurely. Simply run the setup script once on your production server and the warning will disappear.

## Troubleshooting

### "gpg: decryption failed: No secret key"

This usually happens if the GPG key is not available. Ensure:

```bash
gpg --list-keys  # Should show your GPG key
pass  # Should work without errors
```

### "Cannot initialize credentials store"

Try re-initializing the password store:

```bash
pass init $(gpg --list-keys --keyid-format LONG | grep uid -B 1 | head -1 | awk '{print $2}' | cut -d'/' -f2)
```

### Docker login fails after setup

Re-login to your registries:

```bash
docker logout ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
```

## Security Benefits

- ✓ Credentials encrypted at rest using GPG
- ✓ Credentials protected by your GPG passphrase
- ✓ Compatible with all Docker commands
- ✓ Works with Docker Compose
- ✓ No changes needed to deployment workflows

## References

- [Docker Credential Helpers Documentation](https://docs.docker.com/engine/reference/commandline/login/#credential-helpers)
- [docker-credential-helpers GitHub](https://github.com/docker/docker-credential-helpers)
- [pass - the standard unix password manager](https://www.passwordstore.org/)
