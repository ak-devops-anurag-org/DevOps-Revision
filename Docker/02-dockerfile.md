# 02 — Dockerfile Instructions & Multi-Stage Builds

## Dockerfile — Instruction Flow

```dockerfile
FROM        # 1. Base image (always first)
LABEL       # 2. Metadata (author, version, description)
ENV         # 3. Environment variables
WORKDIR     # 4. Set working directory (creates if absent)
COPY / ADD  # 5. Copy files into image
RUN         # 6. Execute shell commands (builds a new layer)
EXPOSE      # 7. Document port(s) the app listens on
VOLUME      # 8. Declare persistent mount points
USER        # 9. Switch to non-root user
ENTRYPOINT  # 10. Fixed executable to run
CMD         # 11. Default arguments (overridable at runtime)
```

---

## Key Instructions Explained

### `FROM`
```dockerfile
FROM node:18-alpine          # lightweight alpine base
FROM ubuntu:22.04            # full ubuntu base
FROM scratch                 # completely empty (for static binaries)
```

### `RUN`
- Executes during **build time** and creates a new layer.
- Chain commands with `&&` to reduce layers.

```dockerfile
RUN apt-get update && apt-get install -y curl git \
    && rm -rf /var/lib/apt/lists/*
```

### `COPY` vs `ADD`

| | `COPY` | `ADD` |
|--|--------|-------|
| Copy local files | ✅ | ✅ |
| Copy remote URLs | ❌ | ✅ |
| Auto-extract `.tar` | ❌ | ✅ |
| **Preferred** | ✅ For most cases | Only when tar/URL needed |

```dockerfile
COPY src/ /app/src/          # simple file copy
ADD archive.tar.gz /app/     # auto-extracts tar
```

### `CMD` vs `ENTRYPOINT`

| | `CMD` | `ENTRYPOINT` |
|--|-------|--------------|
| **Purpose** | Default arguments | Fixed executable |
| **Overridable** | Yes (`docker run <image> <override>`) | Only with `--entrypoint` flag |
| **Best used for** | Default run command | Defining the main binary |

```dockerfile
# Pattern: ENTRYPOINT = executable, CMD = default args
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]

# Override CMD at runtime:
# docker run myimage -g "daemon on;"
```

### `ENV` — Environment Variables
```dockerfile
ENV NODE_ENV=production \
    PORT=3000
```

### `WORKDIR`
```dockerfile
WORKDIR /app    # sets CWD; all subsequent COPY/RUN use this
```

### `EXPOSE`
- **Documentation only** — does not publish the port.
- Use `-p` or `-P` at `docker run` to actually publish.

```dockerfile
EXPOSE 3000 8080
```

### `USER`
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

### `ARG` vs `ENV`

| | `ARG` | `ENV` |
|--|-------|-------|
| Available during | Build only | Build + Runtime |
| Passed by | `--build-arg` flag | Dockerfile or `-e` at run |

```dockerfile
ARG APP_VERSION=1.0
ENV VERSION=$APP_VERSION
```

---

## Port Publishing: `EXPOSE` vs `-p` vs `-P`

```bash
# -p  → map specific host port to container port
docker run -d -p 8080:80 nginx          # host:8080 → container:80

# -P  → map ALL EXPOSE'd ports to random host ports
docker run -d -P nginx

# Check mapped ports
docker port <container>
```

---

## Multi-Stage Build

**Problem:** Build tools (compilers, bundlers) bloat the final image.  
**Solution:** Use multiple `FROM` stages — copy only the built artifacts.

```dockerfile
# ── Stage 1: Build ──────────────────────────────
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

# ── Stage 2: Production (slim) ──────────────────
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
# Build final image (only Stage 2 ends up in the image)
docker build -t myapp:prod .

# Build only up to a specific stage
docker build --target build -t myapp:dev .
```

**Benefits:**
- ✅ Final image has **no** build tools / source code
- ✅ Drastically smaller and more secure image
- ✅ Clear separation of build vs runtime concerns

---

## Dockerfile Best Practices

| Rule | Why |
|------|-----|
| Use specific tags (`node:18-alpine`) | Avoid breaking changes from `latest` |
| Chain `RUN` commands with `&&` | Fewer layers → smaller image |
| Copy `package.json` before source code | Leverage Docker layer cache |
| Use `.dockerignore` | Exclude `node_modules`, `.git`, secrets |
| Use non-root `USER` | Reduce attack surface |
| Use multi-stage builds | Keep production image lean |

### Sample `.dockerignore`
```
node_modules
.git
.env
*.log
dist
```

---

## Quick Example – Full Node.js Dockerfile

```dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=production
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
USER node
CMD ["node", "dist/index.js"]
```

```bash
docker build -t mynode-app:1.0 .
docker run -d -p 3000:3000 --name nodeapp mynode-app:1.0
```


### How to server React frontend - using node or Nginx

For a standard React SPA (Create React App, Vite, etc. — anything that just builds to static HTML/JS/CSS), Nginx is the better practice, not a Node.js server. A few reasons this is the industry default:

- You don't need a JS runtime to serve static files. Node.js/Express serving static assets is doing unnecessary work — spinning up an event loop, V8, npm dependencies — for a job that's just "read a file, send bytes." Nginx does this in C, with far lower memory footprint and higher throughput.
- Smaller, more secure image. An Nginx-alpine final image has no Node runtime, no npm packages, no node_modules — smaller attack surface, fewer CVEs to scan for in the CWPP gate you set up earlier.
- Mature reverse-proxy features for free — gzip/brotli compression, caching headers, TLS termination, rate limiting, SPA fallback routing — all config, no code.
- Node.js server only earns its place when you actually need a server — Next.js/Remix SSR, server components, an API you're bundling in, or WebSocket handling alongside the frontend. If you're doing pure client-side rendering, a Node server is extra runtime for zero benefit.


```dockerfile
# ---------- Build stage ----------
FROM node:20-alpine AS build
WORKDIR /app

# Install deps first so this layer is cached unless package files change
COPY package.json package-lock.json ./
RUN npm ci --omit=production

COPY . .
RUN npm run build
# CRA outputs to /app/build, Vite outputs to /app/dist — adjust the COPY
# path below to match your build tool.

# ---------- Production stage ----------
FROM nginx:1.27-alpine AS production

# Strip the default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Bring in only the compiled static assets, not source or node_modules
COPY --from=build /app/build /usr/share/nginx/html

# Custom server block: SPA routing, gzip, caching, security headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Run as a non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid
USER nginx

# Non-privileged port since we're not running as root
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```