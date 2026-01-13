# Fullstack Template

## Follow these steps

### Initialize the project

#### Set up the repo

Create a new project on github

```
git clone git@github.com:mbylstra/fllstck-tmplt.git {{your-project-name}}
cd your-project-name
git remote remove origin
git remote add origin git@github.com:mbylstra/{{your-project-name}}.git
git push
```

#### Enable tracking of the template repo

This is so we can merge/rebase changes to the template in the future

`make track-template-repo`

#### Replace project names

`make customize-template`

#### Set up .envrc

copy .envrc.example to .envrc and fill in the values

#### Test Claude

start claude (shouldn't be any warnings)

#### Install packages

```
make install
```

### Initialize the mobile app

#### Quick test

Connect phone (iphone or android) with cable

```
cd mobile-app
make flutter-run
```

---

### Configure Production Deployment

#### Automated Deployment Setup

This template includes complete automation for production deployment infrastructure.

**Location:** `scripts/automated-deployment/`

**What gets automated:**

- SSH keys and GitHub secrets
- DNS configuration (backend + frontend)
- Netlify site creation + custom domain + SSL
- Docker registry authentication
- Project initialization on droplet

**Get started:**

```bash
cd scripts/automated-deployment
cat README.md  # Read the setup instructions
```

See [`scripts/automated-deployment/README.md`](scripts/automated-deployment/README.md) for detailed instructions.
