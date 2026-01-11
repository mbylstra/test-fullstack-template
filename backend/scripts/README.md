# Database Migration Scripts

## replace-prod-db-with-local.sh

**⚠️ DESTRUCTIVE OPERATION ⚠️**

This script migrates your local database to production by:

1. Dumping the local PostgreSQL database
2. Backing up the current production database (safety first!)
3. Copying the local dump to the production server
4. Restoring the dump to production
5. Running migrations to ensure schema compatibility

### Prerequisites

1. **Docker installed locally**
    - The script uses Docker to run `pg_dump` from the database container
    - No need to install PostgreSQL client tools separately

2. **SSH access to production server**
    - SSH key authentication configured
    - Ability to connect without password prompt

3. **Local database running**

    ```bash
    make db-up
    ```

4. **Production server configured**
   Set the `PROD_SERVER` environment variable to your server's SSH address.

### Configuration

Set these environment variables before running the script:

```bash
# Required: SSH address of production server
export PROD_SERVER="root@<droplet-ip>"

# Optional: Custom production directory (default: ~/fllstck-tmplt/backend)
export PROD_DIR="~/fllstck-tmplt/backend"
```

You can also add these to a `.env.local` file in the backend directory.

### Usage

#### Method 1: Using Make (Recommended)

```bash
# Set production server
export PROD_SERVER="root@157.230.xx.xx"

# Run migration
make replace-prod-db-with-local
```

#### Method 2: Direct Script Execution

```bash
# Set production server
export PROD_SERVER="root@157.230.xx.xx"

# Run script
./scripts/replace-prod-db-with-local.sh
```

### Safety Features

- **Double confirmation required**: You must type "yes" and the database name
- **Automatic production backup**: Creates timestamped backup before any changes
- **Rollback instructions**: Provides exact commands to restore from backup
- **Pre-flight checks**: Verifies all prerequisites before starting
- **Error handling**: Exits immediately on any error

### What the Script Does

1. **Checks Prerequisites**
    - Verifies local database is running
    - Checks PostgreSQL client tools are installed
    - Tests SSH connection to production server

2. **Dumps Local Database**
    - Creates clean dump with `--clean` and `--if-exists` flags
    - Excludes ownership and privilege information
    - Stores in `backend/db-dumps/` directory

3. **Backs Up Production Database**
    - Creates timestamped backup on production server
    - Stored at: `~/fllstck-tmplt/backend/prod_backup_<timestamp>.sql`

4. **Copies Dump to Server**
    - Uses `scp` to securely transfer dump file

5. **Restores to Production**
    - Drops existing data and recreates from dump
    - Runs Alembic migrations to ensure schema is current
    - Cleans up temporary dump file on server

6. **Verifies Production**
    - Tests the `/health` endpoint
    - Confirms API is responding

### Rollback

If something goes wrong, you can restore from the backup:

```bash
ssh root@<droplet-ip>
cd ~/fllstck-tmplt/backend

# Restore from backup
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U ${DB_USER} -d ${DB_NAME} < prod_backup_<timestamp>.sql

# Run migrations
docker compose -f docker-compose.prod.yml exec backend \
  uv run alembic upgrade head
```

The script will print the exact rollback command at the end.

### Example Output

```
===================================================
Database Migration to Production
===================================================

⚠️  WARNING: This REPLACES all production data with local data!

Configuration:
  Local DB:  fllstck-tmplt-user@localhost:5432/fllstck-tmplt
  Server:    root@157.230.xx.xx
  Directory: ~/fllstck-tmplt/backend

Are you sure you want to continue? (type 'yes' to proceed): yes
Type the database name 'fllstck-tmplt' to confirm: fllstck-tmplt

===================================================
Checking Prerequisites
===================================================

✓ Local database container is running
✓ PostgreSQL client tools are installed
✓ SSH connection to production server verified
✓ Temporary directory ready: /path/to/backend/db-dumps

===================================================
Dumping Local Database
===================================================

⚠ Dumping database: fllstck-tmplt
✓ Local database dumped: local_dump_20241122_143022.sql (2.3M)

===================================================
Backing Up Production Database
===================================================

⚠ Creating production database backup on server...
✓ Production database backed up: prod_backup_20241122_143022.sql
⚠ Backup is stored on the server at: ~/fllstck-tmplt/backend/prod_backup_20241122_143022.sql

===================================================
Copying Dump to Production Server
===================================================

✓ Dump file copied to server

===================================================
Restoring to Production Database
===================================================

⚠ Dropping and recreating production database...
✓ Database restored and migrations applied

===================================================
Cleanup
===================================================

✓ Local dump file removed
✓ Cleanup complete

===================================================
Verifying Production
===================================================

Testing production API health endpoint...
✓ Production API is responding

===================================================
Migration Complete!
===================================================

✓ Local database successfully migrated to production
⚠ Production backup saved as: prod_backup_20241122_143022.sql
⚠ The backup is stored on the server at: ~/fllstck-tmplt/backend/prod_backup_20241122_143022.sql

To rollback, run on the server:
  cd ~/fllstck-tmplt/backend
  docker compose -f docker-compose.prod.yml exec -T postgres \
    psql -U ${DB_USER} -d ${DB_NAME} < prod_backup_20241122_143022.sql
```

### Troubleshooting

#### "Cannot connect to production server"

Ensure you can SSH to the server without a password:

```bash
ssh root@<droplet-ip>
```

If this prompts for a password, set up SSH key authentication:

```bash
ssh-copy-id root@<droplet-ip>
```

#### "Local database container is not running"

Start the local database:

```bash
make db-up
```

#### "Docker command not found"

Install Docker:

```bash
# macOS
brew install --cask docker

# Ubuntu/Debian
sudo apt-get install docker.io
```

#### "Could not verify production API health"

This is a warning, not an error. The migration may have succeeded even if the health check fails. Manually verify by visiting:

```
https://fllstck-tmplt--backend.michaelbylstra.com/health
```

### Best Practices

1. **Test first**: Try the script with a staging environment if available
2. **Off-peak hours**: Run during low traffic periods
3. **Verify data**: Check both source and destination data before migrating
4. **Keep backups**: Don't delete the backup files until you've confirmed the migration
5. **Communicate**: Notify users if there will be downtime

---

## reset-user-password.py

Reset a user's password in the database. Useful after database migrations when password hashes have changed, or when users forget their passwords.

### Usage

**Local:**

```bash
cd backend
uv run python scripts/reset-user-password.py user@example.com newpassword123
```

**Production (on server):**

```bash
ssh root@<droplet-ip>
cd /root/fllstck-tmplt/backend
docker compose -f docker-compose.prod.yml exec backend \
  uv run python scripts/reset-user-password.py user@example.com newpassword123
```

### How It Works

1. Hashes the new password using Argon2 (same as your app)
2. Updates the `password_hash` field in the database for the specified user
3. Confirms the update with user details

### After Database Migration

If you migrated your local database to production, all password hashes changed. To reset a production user's password:

```bash
# SSH to server
ssh root@<droplet-ip>
cd /root/fllstck-tmplt/backend

# Reset password for your account
docker compose -f docker-compose.prod.yml exec backend \
  uv run python scripts/reset-user-password.py admin@example.com NewSecurePassword123
```

**Example output:**

```
🔄 Resetting password for: admin@example.com

✅ Password successfully updated for user: admin@example.com
   User ID: 550e8400-e29b-41d4-a716-446655440000
```

---

### Alternatives

If you need more control, you can perform the migration manually:

```bash
# 1. Dump local database (using Docker)
docker exec fllstck-tmplt-postgres pg_dump -U fllstck-tmplt-user fllstck-tmplt \
  --clean --if-exists --no-owner --no-privileges > local_dump.sql

# 2. Backup production (on server)
ssh root@<droplet-ip>
cd ~/fllstck-tmplt/backend
docker compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U ${DB_USER} ${DB_NAME} > backup.sql

# 3. Copy dump to server
scp local_dump.sql root@<droplet-ip>:~/fllstck-tmplt/backend/

# 4. Restore on production (on server)
docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U ${DB_USER} -d ${DB_NAME} < local_dump.sql

# 5. Run migrations (on server)
docker compose -f docker-compose.prod.yml exec backend \
  uv run alembic upgrade head
```
