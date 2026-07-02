# 08 — Docker Commands Reference

## 🟢 Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `docker version` | Docker client + server version | `docker version` |
| `docker info` | System-wide info (containers, images, daemon) | `docker info` |
| `docker help` | List all commands | `docker help` |
| `docker <cmd> --help` | Help for specific command | `docker run --help` |

---

## 📦 Image Commands

```bash
docker build -t <name>:<tag> .             # build image from Dockerfile
docker build --no-cache -t myapp .         # bypass layer cache
docker build --target <stage> -t myapp .   # build up to specific multi-stage stage
docker pull <image>:<tag>                  # pull from registry
docker push <image>:<tag>                  # push to registry
docker images                              # list local images
docker images -a                           # include intermediate layers
docker rmi <image>                         # remove image
docker rmi -f $(docker images -q)          # ⚡ force remove ALL images
docker image prune                         # remove dangling images
docker image prune -a -f                   # remove ALL unused images
docker image inspect <image>               # full JSON info
docker image history <image>               # show layers
docker tag <src>:<tag> <dest>:<tag>        # create tag alias
docker save -o file.tar <image>            # export image to tar
docker load -i file.tar                    # import image from tar
docker search <term>                       # search Docker Hub
```

---

## 🚀 Container Commands

### Create & Run
```bash
docker run <image>                         # run container (foreground)
docker run -d <image>                      # run detached (background)
docker run -it <image> bash                # interactive shell
docker run --name <name> <image>           # assign name
docker run -p 8080:80 <image>              # map port host:container
docker run -P <image>                      # publish all EXPOSE'd ports
docker run -e KEY=VAL <image>              # set env variable
docker run --env-file .env <image>         # load env from file
docker run -v vol:/path <image>            # mount named volume
docker run -v /host:/container <image>     # bind mount
docker run --rm <image>                    # auto-remove on exit
docker run --network <net> <image>         # attach to network
docker run --restart=always <image>        # auto-restart policy
docker run --cpus="1" --memory="512m" <image>  # resource limits
docker create <image>                      # create without starting
```

### View Containers
```bash
docker ps                                  # list running containers
docker ps -a                               # all (running + stopped)
docker ps -q                               # IDs of running containers
docker ps -aq                              # IDs of ALL containers
docker ps --filter status=exited           # only stopped containers
docker ps --filter name=web                # filter by name pattern
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

### Control
```bash
docker start <container>                   # start stopped container
docker stop <container>                    # graceful stop (SIGTERM)
docker stop -t 5 <container>              # 5s timeout before SIGKILL
docker kill <container>                    # immediate SIGKILL
docker restart <container>                 # stop + start
docker pause <container>                   # freeze processes
docker unpause <container>                 # resume processes
docker rename <old> <new>                  # rename container
```

### Interact
```bash
docker exec -it <container> bash           # open shell in running container
docker exec -it <container> sh             # for alpine
docker exec -u root <container> bash       # exec as root
docker exec <container> <command>          # one-off command
docker attach <container>                  # attach stdin/stdout to container
docker cp ./file.txt <container>:/app/     # host → container
docker cp <container>:/app/log ./log.txt   # container → host
```

### Inspect & Debug
```bash
docker logs <container>                    # view logs
docker logs -f <container>                 # follow logs (live)
docker logs --tail 100 <container>         # last 100 lines
docker logs --since 1h <container>         # logs from last 1 hour
docker inspect <container>                 # full JSON details
docker inspect -f '{{.NetworkSettings.IPAddress}}' <container>  # get IP
docker stats                               # live resource usage (all)
docker stats <container>                   # one container
docker top <container>                     # processes inside
docker port <container>                    # port mappings
docker diff <container>                    # filesystem changes
```

### Remove
```bash
docker rm <container>                      # remove stopped container
docker rm -f <container>                   # force remove (even running)
docker rm -f container1 container2         # remove multiple

# ─── ⚡ ADVANCED CLEANUP — ONE LINERS ──────────────────────────────────

# Remove ALL stopped containers
docker container prune -f

# Remove ALL containers (running + stopped) — Linux/macOS
docker rm -f $(docker ps -aq)

# Remove ALL containers (running + stopped) — PowerShell (Windows)
docker ps -aq | ForEach-Object { docker rm -f $_ }

# Remove only STOPPED containers — Linux/macOS
docker rm $(docker ps -aq --filter status=exited)

# Remove containers + dangling images + unused networks
docker system prune -f

# Remove EVERYTHING (containers + images + volumes + networks + cache) ☢️
docker system prune -a --volumes -f
```

---

## 🌐 Network Commands

```bash
docker network ls                               # list networks
docker network create <name>                    # create bridge network
docker network create --driver overlay <name>   # overlay network
docker network create --subnet 10.1.0.0/24 <name>
docker network inspect <name>                   # detailed view
docker network connect <network> <container>    # attach to network
docker network disconnect <network> <container> # detach from network
docker network rm <name>                        # remove network
docker network prune -f                         # remove ALL unused networks
```

---

## 💾 Volume Commands

```bash
docker volume create <name>                     # create volume
docker volume ls                                # list volumes
docker volume inspect <name>                    # full info + mountpoint
docker volume rm <name>                         # remove specific volume
docker volume prune -f                          # remove ALL unused volumes
docker run -v <vol>:/path <image>               # use volume in container
docker run -v /host:/container <image>          # bind mount
docker run --mount type=volume,source=<vol>,target=/path <image>
docker run --mount type=bind,source=/host,target=/container <image>
docker run --mount type=tmpfs,target=/tmp <image>
```

---

## 🧹 Cleanup & Prune Commands

```bash
# Images
docker image prune                    # dangling images only
docker image prune -a -f              # ALL unused images

# Containers
docker container prune -f             # stopped containers

# Volumes
docker volume prune -f                # unused volumes (⚠️ data loss)

# Networks
docker network prune -f               # unused networks

# Build cache
docker builder prune -f               # all build cache
docker builder prune --keep-storage 2GB   # keep 2GB of cache

# System-wide
docker system prune -f                # containers + images + networks (no volumes)
docker system prune -a -f             # + unreferenced images
docker system prune -a --volumes -f   # ☢️ EVERYTHING including volumes

# Disk usage
docker system df                      # usage summary
docker system df -v                   # verbose per image/container/volume
```

---

## 🏷️ Registry & Auth Commands

```bash
docker login                          # login to Docker Hub
docker login myregistry.io            # login to private registry
docker logout                         # logout
docker push <image>:<tag>             # push image
docker pull <image>:<tag>             # pull image
docker search <term>                  # search Docker Hub
docker search --filter stars=50 <term>
```

---

## 🔐 Commit & Export

```bash
docker commit <container> <new-image>:<tag>          # container → image
docker commit -m "msg" -a "author" <c> <image>:<tag>

docker export -o snapshot.tar <container>            # container FS → tar
docker import snapshot.tar <image>:<tag>             # tar → image

docker save -o image.tar <image>:<tag>               # image → tar (with layers)
docker load -i image.tar                             # tar → image (restore layers)
```

---

## 📊 Monitoring Commands

```bash
docker stats                                  # real-time CPU/MEM/NET/IO all containers
docker stats <container>                      # single container
docker stats --no-stream                      # one snapshot (no live mode)
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

docker top <container>                        # processes in container (like ps)
docker events                                 # live stream of Docker events
docker events --filter type=container         # only container events
docker events --since 30m                     # last 30 minutes
```

---

## ⚡ Power-User One-Liners (Advanced)

```bash
# Stop ALL running containers
docker stop $(docker ps -q)

# Remove ALL containers (running + stopped)
docker rm -f $(docker ps -aq)

# Remove ALL images
docker rmi -f $(docker images -q)

# Remove ALL volumes
docker volume rm $(docker volume ls -q)

# Remove ALL networks (except defaults)
docker network rm $(docker network ls -q)

# Full nuclear cleanup ☢️ — containers + images + volumes + networks + cache
docker system prune -a --volumes -f

# Get container IP
docker inspect -f '{{.NetworkSettings.IPAddress}}' <container>

# Get all container names and IPs
docker inspect -f '{{.Name}} - {{.NetworkSettings.IPAddress}}' $(docker ps -q)

# Kill all containers using a specific image
docker rm -f $(docker ps -aq --filter ancestor=nginx)

# Run quick alpine shell
docker run --rm -it alpine sh

# Watch container logs with timestamps
docker logs -f --timestamps <container>

# Copy entire directory from container
docker cp <container>:/app ./local-app-backup

# Restart only crashed (exited non-zero) containers
docker start $(docker ps -aq --filter status=exited)

# Check how much space Docker is using
docker system df -v

# Remove dangling images (untagged)
docker image prune -f

# List images with size > 100MB
docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | awk '$2 > 100'

# Enter last created container
docker exec -it $(docker ps -l -q) bash
```

---

## Summary Table — Quick Reference

| Category | Remove All One-Liner |
|----------|---------------------|
| **All containers** (running+stopped) | `docker rm -f $(docker ps -aq)` |
| **All stopped containers** | `docker container prune -f` |
| **All images** | `docker rmi -f $(docker images -q)` |
| **All unused images** | `docker image prune -a -f` |
| **All volumes** | `docker volume rm $(docker volume ls -q)` |
| **All unused volumes** | `docker volume prune -f` |
| **All unused networks** | `docker network prune -f` |
| **Everything (nuclear)** ☢️ | `docker system prune -a --volumes -f` |
