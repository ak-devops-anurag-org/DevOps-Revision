# 06 — Docker Storage

## Storage Types Overview

| Type | Managed By | Persists After `docker rm`? | Use Case |
|------|------------|----------------------------|----------|
| **Docker Volume** | Docker daemon | ✅ Yes | Databases, persistent app data |
| **Bind Mount** | Host OS | ✅ Yes (host file stays) | Dev — live code reload |
| **tmpfs Mount** | Memory (RAM) | ❌ No | Sensitive in-memory data |
| **COW Layer** | Docker (per container) | ❌ No | Container runtime changes |

---

## Docker Volumes

- Managed by Docker, stored at `/var/lib/docker/volumes/` on Linux.
- **Best choice for production** — portable, backup-friendly, driver-extensible.

```bash
# Create
docker volume create myvolume

# List
docker volume ls

# Inspect (see mountpoint, driver, etc.)
docker volume inspect myvolume

# Remove
docker volume rm myvolume

# Remove ALL unused volumes
docker volume prune -f

# Mount to container
docker run -d -v myvolume:/data alpine

# Named volume (shorter syntax)
docker run -d \
  --name mydb \
  -v pgdata:/var/lib/postgresql/data \
  postgres:15

# Share same volume between two containers
docker run -d --name writer -v shared:/data alpine
docker run -d --name reader -v shared:/data:ro alpine   # read-only for reader
```

---

## Bind Mounts

- Map a **host directory/file** directly into the container.
- Changes on host reflect instantly in container (great for development).
- No Docker management — host path must exist.

```bash
# Syntax
docker run -v /absolute/host/path:/container/path <image>

# Examples
docker run -d -v $(pwd)/app:/app -p 3000:3000 node:18    # dev with live reload
docker run -v /etc/nginx/conf.d:/etc/nginx/conf.d nginx   # custom nginx config

# Windows (PowerShell)
docker run -d -v ${PWD}/src:/app node:18

# Read-only bind mount
docker run -v /host/config:/app/config:ro myapp
```

---

## tmpfs Mounts

- Stored in **host memory only** — never written to disk.
- Data is gone when container stops.
- Good for secrets, session tokens, cache.

```bash
# Syntax
docker run --tmpfs /container/path <image>

# With options
docker run --mount type=tmpfs,target=/tmp,tmpfs-size=100m myapp
```

---

## `-v` vs `--mount` Syntax

| | `-v` (legacy) | `--mount` (modern, explicit) |
|--|----------------|------------------------------|
| Syntax | Compact | Verbose, key=value |
| Explicit type | ❌ Inferred | ✅ `type=volume/bind/tmpfs` |
| Error-friendly | ❌ Less clear | ✅ Better error messages |
| Preferred | Dev shortcuts | Production / scripts |

```bash
# Volume — both equivalent
docker run -v myvolume:/data alpine
docker run --mount type=volume,source=myvolume,target=/data alpine

# Bind — both equivalent
docker run -v /host/path:/app alpine
docker run --mount type=bind,source=/host/path,target=/app alpine

# tmpfs — both equivalent
docker run --tmpfs /tmp alpine
docker run --mount type=tmpfs,target=/tmp alpine
```

---

## Volume Lifecycle

```
docker volume create myvolume
        │
        ▼
docker run -v myvolume:/data myapp    ← container uses volume
        │
        ▼
docker stop / docker rm myapp         ← container deleted
        │
        ▼
myvolume STILL EXISTS ──► reuse with next container
        │
        ▼
docker volume rm myvolume              ← only then data is deleted
```

---

## Volume in Docker Compose

```yaml
services:
  db:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data

  web:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro   # bind mount (read-only)

volumes:
  pgdata:   # named volume — managed by Docker
```

---

## Backup & Restore Volumes

```bash
# Backup volume to tar
docker run --rm \
  -v myvolume:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/myvolume-backup.tar.gz -C /data .

# Restore volume from tar
docker run --rm \
  -v myvolume:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/myvolume-backup.tar.gz -C /data
```

---

## Storage Best Practices

| Rule | Reason |
|------|--------|
| Use **named volumes** for production data | Docker manages lifecycle, easy backup |
| Use **bind mounts** only in dev | Host dependency — not portable |
| Never store secrets in volumes without encryption | Volumes are plain directories on disk |
| Use `--read-only` with bind mounts where possible | Prevent accidental writes |
| Prune unused volumes regularly | Prevent disk bloat |

```bash
# Check disk usage
docker system df
docker system df -v     # verbose (per image/container/volume)
```
