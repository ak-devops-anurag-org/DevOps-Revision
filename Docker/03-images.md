# 03 — Docker Images

## What is a Docker Image?
- **Immutable, read-only** filesystem snapshot built from a Dockerfile.
- Made of **stacked layers** — each Dockerfile instruction creates one layer.
- Stored locally or in a remote **registry** (Docker Hub, ECR, GCR, private).

---

## Build an Image

```bash
# Syntax
docker build -t <name>:<tag> <build-context>

# Examples
docker build -t myapp:1.0 .                    # build from current directory
docker build -t myapp:latest -f Dockerfile.prod . # custom Dockerfile
docker build --no-cache -t myapp:fresh .       # bypass layer cache
docker build --build-arg ENV=production -t myapp . # pass build args
```

---

## List & Inspect Images

```bash
docker images                          # list local images
docker images -a                       # include intermediate layers
docker images --filter dangling=true   # show only dangling images
docker image inspect nginx             # full JSON metadata of an image
docker image history nginx             # show layers + sizes
```

---

## Tag an Image

```bash
# Syntax
docker tag <source-image>:<tag> <target-image>:<tag>

# Examples
docker tag myapp:1.0 myapp:latest                        # local alias
docker tag myapp:1.0 myregistry.io/team/myapp:1.0       # for private registry
docker tag myapp:1.0 username/myapp:1.0                  # for Docker Hub
```

---

## Push & Pull Images

```bash
# Login to registry
docker login                                          # Docker Hub
docker login myregistry.io                           # private registry

# Push
docker push username/myapp:1.0
docker push myregistry.io/team/myapp:1.0

# Pull
docker pull nginx                                    # latest tag
docker pull nginx:1.25-alpine                        # specific tag
docker pull myregistry.io/team/myapp:1.0             # from private registry

# Search Docker Hub
docker search nginx
docker search --filter stars=100 nginx               # filter by stars
```

---

## Save, Load, Export & Import

```bash
# Save image to tar file (preserves layers and tags)
docker save -o myapp.tar myapp:1.0

# Load image from tar
docker load -i myapp.tar

# Export container filesystem as tar (flat, no layers)
docker export -o container-fs.tar mycontainer

# Import tar as a new image
docker import container-fs.tar myapp:imported
```

> 💡 **save/load** → for images (keeps layers).  
> **export/import** → for containers (flat snapshot, loses history).

---

## Types of Docker Images

| Type | Description | Use Case |
|------|-------------|----------|
| **Official Images** | Maintained by Docker/vendors on Docker Hub | Base images (nginx, node, python) |
| **Distroless Images** | No shell, no package manager — minimal OS | Production security (Google distroless) |
| **Alpine Images** | Ultra-small Linux (~5 MB) | Smaller production images |
| **Scratch Images** | Empty — zero base | Static Go/C binaries |
| **Dangling Images** | Untagged, orphaned layers from old builds | Should be pruned regularly |
| **Intermediate Images** | Temporary layers cached during build | Reused for faster rebuilds |

```bash
# Remove dangling images
docker image prune

# Remove ALL unused images (not just dangling)
docker image prune -a

# Remove specific image
docker rmi myapp:1.0
docker rmi <image-id>

# Force remove (even if container uses it)
docker rmi -f myapp:1.0
```

---

## Remove All Images (Advanced)

```bash
# Remove all images at once
docker rmi $(docker images -q)

# Force remove all images
docker rmi -f $(docker images -q)

# Remove all unused images (dangling + unreferenced)
docker image prune -a -f

# Full system cleanup (images + containers + networks + cache)
docker system prune -a -f
```

---

## Image Layer Cache — How It Works

```
Dockerfile line      → Layer    → Cached?
─────────────────────────────────────────
FROM node:18         → Layer 1  → ✅ Cache hit (unchanged)
COPY package.json .  → Layer 2  → ✅ Cache hit (file same)
RUN npm install      → Layer 3  → ✅ Cache hit (Layer 2 same)
COPY . .             → Layer 4  → ❌ Cache MISS (code changed)
RUN npm run build    → Layer 5  → ❌ Rebuild
```

**Key insight:** Copy `package.json` BEFORE copying source code so `npm install` is cached and only rebuilt when dependencies change.
