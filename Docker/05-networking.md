# 05 — Docker Networking

## Overview
- Containers communicate through virtual **Docker networks**.
- Isolated from the host network by default (bridge mode).
- Docker manages its own internal DNS for container name resolution.

---

## Network Drivers

| Driver | Description | Use Case |
|--------|-------------|----------|
| **bridge** | Default private internal network on single host | Dev, isolated apps |
| **host** | Container shares host network stack directly | Performance-critical (bypasses NAT) |
| **overlay** | Multi-host networking for Swarm/Kubernetes | Distributed / clustered apps |
| **macvlan** | Container gets its own MAC + appears as physical device | Legacy apps needing physical network presence |
| **ipvlan** | Uses host MAC, differentiates by IP — lighter than macvlan | Scalable multi-container networking |
| **none** | No networking — completely isolated | Batch jobs, security sandbox |

---

## Default Bridge vs Custom Bridge

| Feature | Default Bridge (`bridge`) | Custom Bridge |
|---------|--------------------------|---------------|
| Container DNS (name resolution) | ❌ No | ✅ Yes |
| Automatic isolation | Shared with all containers | Per-network isolation |
| `--link` needed to connect | Yes (legacy) | No |
| **Preferred for prod** | ❌ | ✅ |

```bash
# Create a custom bridge network
docker network create --driver bridge mynet

# Run containers in same network (they can reach each other by name)
docker run -d --name app --network mynet myapp
docker run -d --name db  --network mynet mysql:8
# 'app' can reach 'db' as: mysql -h db -u root -p
```

---

## Common Networking Commands

```bash
# List all networks
docker network ls

# Inspect a network (IPs, connected containers)
docker network inspect mynet

# Create network
docker network create mynet
docker network create --driver overlay --subnet 10.1.0.0/24 prodnet

# Connect/Disconnect running container to network
docker network connect mynet mycontainer
docker network disconnect mynet mycontainer

# Remove a network
docker network rm mynet

# Remove ALL unused networks
docker network prune -f
```

---

## Port Publishing

```bash
# -p host:container  — specific port mapping
docker run -d -p 8080:80 nginx          # host port 8080 → container port 80
docker run -d -p 127.0.0.1:8080:80 nginx  # bind to localhost only

# -P — publish ALL EXPOSE'd ports to random host ports
docker run -d -P nginx

# Check mapped ports
docker port <container>
```

---

## Host Network Mode

```bash
# Container uses host's IP and ports directly (no NAT)
docker run -d --network host nginx

# nginx now listens on host port 80 directly (no -p needed)
```

> ⚠️ `--network host` only works on Linux. On Windows/macOS it is ignored or limited.

---

## None Network Mode

```bash
# Container has only loopback interface — completely isolated
docker run --rm --network none alpine ping google.com
# → ping: network is unreachable
```

---

## Macvlan vs IPvlan

| Feature | Macvlan | IPvlan |
|---------|---------|--------|
| MAC address per container | ✅ Unique MAC each | ❌ Shares host MAC |
| Container appears as physical device | ✅ | ❌ |
| Switch / promiscuous mode needed | ✅ | ❌ (easier) |
| Use case | Legacy apps on physical LAN | Scalable cloud networking |

```bash
# Macvlan example
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan-net

docker run -d --network macvlan-net --ip=192.168.1.100 nginx
```

---

## Container IP Addressing

```bash
# Get container IP
docker inspect -f '{{.NetworkSettings.IPAddress}}' <container>

# Get IP on specific network
docker inspect -f '{{.NetworkSettings.Networks.mynet.IPAddress}}' <container>

# Full network details
docker inspect <container> | grep -i ipaddress
```

---

## DNS & Container Name Resolution

- Containers on the **same custom bridge network** resolve each other by **container name**.
- Docker runs an internal DNS server at `127.0.0.11`.

```bash
docker network create appnet
docker run -d --name backend --network appnet mybackend
docker run -d --name frontend --network appnet myfrontend

# frontend can reach backend as:
# http://backend:3000
```

---

## Expose Ports Summary Diagram

```
Host Machine
┌──────────────────────────────────────────────────┐
│  Port 8080  ──(-p 8080:80)──► Container Port 80  │
│  Port 3306  ──(-p 3306:3306)► Container Port 3306│
│  Port XXXX  ──(-P)─────────► Random → EXPOSE'd   │
└──────────────────────────────────────────────────┘
```
