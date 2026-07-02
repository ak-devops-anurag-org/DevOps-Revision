# 01 — Introduction to Docker

## What is Docker?
- **Containerization platform** that packages apps + dependencies into portable **containers**.
- Solves the *"works on my machine"* problem — consistent runtime across dev, test, and prod.
- Provides a **CLI / SDK** toolset plus the **Docker Engine** (daemon + REST API).

```bash
# Check Docker version
docker version

# System-wide info
docker info
```

---

## Docker Architecture

```
┌─────────────────────────────────────────────┐
│                  Docker CLI                 │
│          (docker build / run / ps …)        │
└─────────────────┬───────────────────────────┘
                  │ REST API
┌─────────────────▼───────────────────────────┐
│             Docker Daemon  (dockerd)        │
│  Manages Images │ Containers │ Networks │ Volumes │
└──────┬──────────┴───────────────────────────┘
       │ gRPC
┌──────▼─────────────────┐
│      containerd        │  ← High-level runtime
└──────┬─────────────────┘
       │
┌──────▼─────────────────┐
│    runc (OCI runtime)  │  ← Low-level runtime
└────────────────────────┘
```

| Component | Role |
|-----------|------|
| **Docker Daemon** (`dockerd`) | Long-running server process that builds, runs, and manages containers |
| **Docker CLI** | Client tool that sends commands to the daemon via REST API |
| **containerd** | High-level container runtime (manages lifecycle, image pulls) |
| **runc** | OCI-compliant low-level runtime that spawns actual containers |
| **Registry** | Remote store for images (Docker Hub, AWS ECR, GCR, private) |

---

## Image vs Container

| | Image | Container |
|--|-------|-----------|
| **Nature** | Immutable, read-only template | Running instance of an image |
| **Storage** | Stacked read-only layers | Adds a writable COW layer on top |
| **Created by** | `docker build` | `docker run` / `docker create` |
| **Persistence** | Permanent (until deleted) | Ephemeral by default |

```bash
# Pull image + run as a container
docker pull ubuntu:22.04
docker run --rm ubuntu:22.04 echo "Hello from container"

# List images vs running containers
docker images
docker ps -a
```

---

## Copy-On-Write (COW) Layer Architecture

- Images are **stacked read-only layers** (one per Dockerfile instruction).
- On `docker run`, Docker adds a thin **writable COW layer** on top.
- Changes happen only in the writable layer — base layers are shared between containers.

```
[ writable layer  ]  ← Container-specific changes
[ RUN npm install ]  ← Image layer 3 (read-only)
[ COPY . /app     ]  ← Image layer 2 (read-only)
[ FROM node:18    ]  ← Base image layer (read-only)
```

**Benefits:**  ✅ Shared layers save disk space  ✅ Fast container start  ✅ Non-destructive changes

---

## Namespaces & cGroups (Container Isolation)

### Namespaces — **what a process can see**
| Namespace | Isolates |
|-----------|----------|
| `PID` | Process IDs |
| `NET` | Network interfaces, IPs, ports |
| `MNT` | Filesystem mount points |
| `IPC` | Inter-process communication |
| `UTS` | Hostname and domain name |
| `USER` | User and group IDs |

### cGroups — **what a process can use**
- Limit and monitor **CPU, memory, disk I/O, network bandwidth** per container.

```bash
# Run with resource limits
docker run --rm --cpus="0.5" --memory="256m" ubuntu top

# Check resource usage live
docker stats
```

---

## Container Lifecycle

```
create ──► start ──► running ──► stop ──► remove
              ▲          │
              └──restart─┘
```

| Stage | Command | Description |
|-------|---------|-------------|
| Create | `docker create` | Allocates COW layer, network; does NOT start process |
| Start | `docker start` | Spawns the process inside the container |
| Run | `docker run` | **create + start** in one step |
| Execute | `docker exec -it <c> bash` | Open shell inside a running container |
| Stop | `docker stop <c>` | Sends `SIGTERM` → waits → `SIGKILL` |
| Kill | `docker kill <c>` | Immediately sends `SIGKILL` |
| Remove | `docker rm <c>` | Deletes container + its writable layer |

```bash
# Full lifecycle example
docker run -d --name webserver nginx:latest   # create + start
docker exec -it webserver bash               # enter shell
docker stop webserver                        # graceful stop
docker rm webserver                          # cleanup
```
