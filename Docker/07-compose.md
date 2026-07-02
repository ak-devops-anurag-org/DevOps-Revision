# 07 — Docker Compose

## What is Docker Compose?
- Tool to **define and run multi-container** Docker applications.
- Uses a `docker-compose.yml` (or `compose.yml`) file to declare services, networks, volumes.
- One command to start/stop the entire stack.

---

## Key Advantages

| Feature | Benefit |
|---------|---------|
| Single config file | Entire app stack in one YAML |
| Dependency management | `depends_on` starts services in order |
| Environment support | `.env` files, env variables |
| Built-in networking | Services communicate by **service name** |
| Reproducible | Same config across dev, CI, staging |

---

## `docker-compose.yml` Structure

```yaml
version: "3.8"            # Compose file version

services:                 # define each container as a service
  <service-name>:
    image: <image>        # use existing image OR
    build: .              # build from local Dockerfile
    container_name: <name>
    ports:
      - "host:container"
    environment:
      - KEY=VALUE
    env_file:
      - .env
    volumes:
      - named-vol:/path
      - ./host:/container
    networks:
      - mynet
    depends_on:
      - <other-service>
    restart: always
    command: <override-cmd>

networks:
  mynet:                  # define custom networks

volumes:
  named-vol:              # define named volumes
```

---

## Full Example — Web App + Database

```yaml
version: "3.8"

services:
  web:
    build: .
    container_name: webapp
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      - db
    networks:
      - appnet
    restart: on-failure

  db:
    image: postgres:15-alpine
    container_name: postgres_db
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - appnet
    restart: always

  cache:
    image: redis:7-alpine
    container_name: redis_cache
    ports:
      - "6379:6379"
    networks:
      - appnet

networks:
  appnet:
    driver: bridge

volumes:
  pgdata:
```

---

## Essential Compose Commands

```bash
# Start all services (detached)
docker compose up -d

# Start and rebuild images
docker compose up -d --build

# Stop all services (keeps containers)
docker compose stop

# Stop and remove containers + networks
docker compose down

# Stop and remove containers + networks + volumes (⚠️ deletes data)
docker compose down -v

# View running services
docker compose ps

# View logs
docker compose logs
docker compose logs -f              # follow
docker compose logs web             # specific service
docker compose logs --tail=50 web   # last 50 lines

# Run one-off command in a service
docker compose exec web bash
docker compose exec db psql -U admin -d mydb

# Scale a service (run multiple replicas)
docker compose up -d --scale web=3

# Pull latest images
docker compose pull

# Rebuild only specific service
docker compose build web

# Restart specific service
docker compose restart web

# Remove stopped containers
docker compose rm

# Validate compose file
docker compose config
```

---

## Environment Variables in Compose

### Option 1 — Inline in `docker-compose.yml`
```yaml
environment:
  - NODE_ENV=production
  - PORT=3000
```

### Option 2 — `.env` file (auto-loaded)
```env
# .env
NODE_ENV=production
PORT=3000
DB_PASSWORD=secret
```
```yaml
# docker-compose.yml
environment:
  - NODE_ENV=${NODE_ENV}
  - PORT=${PORT}
```

### Option 3 — `env_file`
```yaml
env_file:
  - .env
  - .env.production
```

---

## `depends_on` — Service Order

```yaml
services:
  app:
    depends_on:
      - db
      - cache
  db:
    image: postgres:15
  cache:
    image: redis:7
```

> ⚠️ `depends_on` only waits for container **start**, not for the service to be **ready**.  
> Use health checks or tools like `wait-for-it.sh` for full readiness.

---

## Health Checks in Compose

```yaml
services:
  db:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    depends_on:
      db:
        condition: service_healthy     # wait until db is healthy
```

---

## Compose vs Plain Docker Commands

| Task | Docker | Compose |
|------|--------|---------|
| Start app stack | Multiple `docker run` commands | `docker compose up -d` |
| View logs | `docker logs <c>` | `docker compose logs` |
| Stop all | `docker stop c1 c2 c3` | `docker compose down` |
| Exec into service | `docker exec -it <c> bash` | `docker compose exec web bash` |
| Rebuild | `docker build` + `docker run` | `docker compose up --build` |
