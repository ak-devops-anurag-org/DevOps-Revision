# 09 — Security & Best Practices

## 1. Use Minimal Base Images

- Smaller images = smaller attack surface.
- Fewer packages = fewer vulnerabilities.

```dockerfile
# ❌ Avoid
FROM ubuntu:latest

# ✅ Prefer
FROM node:18-alpine          # Alpine Linux (~5 MB)
FROM python:3.11-slim        # Debian slim variant
FROM gcr.io/distroless/nodejs18-debian12   # Google distroless
```

---

## 2. Multi-Stage Builds

- Keep build tools out of the final image.
- Final image has only what the app needs to run.

```dockerfile
FROM node:18 AS build
WORKDIR /app
COPY . .
RUN npm ci && npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

---

## 3. Run as Non-Root User

- By default, Docker containers run as **root** — a security risk.
- Always drop to a non-root user.

```dockerfile
# Alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Debian/Ubuntu
RUN useradd --create-home appuser
USER appuser
```

```bash
# Verify user inside container
docker exec mycontainer whoami
```

---

## 4. Read-Only Container Filesystem

```bash
# Make container filesystem read-only
docker run --read-only -d myapp

# Allow specific writable paths
docker run --read-only --tmpfs /tmp myapp
```

---

## 5. Scan Images for Vulnerabilities

```bash
# Docker Scout (built-in, newer Docker)
docker scout cves myapp:latest
docker scout quickview myapp:latest

# Trivy (popular open-source scanner)
trivy image myapp:latest
trivy image --severity HIGH,CRITICAL myapp:latest

# Grype
grype myapp:latest
```

---

## 6. Avoid Hardcoding Secrets

```dockerfile
# ❌ Never do this
ENV DB_PASSWORD=mysecretpassword

# ✅ Pass secrets at runtime
docker run -e DB_PASSWORD=mysecretpassword myapp

# ✅ Use Docker Secrets (Swarm)
docker secret create db_pass ./db_pass.txt
docker service create --secret db_pass myapp

# ✅ Use env file (never commit .env to git)
docker run --env-file .env myapp
```

---

## 7. Use `.dockerignore`

Prevents sensitive or unnecessary files from entering the build context.

```
# .dockerignore
.git
.env
*.log
node_modules
secrets/
*.pem
*.key
```

---

## 8. Limit Container Capabilities

```bash
# Drop ALL capabilities, add only needed ones
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx

# Don't run in privileged mode ❌ (grants full host access)
# Only use privileged if absolutely necessary
docker run --privileged myapp    # ❌ avoid
```

---

## 9. Avoid `--network=host` in Production

```bash
# ❌ Host mode bypasses network isolation
docker run --network host myapp

# ✅ Use custom bridge networks instead
docker network create mynet
docker run --network mynet myapp
```

---

## 10. Resource Limits

Prevent a single runaway container from consuming all host resources.

```bash
docker run \
  --cpus="1.0" \
  --memory="512m" \
  --memory-swap="512m" \   # disable swap
  --pids-limit=100 \        # limit number of processes
  myapp
```

---

## 11. Keep Images Updated

```bash
# Pull latest base image before rebuilding
docker pull node:18-alpine
docker build --no-cache -t myapp .

# Use Watchtower to auto-update container images
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower
```

---

## 12. Docker Content Trust (DCT)

Ensures only signed images are pulled and run.

```bash
# Enable content trust
export DOCKER_CONTENT_TRUST=1

# Now all pull/push operations verify signatures
docker pull nginx        # only succeeds if image is signed
```

---

## 13. Health Checks

```dockerfile
# In Dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

```bash
# Check container health status
docker inspect --format='{{.State.Health.Status}}' <container>
```

---

## Security Checklist

| ✅ | Practice |
|----|----------|
| ✅ | Use minimal/distroless base image |
| ✅ | Multi-stage builds |
| ✅ | Non-root USER |
| ✅ | Read-only filesystem where possible |
| ✅ | No secrets in Dockerfile/ENV |
| ✅ | `.dockerignore` in place |
| ✅ | Cap-drop unnecessary capabilities |
| ✅ | CPU + memory limits set |
| ✅ | Scan images with Trivy/Scout |
| ✅ | Use Docker Content Trust |
| ✅ | Health checks defined |
| ✅ | Avoid `--privileged` and `--network=host` |
