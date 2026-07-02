# 10 — Docker Swarm vs Kubernetes

## Container Orchestration — Why Needed?

When you run containers at scale, you need:
- **Service discovery** — how do containers find each other?
- **Load balancing** — distribute traffic across replicas
- **Scaling** — add/remove replicas dynamically
- **Self-healing** — restart failed containers automatically
- **Rolling updates** — deploy new versions without downtime

---

## Docker Swarm

Docker's **built-in orchestration** tool — simple and integrated with Docker CLI.

### Key Concepts
| Term | Description |
|------|-------------|
| **Node** | A Docker host in the swarm (Manager or Worker) |
| **Manager Node** | Orchestrates services, maintains cluster state |
| **Worker Node** | Runs containers assigned by Manager |
| **Service** | Desired state definition (image, replicas, ports) |
| **Task** | Single running container (one instance of a service) |
| **Stack** | Group of services deployed from a Compose file |

### Swarm Commands

```bash
# Initialize swarm (makes current node a Manager)
docker swarm init

# Join worker node (run on worker machine)
docker swarm join --token <WORKER_TOKEN> <MANAGER_IP>:2377

# Get join token
docker swarm join-token worker
docker swarm join-token manager

# List nodes in swarm
docker node ls

# Drain node (for maintenance — no new tasks)
docker node update --availability drain <node>

# Reactivate node
docker node update --availability active <node>
```

### Service Management

```bash
# Create a service with 3 replicas
docker service create --name web --replicas 3 -p 80:80 nginx

# List services
docker service ls

# Service details / tasks
docker service ps web

# Scale up/down
docker service scale web=5

# Rolling update (update image)
docker service update --image nginx:alpine web

# Rolling update options
docker service update \
  --image myapp:2.0 \
  --update-parallelism 1 \  # update 1 at a time
  --update-delay 10s \      # wait 10s between each
  web

# Remove service
docker service rm web
```

### Swarm Stacks (Compose for Swarm)

```bash
# Deploy stack from compose file
docker stack deploy -c docker-compose.yml mystack

# List stacks
docker stack ls

# List services in stack
docker stack services mystack

# Remove stack
docker stack rm mystack
```

### Swarm Networking

- Swarm uses **overlay networks** for multi-host container communication.
- Services on the same overlay network can communicate by **service name**.

```bash
docker network create --driver overlay myoverlay
docker service create --network myoverlay --name api myapi
docker service create --network myoverlay --name db  mydb
# 'api' reaches 'db' as: http://db:5432
```

---

## Kubernetes (K8s)

Industry-standard orchestration platform — far more feature-rich and complex.

### Key Concepts

| Term | Description |
|------|-------------|
| **Cluster** | Set of nodes (masters + workers) |
| **Node** | Single machine (VM or physical) |
| **Pod** | Smallest deployable unit — 1+ containers |
| **Deployment** | Manages replicas of Pods, rolling updates |
| **Service** | Stable network endpoint for Pods |
| **Namespace** | Logical isolation within cluster |
| **ConfigMap** | External config (non-sensitive) |
| **Secret** | Sensitive config (passwords, tokens) |
| **Ingress** | HTTP routing into the cluster |
| **PersistentVolume** | Storage claim in cluster |

### Basic kubectl Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl describe pod <pod>
kubectl logs <pod>
kubectl exec -it <pod> -- bash

# Deployments
kubectl get deployments
kubectl create deployment web --image=nginx --replicas=3
kubectl scale deployment web --replicas=5
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web       # rollback

# Apply config from YAML
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml

# Services
kubectl get services
kubectl expose deployment web --port=80 --type=LoadBalancer

# Namespaces
kubectl get namespaces
kubectl create namespace staging
kubectl apply -f app.yaml -n staging
```

### Example K8s Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
  type: LoadBalancer
```

---

## Docker Swarm vs Kubernetes — Comparison

| Feature | Docker Swarm | Kubernetes |
|---------|-------------|------------|
| **Setup complexity** | ✅ Simple — built into Docker | ❌ Steep learning curve |
| **CLI integration** | ✅ Same Docker CLI | Separate `kubectl` |
| **Scalability** | Medium scale | ✅ Large-scale enterprise |
| **Auto-scaling** | ❌ Manual scaling | ✅ HPA (Horizontal Pod Autoscaler) |
| **Rolling updates** | ✅ Built-in | ✅ Built-in |
| **Self-healing** | ✅ Restarts failed tasks | ✅ Advanced health management |
| **Networking** | Overlay networks | CNI plugins (Calico, Flannel) |
| **Storage** | Volumes | PersistentVolume + StorageClass |
| **Load balancing** | Internal VIP | Internal + external Ingress |
| **Secret management** | Basic Docker secrets | Secrets + external integrations |
| **Monitoring** | Limited | ✅ Rich ecosystem (Prometheus, Grafana) |
| **Community & Ecosystem** | Shrinking | ✅ Industry standard |
| **Best for** | Small-medium teams, simple apps | Production, large-scale, enterprise |

---

## When to Use What?

| Scenario | Choose |
|----------|--------|
| Simple multi-host app, small team | **Docker Swarm** |
| Rapid prototype / dev environment | **Docker Swarm** or **Compose** |
| Enterprise, large-scale microservices | **Kubernetes** |
| Need auto-scaling, advanced scheduling | **Kubernetes** |
| Existing Docker workflow, simple migration | **Docker Swarm** |
| Cloud-native apps (AWS EKS, GKE, AKS) | **Kubernetes** |

---

## VM vs Containers (Quick Reference)

| | Virtual Machines | Containers |
|--|-----------------|------------|
| **Isolation** | Full OS isolation | Process-level isolation |
| **Size** | GBs | MBs |
| **Boot time** | Minutes | Seconds |
| **Overhead** | High (hypervisor + full OS) | Low (shared host kernel) |
| **Use case** | Legacy apps, full OS difference needed | Microservices, cloud-native apps |
| **Security** | Stronger boundary | Namespace-based isolation |
