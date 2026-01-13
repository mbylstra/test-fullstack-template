# Netlify Custom Domain & SSL Setup

This document explains how the automated deployment script handles Netlify domain configuration and SSL certificate provisioning.

## Overview

The script automates setting up a custom domain on Netlify with automatic SSL:

- **Custom Domain**: `test-fullstack-template-frontend.michaelbylstra.com`
- **Netlify Site**: `mb-mb-test-fullstack-template.netlify.app` (note the `mb-` prefix)
- **SSL**: Automatically provisioned by Netlify (Let's Encrypt)
- **DNS**: Managed via Digital Ocean
- **Initial TTL**: 60 seconds (for quick testing)
- **Production TTL**: 3600 seconds (increased after testing)

## Naming Convention

### Netlify Site Names

The script follows the `mb-` prefix convention to avoid naming conflicts:

- **Pattern**: `mb-{project-name}`
- **Example**: `mb-test-fullstack-template` becomes `mb-mb-test-fullstack-template.netlify.app`
- **Why**: Prevents conflicts with other projects that might have similar names

This matches your existing setup (e.g., `mb-tododoo.netlify.app` for the todo app).

## DNS TTL Strategy

The script uses a **two-phase TTL approach**:

### Phase 1: Initial Testing (60 seconds)

- **Low TTL**: 60 seconds (1 minute)
- **Purpose**: Quick iteration and testing
- **Benefits**:
  - See DNS changes faster
  - Easy to fix mistakes
  - Quick troubleshooting

### Phase 2: Production (3600 seconds)

- **Higher TTL**: 3600 seconds (1 hour)
- **Purpose**: Better performance
- **Benefits**:
  - Fewer DNS queries
  - Lower costs
  - Standard production practice

**Workflow:**
1. Script creates records with 60s TTL
2. Test domains work correctly
3. Run `./scripts/increase-dns-ttl.sh` to bump to 3600s

## How It Works

### 1. DNS Configuration (CNAME Record)

The script creates a CNAME record in Digital Ocean DNS:

```
test-fullstack-template-frontend.michaelbylstra.com → mb-mb-test-fullstack-template.netlify.app
```

**Why CNAME instead of A record?**
- Netlify uses a CDN with multiple IP addresses that can change
- CNAME automatically follows Netlify's infrastructure changes
- Recommended by Netlify for custom domains

### 2. Netlify Custom Domain Setup

The script uses Netlify CLI to:

1. Add the custom domain to your Netlify site
2. Verify DNS configuration
3. Trigger SSL certificate provisioning

### 3. Automatic SSL Provisioning

Once DNS is configured, Netlify automatically:

1. Detects the CNAME record pointing to their servers
2. Requests a Let's Encrypt SSL certificate
3. Provisions the certificate (typically 1-5 minutes)
4. Enables HTTPS with automatic renewal

## Prerequisites

### 1. Netlify Site - Manual or Automatic Creation

You have two options for creating your Netlify site:

#### Option A: Automatic Creation (Recommended)

The script can create the Netlify site for you automatically! When it detects the site doesn't exist, it will:

1. Prompt if you want to create it
2. Create a new site with name `mb-test-fullstack-template`
3. Link it to your GitHub repository for auto-deploys
4. Deploy your frontend code
5. Configure custom domain and SSL

**Prerequisites:**
- Frontend must be built first: `cd web-frontend && npm run build`
- Netlify CLI authenticated: `netlify login`
- You'll be prompted during the script execution

**What happens:**
```bash
# The script will run these commands for you:
netlify sites:create --name mb-test-fullstack-template
netlify link --id <site_id>
netlify deploy --prod --dir=dist
netlify api createSiteDomain --data '{"site_id": "...", "domain": "..."}'
```

#### Option B: Manual Creation

If you prefer to set up manually first:

```bash
# In your frontend directory
cd web-frontend

# Build first
npm run build

# Deploy to Netlify
netlify deploy --prod

# Or via Git integration (recommended for ongoing deploys)
# Connect your GitHub repo to Netlify at: https://app.netlify.com
```

### 2. Netlify CLI Installed

```bash
# Install globally
npm install -g netlify-cli

# Authenticate
netlify login
```

### 3. Site Name Configuration

The script needs to know your Netlify site name. Update in the script:

```bash
# In setup-automated-deployment.sh
NETLIFY_SITE_NAME="mb-test-fullstack-template"  # Your site name from *.netlify.app (with mb- prefix)
```

**How to find your site name:**

1. Go to https://app.netlify.com
2. Click on your site
3. Look at the URL or the site name under "Site overview"
4. Example: If your site is `mb-test-fullstack-template.netlify.app`, the site name is `mb-test-fullstack-template`

**Note**: Use the `mb-` prefix to avoid naming conflicts, matching the existing convention (e.g., `mb-tododoo`).

## What the Script Does

### Step 5: Configure Netlify Custom Domain

The script performs these actions:

```bash
# 1. Verify site exists
netlify api getSite --data '{"site_id": "test-fullstack-template"}'

# 2. Add custom domain to Netlify
netlify api createSiteDomain --data '{
  "site_id": "test-fullstack-template",
  "domain": "test-fullstack-template-frontend.michaelbylstra.com"
}'

# 3. Create CNAME record in Digital Ocean DNS
doctl compute domain records create michaelbylstra.com \
  --record-type CNAME \
  --record-name test-fullstack-template-frontend \
  --record-data mb-test-fullstack-template.netlify.app. \
  --record-ttl 3600

# 4. Netlify automatically provisions SSL (no manual step needed)
```

## Verification

After the script runs, verify the setup:

### 1. Check DNS Propagation

```bash
# Should return: mb-test-fullstack-template.netlify.app
dig +short test-fullstack-template-frontend.michaelbylstra.com CNAME

# Or use online tool
# https://dnschecker.org
```

### 2. Check Netlify Domain Status

Visit your Netlify dashboard:
- Go to: https://app.netlify.com/sites/test-fullstack-template/settings/domain
- You should see `test-fullstack-template-frontend.michaelbylstra.com` listed
- SSL status should show "HTTPS enabled" (may take a few minutes)

### 3. Test the Site

```bash
# Should redirect to HTTPS and show your site
curl -I https://test-fullstack-template-frontend.michaelbylstra.com

# Should see:
# HTTP/2 200
# server: Netlify
```

## Manual Setup (If Script Fails)

If the automated setup doesn't work, you can configure manually:

### Option 1: Via Netlify Dashboard (Easiest)

1. Go to https://app.netlify.com/sites/test-fullstack-template
2. Navigate to **Domain management** → **Domains**
3. Click **Add custom domain**
4. Enter: `test-fullstack-template-frontend.michaelbylstra.com`
5. Netlify shows DNS instructions:
   - **Type**: CNAME
   - **Name**: `test-fullstack-template-frontend`
   - **Value**: `mb-test-fullstack-template.netlify.app`
6. Add CNAME to Digital Ocean DNS
7. Wait for SSL provisioning (automatic)

### Option 2: Via CLI

```bash
# Add domain to Netlify
netlify domains:add test-fullstack-template-frontend.michaelbylstra.com --site test-fullstack-template

# Add CNAME in Digital Ocean
doctl compute domain records create michaelbylstra.com \
  --record-type CNAME \
  --record-name test-fullstack-template-frontend \
  --record-data mb-test-fullstack-template.netlify.app. \
  --record-ttl 3600
```

## SSL Certificate Details

### Automatic Provisioning

Netlify handles all SSL certificate management:

- **Provider**: Let's Encrypt
- **Type**: Domain Validated (DV)
- **Validity**: 90 days (auto-renewed)
- **Provisioning Time**: 1-5 minutes (typically)
- **Renewal**: Automatic (no action required)

### How It Works

1. You add custom domain to Netlify
2. You create CNAME pointing to Netlify
3. Netlify detects the DNS record
4. Netlify requests certificate from Let's Encrypt
5. Let's Encrypt validates domain ownership via DNS
6. Certificate is issued and installed
7. HTTPS is enabled automatically
8. Certificate auto-renews before expiration

### Why No Manual Certificate?

You don't need to:
- ❌ Generate CSR (Certificate Signing Request)
- ❌ Upload certificates
- ❌ Configure SSL settings
- ❌ Renew certificates manually

Netlify handles everything automatically.

## Troubleshooting

### SSL Certificate Not Provisioning

**Symptom**: Domain added but SSL shows "Waiting" or "Failed"

**Solutions**:

1. **Check DNS is correct:**
   ```bash
   dig test-fullstack-template-frontend.michaelbylstra.com CNAME
   # Should return: mb-test-fullstack-template.netlify.app
   ```

2. **Wait for DNS propagation:**
   - Can take up to 24 hours (usually 5-30 minutes)
   - Check at: https://dnschecker.org

3. **Verify domain not claimed:**
   - Domain can only be on one Netlify site
   - Check if it's on another site: https://app.netlify.com

4. **Force certificate renewal:**
   ```bash
   netlify api provisionSiteTLSCertificate --data '{"site_id": "test-fullstack-template"}'
   ```

5. **Contact Netlify Support:**
   - https://www.netlify.com/support/
   - They can manually provision if there's an issue

### Domain Shows "Waiting for DNS"

**Symptom**: Netlify says "Waiting for DNS propagation"

**Solutions**:

1. **Verify CNAME exists:**
   ```bash
   doctl compute domain records list michaelbylstra.com | grep test-fullstack-template-frontend
   ```

2. **Check CNAME target has trailing dot:**
   - Incorrect: `mb-test-fullstack-template.netlify.app`
   - Correct: `mb-test-fullstack-template.netlify.app.`
   - The trailing dot matters for some DNS providers

3. **Wait longer:**
   - DNS propagation isn't instant
   - Check again in 15-30 minutes

### Mixed Content Warnings

**Symptom**: Site loads but has mixed content warnings

**Cause**: Your site is loading HTTP resources on an HTTPS page

**Solutions**:

1. **Use protocol-relative URLs:**
   ```javascript
   // Instead of: http://example.com/script.js
   // Use: //example.com/script.js
   ```

2. **Force HTTPS in your code:**
   ```javascript
   const apiUrl = 'https://test-fullstack-template-backend.michaelbylstra.com';
   ```

3. **Check environment variables:**
   - Ensure your frontend is using `https://` for API calls
   - Update `.env` files if needed

## Benefits of This Approach

### ✅ Fully Automated
- No manual certificate generation
- No SSL configuration needed
- Works out of the box

### ✅ Always Up to Date
- Certificates auto-renew
- No expiration warnings
- No manual intervention

### ✅ CDN Included
- Netlify CDN handles all traffic
- Faster load times globally
- DDoS protection included

### ✅ DNS Flexibility
- Keep DNS at Digital Ocean
- No need to migrate nameservers
- Manage all records in one place

### ✅ Zero Downtime
- SSL updates happen transparently
- No service interruptions
- Automatic failover

## Alternative: Netlify DNS

If you want, you can use Netlify's DNS instead:

### Pros:
- All-in-one management
- Slightly faster SSL provisioning
- No need for Digital Ocean DNS

### Cons:
- Must migrate ALL DNS records
- Less control over DNS settings
- Harder to switch providers later

### How to Switch:

1. Go to: https://app.netlify.com/sites/test-fullstack-template/settings/domain
2. Click "Set up Netlify DNS"
3. Netlify provides nameservers
4. Update nameservers at your domain registrar
5. Import existing DNS records

**Not recommended** if you have other services on the same domain (like your backend).

## Summary

The automated script:
1. ✅ Creates CNAME record in Digital Ocean DNS
2. ✅ Adds custom domain to Netlify
3. ✅ Netlify automatically provisions SSL certificate
4. ✅ Your site is accessible via HTTPS at your custom domain

**Zero manual certificate management required!**
