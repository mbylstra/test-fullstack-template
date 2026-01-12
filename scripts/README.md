# Scripts Directory

This directory contains automation scripts for deployment and development tasks.

## Directory Structure

```
scripts/
├── automated-deployment/          # Production deployment automation
│   ├── README.md                  # Manual steps & quick start
│   ├── setup-automated-deployment.sh   # Main automation script
│   ├── increase-dns-ttl.sh        # Increase DNS TTL after testing
│   ├── DETAILED_GUIDE.md          # Comprehensive documentation
│   ├── NETLIFY_SETUP.md           # Netlify domain & SSL guide
│   └── AUTOMATION_SUMMARY.md      # What gets automated
│
├── customize-template.sh          # Initialize this template for your project
├── track-template-repo.sh         # Track upstream template updates
├── merge-latest-template.sh       # Merge template updates
└── rebase-from-latest-template.sh # Rebase from template
```

## Automated Deployment

**Location:** `automated-deployment/`

Complete automation for setting up production deployment infrastructure including:
- SSH keys and GitHub secrets
- DNS configuration (Digital Ocean)
- Netlify site creation and custom domain setup
- SSL certificate provisioning
- Droplet project initialization
- Docker registry authentication

**Quick Start:**
```bash
cd automated-deployment
cat README.md  # Read the setup instructions
./setup-automated-deployment.sh
```

See [`automated-deployment/README.md`](automated-deployment/README.md) for detailed instructions.

---

## Other Scripts

Add other automation scripts here as your project grows:
- Database backup scripts
- Data migration scripts
- Development environment setup
- Testing utilities
- etc.
