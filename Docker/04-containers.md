# 04 — Docker Containers

## Container Lifecycle

```
[Image]
   │
   ▼
docker create  →  CREATED
                     │
              docker start
                     │
                     ▼
                  RUNNING  ←──── docker restart
                  │     │
         docker pause  docker stop / kill
                  │     │
               PAUSED  STOPPED
                  │     │
          docker unpause  │
                  └──► RUNNING
                           │
                      docker rm
                           │
                        DELETED
```

---

## Running Containers

```bash
# Syntax
docker run [OPTIONS] <image> [COMMAND]

# Common flags
-d              # detached mode (background)
-it             # interactive + pseudo-TTY (for shell)
--name <name>   # assign container name
-p host:cont    # publish port
-e KEY=VALUE    # set environment variable
-v vol:/path    # mount volume
--rm            # auto-remove when container exits
--network <net> # attach to network
--restart <policy> # restart policy
```

```bash
# Examples
docker run -d --name webserver -p 8080:80 nginx:latest
docker run -it --name myubuntu ubuntu:22.04 bash
docker run -d --name db -e MYSQL_ROOT_PASSWORD=secret mysql:8
docker run --rm ubuntu echo "one-time task"
docker run -d --restart=always --name api myapp:1.0
```

---

## List Containers

```bash
docker ps                    # only running containers
docker ps -a                 # all containers (running + stopped)
docker ps -q                 # only container IDs
docker ps -aq                # all container IDs (running + stopped)
docker ps --filter status=exited   # only stopped ones
docker ps --filter name=web        # filter by name
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"  # custom format
```

---

## Start, Stop & Restart

```bash
docker start <container>               # start stopped container
docker stop <container>                # graceful stop (SIGTERM → SIGKILL)
docker stop -t 5 <container>          # custom timeout (seconds) before SIGKILL
docker kill <container>               # immediate kill (SIGKILL)
docker restart <container>            # stop + start
docker restart -t 10 <container>      # with timeout

# Multiple at once
docker stop container1 container2 container3
```

---

## Execute Commands Inside Container

```bash
# Open interactive bash shell
docker exec -it <container> bash
docker exec -it <container> sh        # for alpine images

# Run a one-off command
docker exec <container> ls /app
docker exec <container> cat /etc/nginx/nginx.conf

# Run as specific user
docker exec -u root <container> bash

# Set env var inside exec session
docker exec -e DEBUG=true -it <container> bash
```

---

## Attach to a Running Container

```bash
docker attach <container>             # attach stdin/stdout to container
# Press Ctrl+P, Ctrl+Q to detach WITHOUT stopping
```

> ⚠️ `docker attach` attaches to the **main process**. Exiting can stop the container.  
> Use `docker exec -it` instead for interactive debugging.

---

## Inspect & Monitor

```bash
docker inspect <container>            # full JSON config, IPs, mounts, env vars
docker inspect -f '{{.NetworkSettings.IPAddress}}' <container>  # get IP
docker logs <container>               # view container logs
docker logs -f <container>            # follow logs (tail -f style)
docker logs --tail 100 <container>    # last 100 lines
docker logs --since 10m <container>   # logs from last 10 minutes

docker stats                          # live CPU/memory/IO stats for all containers
docker stats <container>              # stats for one container
docker top <container>                # processes running inside container
docker port <container>               # show port mappings
docker diff <container>               # show filesystem changes (A=added, C=changed, D=deleted)
```

---

## Copy Files To/From Container

```bash
# Host → Container
docker cp ./config.json mycontainer:/app/config.json

# Container → Host
docker cp mycontainer:/app/logs/app.log ./app.log
```

---

## Container Rename, Pause & Commit

```bash
docker rename old-name new-name                    # rename container

docker pause <container>                           # freeze processes (SIGSTOP)
docker unpause <container>                         # resume (SIGCONT)

docker commit <container> myimage:v2               # create image from running container
docker commit -m "added config" <container> myimage:v2  # with message
```

---

## Restart Policies

```bash
docker run -d --restart=no           <image>  # default — never auto-restart
docker run -d --restart=always       <image>  # always restart (even on Docker restart)
docker run -d --restart=on-failure   <image>  # restart only on non-zero exit
docker run -d --restart=on-failure:3 <image>  # max 3 retry attempts
docker run -d --restart=unless-stopped <image> # restart unless manually stopped
```

---

## Remove Containers

```bash
docker rm <container>                            # remove stopped container
docker rm -f <container>                         # force remove running container
docker rm -f container1 container2               # remove multiple

# ─── ADVANCED: Remove ALL Containers ─────────────────────────────────
# Remove all STOPPED containers
docker container prune -f

# Remove ALL containers (running + stopped) — ONE LINER
docker rm -f $(docker ps -aq)

# PowerShell equivalent (Windows)
docker ps -aq | ForEach-Object { docker rm -f $_ }

# Remove stopped containers + dangling images + networks at once
docker system prune -f

# Nuclear option — remove EVERYTHING (containers + images + volumes + networks)
docker system prune -a --volumes -f
```

---

## Resource Limits

```bash
# CPU
docker run --cpus="1.5" nginx           # allow max 1.5 CPU cores
docker run --cpu-shares=512 nginx        # relative CPU weight (default 1024)

# Memory
docker run --memory="512m" nginx         # hard limit 512 MB RAM
docker run --memory="512m" --memory-swap="1g" nginx   # RAM + swap limit

# Both together
docker run -d \
  --name myapp \
  --cpus="0.5" \
  --memory="256m" \
  -p 8080:80 \
  nginx:latest
```

---

## Environment Variables

```bash
# Pass single variable
docker run -e APP_ENV=production myapp

# Pass multiple
docker run -e APP_ENV=production -e PORT=8080 myapp

# Load from file
docker run --env-file .env myapp
```
