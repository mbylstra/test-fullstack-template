# Docker Troubleshooting

## Docker Desktop Running But Can't Connect to Daemon

### Symptoms

- Docker Desktop shows "Docker Desktop is running" in the menu bar
- Running `docker ps` or `make dev-all` fails with: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`
- The Docker Desktop GUI appears to be running, but the Docker engine hasn't actually started

### Root Cause

Docker Desktop's GUI can be open while the Docker engine VM fails to start. This creates a state where the application appears running but the daemon is not accessible.

### Solution: Proper Quit and Restart

Use AppleScript to properly quit Docker Desktop, then restart it:

```bash
osascript -e 'quit app "Docker Desktop"' && sleep 5 && open -a "Docker Desktop"
```

This command:
1. Uses AppleScript to send a proper quit signal to Docker Desktop
2. Waits 5 seconds for the application to fully terminate
3. Restarts Docker Desktop
4. Wait 15-20 seconds for Docker engine to fully start

### Verify Docker is Working

After restarting, wait about 15-20 seconds, then verify Docker is working:

```bash
docker ps
```

If successful, you should see a list of containers (or an empty list with headers).

### Fix Docker Context Issues

Docker Desktop uses two contexts: `desktop-linux` and `default`. Sometimes the `desktop-linux` context socket doesn't work properly. To fix:

```bash
docker context use default
```

This permanently switches to the more reliable `default` context.

### Why This Works

- Regular `killall` may not properly terminate all Docker processes
- Using `osascript -e 'quit app "..."'` sends a proper macOS quit event
- This ensures all Docker Desktop components shut down cleanly
- The clean restart allows the Docker engine VM to start properly

### Alternative: Toggle Docker Socket Setting

If the above doesn't work, try this in Docker Desktop:

1. Open Docker Desktop → Settings (gear icon) → Advanced
2. Uncheck "Use default Docker socket (Requires password)"
3. Apply & Restart
4. After restart, check it again
5. Apply & Restart (enter password when prompted)

---

## Phantom Container Error

### Symptoms

- Running `make dev-all` or `docker compose up` fails with:
  ```
  Error response from daemon: No such container: <container-id>
  ```
- The error persists even after restarting Docker Desktop
- `docker ps -a` shows a container that can't be removed

### Root Cause

Docker Compose caches container IDs based on the project name (derived from the directory name). When containers are forcefully killed or Docker crashes, this cache can become corrupted, causing Docker Compose to try to start a non-existent container.

### Solution 1: Use Explicit Project Names

This is already fixed in the Makefile by using explicit project names:

```bash
docker compose -p test-fullstack-template -f docker-compose.dev.yml up -d --wait
```

The `-p test-fullstack-template` flag ensures consistent project naming and prevents cache corruption.

### Solution 2: Clean Up Corrupted State

If you encounter a phantom container error:

1. Restart Docker Desktop to clear corrupted state:
   ```bash
   osascript -e 'quit app "Docker Desktop"' && sleep 5 && open -a "Docker Desktop"
   ```

2. Wait 20 seconds, then remove all containers:
   ```bash
   docker ps -a -q | xargs docker rm -f
   ```

3. Try with a different project name:
   ```bash
   docker compose -p myproject-new -f docker-compose.dev.yml up -d --wait
   ```

### Prevention

Always use explicit project names in `docker compose` commands to avoid this issue. The Makefile in this project has been updated to use `-p test-fullstack-template` for all Docker Compose commands.
