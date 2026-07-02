# Docker Revision Guide

## Introduction to Docker  
- Containerization platform for packaging applications and dependencies into lightweight, portable **containers**.  
- Solves “works on my machine” issues by providing consistent **runtime environments** across development, test, and production.  
- Functions as both a **platform** (Docker Engine + orchestration) and a **CLI/SDK toolset** for building, shipping, and running containers.  

Command Syntax  
```bash
docker version
```
Example  
```bash
docker version
```

## Docker Architecture Overview  
- **Docker Engine**: Core runtime composed of **Docker Daemon** (dockerd), **CLI**, and **REST API** for managing images, containers, networks, and volumes.  
- **Container Runtime**: Uses **runc** or other OCI runtimes to create and run containers leveraging **cgroups** and **namespaces**.  
- **Images & Registry**: Read-only **images** stored locally or in a remote **registry** (Docker Hub, private).  
- **Writable Layer**: Each container adds a **Copy-On-Write** (COW) writable layer atop image layers.  
- **Local Components**:  
  - **docker container**: running or stopped instances  
  - **docker image**: immutable filesystem snapshot  
  - **docker volume**: managed persistent storage  
  - **docker network**: virtual networks for container communication  

Command Syntax  
```bash
docker info
```
Example  
```bash
docker info
```

## Docker Container Lifecycle  
- **Create**: `docker create` or `docker run` pulls image, sets up COW layer, network/volumes.  
- **Start**: `docker start` spawns process in container namespace.  
- **Execute**: `docker exec -it <container> bash` enters running container.  
- **Stop**: `docker stop` sends SIGTERM then SIGKILL.  
- **Remove**: `docker rm` deletes container and its writable layer.  

Command Syntax  
```bash
docker run -d --name myapp nginx
```
Example  
```bash
docker run -d --name webserver nginx:latest
```

## Container Runtime, cGroup & Namespace  
- **Namespace**: Kernel feature isolating **PID**, **NET**, **MNT**, **IPC**, **UTS**, and **USER** for process isolation.  
- **cGroup**: Controls and limits resource usage (CPU, memory, I/O) per container.  
- **High-Level Runtimes**: Docker’s built-in **containerd** plus plugin support.  
- **Low-Level Runtimes**: OCI-compliant **runc**, **Kata Containers**, **gVisor**.  

Command Syntax  
```bash
docker run --rm --cpus=".5" ubuntu top
```
Example  
```bash
docker run --rm --memory=256m ubuntu top
```


## Image vs. Container  
- **Image**: Immutable, read-only template with application code, libraries, and metadata.  
- **Container**: Running instance of an image with its own writable layer and isolated namespaces.  
- **Lifecycle**: Image is built once; containers are created, started, stopped, and removed from it.

**Command Syntax**  
```bash
docker images && docker ps -a
```  
**Example**  
```bash
docker pull ubuntu:20.04 && docker run --rm ubuntu:20.04 echo "Hello"
```

## Dockerfile Instructions Flow  
1. **FROM**: Sets base image.  
2. **LABEL**: Metadata.  
3. **ENV**: Environment variables.  
4. **COPY / ADD**: Copy files/archives into image.  
5. **RUN**: Execute build commands.  
6. **WORKDIR**: Set working directory.  
7. **EXPOSE**: Document ports.  
8. **VOLUME**: Declare mount points.  
9. **USER**: Switch user.  
10. **ENTRYPOINT / CMD**: Configure default execution.  

### COPY vs ADD  
- **COPY**: Simple file/dir copy from build context.  
- **ADD**: Also supports remote URLs and auto-extracts tars.  

**Command Syntax**  
```bash
COPY src/ /app/  
ADD config.tar.gz /app/  
```  

### CMD vs ENTRYPOINT  
- **CMD**: Default arguments for `docker run`, overridable.  
- **ENTRYPOINT**: Fixed executable; CMD supplies default params.  

**Command Syntax**  
```bash
ENTRYPOINT ["nginx"]  
CMD ["-g", "daemon off;"]  
```  

### EXPOSE, -p vs. -P  
- **EXPOSE**: Declares port(s) the container listens on (documentation only).  
- **-p**: Maps specific host port to container port (`host:container`).  
- **-P**: Publishes all exposed ports on random host ports.  

**Command Syntax**  
```bash
docker run -d -p 8080:80 nginx  
docker run -d -P nginx  
```  
**Example**  
```bash
docker run -d --name web -p 3000:3000 node:14  
```












## Multistage Docker Build  
- Allows using multiple FROM statements to build intermediate images and copy only necessary artifacts to the final image.  
- Minimizes image size by excluding build dependencies in the final image.  

**Key Benefits:**  
- Smaller, secure production images  
- Clear separation of build and runtime stages  
- Efficient caching and faster builds  

**Command Syntax**  
```dockerfile
FROM node:18 AS build  
WORKDIR /app  
COPY . .  
RUN npm install && npm run build  

FROM nginx:alpine  
COPY --from=build /app/build /usr/share/nginx/html  
```



## Copy-On-Write (COW) Layer Architecture  
- Docker images consist of stacked, immutable **read-only layers** for each Dockerfile instruction.  
- When a container runs, Docker adds a **writable COW layer** on top for runtime file changes.  
- Changes are isolated to that container without modifying the original image layers.  

**Benefits:**  
- Efficient disk usage with shared base layers.  
- Fast container start by layering, not full copy.  
- Container changes non-destructive to image or other containers.  

***

## Docker Networking  
- Containers are connected through virtual networks, enabling isolated communication or external access.  
- Key types:  
  - **Bridge** (default): Private internal network for containers on a host.  
  - **Host**: Container uses host’s network stack directly without network isolation.  
  - **Overlay**: Multi-host container communication for swarm or Kubernetes clusters.  
  - **Macvlan**: Containers get unique MAC addresses on physical network, appearing as physical devices.  
  - **IPvlan**: Similar to Macvlan but manages IP addressing differently for scalability.  

**Real World Use Cases:** Bridge for development, Overlay for swarm apps, Host for performance-critical workloads.  

**Command Syntax**  
```bash
docker network ls  
docker network create --driver bridge mybridge  
```

## Macvlan vs IPvlan (Networking)  
| Feature             | Macvlan                                  | IPvlan                               |
|---------------------|-----------------------------------------|------------------------------------|
| Assigns MAC addresses| Yes, unique MAC per container            | Uses host MAC, differentiates by IP|
| Use case            | Containers appear as physical devices    | Lightweight alternative with less MAC overhead |
| Network compatibility| Requires switch support                   | Easier for some network environments |
| Performance         | High                                     | Comparable or slightly better      |



## Docker Swarm vs Kubernetes  
| Feature             | Docker Swarm                             | Kubernetes                         |
|---------------------|----------------------------------------|----------------------------------|
| Deployment          | Integrated with Docker CLI              | Separate complex system          |
| Orchestration       | Simple, good for small to medium scale | Industry standard, highly scalable|
| Setup               | Easy                                  | More complex                    |
| Community & Support | Moderate                              | Very large, ecosystem rich       |
| Features            | Basic orchestration                    | Advanced scheduling, auto scaling|


## Container IP Addressing  
- Containers get IPs via Docker networking drivers; **bridge** networks use an internal subnet managed by Docker daemon.  
- On creation, Docker daemon or network plugin assigns IP dynamically.  
- Containers in **host** network mode share host’s IP and network stack.  





***

## Docker Storage Types  
- **Docker Volumes**: Managed by Docker, stored in Docker’s internal directories; persistent and portable.  
- **Bind Mounts**: Mounts host directory or file directly into container; useful for development with live code updates.  
- **Tmpfs Mounts**: In-memory temporary storage; data does not persist after container stops.  
- **Ephemeral Storage**: Container’s writable COW layer; lost when container is removed.  

**Command Syntax**  
```bash
docker volume create myvolume  
docker run -v myvolume:/data alpine  
docker run -v /host/path:/container/path alpine  
docker run --tmpfs /tmp alpine  
```  

---

## `--mount` vs `-v` Options  
- `-v`: Older syntax; flexible but less explicit. Can specify volume, bind, or tmpfs.  
- `--mount`: Newer, more expressive; clearly specifies volume type (volume, bind, tmpfs), source, and target paths.  

Use **bind mounts** for development (code sync), **volumes** for persistent data in production.  

**Command Syntax**  
```bash
docker run -v /host/path:/app  
docker run --mount type=bind,source=/host/path,target=/app  
```  

---

## Volume Lifecycle and Behavior  
- Volumes persist beyond the lifecycle of a container.  
- When a container using a volume stops or is removed, data in volume remains intact.  
- Can be reused or manually deleted using `docker volume rm`.  

---

## Best Practices & Security  
- Use **minimal base images** and **multi-stage builds** to reduce attack surface.  
- Run containers as **non-root users** with least privileges.  
- Regularly scan images for vulnerabilities using tools like **Trivy**.  
- Use Docker **Content Trust** and signed images for integrity.  
- Avoid unnecessary privileged flags or **--network=host**.  

---

## Docker Compose  
- Tool to define and run multi-container Docker applications.  
- Uses `docker-compose.yml` to specify services, networks, volumes, and configs.  
- Simplifies orchestration and local dev environment setup.  

**Advantages:**  
- Single command to start/stop multi-container apps.  
- Service dependency management.  
- Environment variables support.  

**Basic Example:**  
```bash
version: "3"
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD: example
```  

**Command Syntax**  
```bash
docker-compose up -d  
docker-compose down
```  
---

## Reasons for Using VMs over Local Machines  
- Strong isolation and security boundary.  
- Ability to run different operating systems.  
- Robust resource management and snapshot/migration support.  
- Useful for legacy apps incompatible with containerization.  

---

## Types of Docker Images  
- **Distroless Images**: Minimal images without package managers or shells for security.  
- **Dangling Images**: Unused images without any tag; created during builds, safe to prune.  
- **Intermediate Images**: Temporary layers during build; cached for future builds.  

---

## 21. Common Docker Commands  

| Command                   | Description                             | Syntax Example                         |
|---------------------------|-------------------------------------|--------------------------------------|
| `docker build`             | Builds an image from a Dockerfile    | `docker build -t myapp .`             |
| `docker run`               | Creates and starts a container       | `docker run -d --name c1 nginx`       |
| `docker ps`                | Lists running containers              | `docker ps -a`                        |
| `docker exec`              | Runs command in running container    | `docker exec -it c1 bash`              |
| `docker attach`            | Attach terminal to container          | `docker attach c1`                    |
| `docker logs`              | Fetches container logs                | `docker logs c1`                      |
| `docker stop`              | Stops running container               | `docker stop c1`                      |
| `docker rm`                | Removes container                     | `docker rm c1`                        |
| `docker rmi`               | Removes image                        | `docker rmi myapp`                    |
| `docker volume create`     | Creates volume                      | `docker volume create myvol`           |
| `docker volume rm`         | Removes volume                      | `docker volume rm myvol`               |
| `docker network create`    | Creates network                    | `docker network create mynet`          |
| `docker network rm`        | Removes network                    | `docker network rm mynet`               |
| `docker image prune`       | Removes unused images              | `docker image prune -a`                 |
| `docker system prune`      | Cleans unused containers, images    | `docker system prune -f`                 |



## Basic Docker Commands  

| Command            | Description                     | Syntax                              |
|--------------------|---------------------------------|-----------------------------------|
| `docker build`     | Build image from Dockerfile      | `docker build -t <image-name> .`  |
| `docker run`       | Create and start container       | `docker run -d --name <name> <image>` |
| `docker ps`        | List running containers          | `docker ps`                       |
| `docker ps -a`     | List all containers (including stopped) | `docker ps -a`                |
| `docker stop`      | Stop a running container         | `docker stop <container>`          |
| `docker rm`        | Remove a container               | `docker rm <container>`            |
| `docker rmi`       | Remove an image                 | `docker rmi <image>`                |
| `docker logs`      | Fetch container logs             | `docker logs <container>`           |
| `docker exec`      | Run command inside container     | `docker exec -it <container> bash` |


## Intermediate Docker Commands  

| Command            | Description                     | Syntax                                |
|--------------------|---------------------------------|-------------------------------------|
| `docker inspect`   | View low-level info on objects    | `docker inspect <container/image>`  |
| `docker commit`    | Create image from container       | `docker commit <container> <image>` |
| `docker pause`     | Pause container processes         | `docker pause <container>`           |
| `docker unpause`   | Resume paused container           | `docker unpause <container>`         |
| `docker rename`    | Rename container                  | `docker rename <old> <new>`          |
| `docker cp`        | Copy files container<>host         | `docker cp <container>:<path> <host_path>` |
| `docker stats`     | Display container resource usage  | `docker stats`                      |


## Docker Networking Commands  

| Command                | Description                 | Syntax                          |
|------------------------|-----------------------------|--------------------------------|
| `docker network ls`    | List Docker networks         | `docker network ls`             |
| `docker network create`| Create a new network         | `docker network create <name>` |
| `docker network inspect`| View network details         | `docker network inspect <name>`|
| `docker network connect`| Connect container to network | `docker network connect <network> <container>` |
| `docker network disconnect`| Disconnect container from network | `docker network disconnect <network> <container>` |
| `docker network rm`    | Remove a network             | `docker network rm <name>`     |


## Docker Volume Commands  

| Command              | Description                   | Syntax                       |
|----------------------|-------------------------------|------------------------------|
| `docker volume ls`   | List volumes                   | `docker volume ls`            |
| `docker volume create`| Create volume                 | `docker volume create <name>`|
| `docker volume inspect`| Inspect volume               | `docker volume inspect <name>`|
| `docker volume rm`   | Remove volume                 | `docker volume rm <name>`     |


## Docker Prune and Cleanup Commands  

| Command                 | Description                        | Syntax                         |
|-------------------------|----------------------------------|--------------------------------|
| `docker system prune`   | Remove unused containers, networks, images | `docker system prune`           |
| `docker image prune`    | Remove unused images               | `docker image prune`            |
| `docker container prune`| Remove stopped containers         | `docker container prune`        |
| `docker volume prune`   | Remove unused volumes             | `docker volume prune`           |
| `docker network prune`  | Remove unused networks            | `docker network prune`          |

## Additional Useful Docker Commands  

| Command                  | Description                         | Syntax                                     |
|--------------------------|-----------------------------------|--------------------------------------------|
| `docker attach`          | Attach your terminal to running container | `docker attach <container>`               |
| `docker diff`            | Inspect changes on container filesystem  | `docker diff <container>`                  |
| `docker export`          | Export container filesystem as tar archive | `docker export -o <file.tar> <container>` |
| `docker import`          | Import a tarball to create an image       | `docker import <file.tar> <image-name>`   |
| `docker pause`           | Pause container processes                   | `docker pause <container>`                 |
| `docker unpause`         | Resume paused container                      | `docker unpause <container>`               |
| `docker top`             | Display processes running in container     | `docker top <container>`                   |
| `docker info`            | Display system-wide information             | `docker info`                              |
| `docker search`          | Search public Docker Hub images             | `docker search <term>`                     |
| `docker login`           | Login to Docker Hub or registry              | `docker login`                             |
| `docker logout`          | Logout from Docker registry                   | `docker logout`                            |
| `docker tag`             | Create tag for an image                      | `docker tag <image> <new-image-name>`     |
| `docker push`            | Push an image to a registry                   | `docker push <image>`                      |

