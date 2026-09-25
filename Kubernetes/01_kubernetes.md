# Kubernetes — Interview Revision Sheet

> **Target Role:** Cloud / DevSecOps Engineer (~2 YOE)
> **Focus:** Basic + Intermediate Kubernetes · Troubleshooting · Security · Production Scenarios
> **Total Questions:** 40 (including scenario-based)


# Section 1 — Kubernetes Fundamentals

### Q1. What is Kubernetes and why do we use it? ⭐ MUST KNOW

**Answer:**
Kubernetes (K8s) is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications. It was originally developed by Google and is now maintained by the CNCF.

**Why Kubernetes:**
- Automated rollouts and rollbacks
- Self-healing (restarts failed containers, replaces unhealthy pods)
- Horizontal scaling
- Service discovery and load balancing
- Secret and configuration management
- Works across cloud providers (GKE, AKS, EKS) and on-premises

**Interview Point:**
Kubernetes solves the problem of running containers at scale in production — handling failures, scaling, networking, and deployments that Docker alone cannot manage.

---

### Q2. Explain Kubernetes architecture — Control Plane vs Worker Node ⭐ MUST KNOW

**Answer:**

| Control Plane (Master)         | Worker Node                        |
| ------------------------------ | ---------------------------------- |
| Manages cluster state          | Runs application workloads         |
| API Server — entry point       | kubelet — node agent               |
| etcd — cluster state store     | kube-proxy — networking rules      |
| Scheduler — assigns Pods       | Container Runtime (containerd/CRI) |
| Controller Manager — reconciliation loops | Pods run here          |

**How they interact:**
1. User submits manifest → API Server
2. API Server stores desired state in etcd
3. Scheduler assigns Pod to a Node
4. kubelet on the Node pulls the image and starts the container
5. Controller Manager continuously reconciles desired state vs current state

**Interview Point:**
- **API Server** is the only component that talks to etcd directly.
- **etcd** is a distributed key-value store — losing etcd means losing the cluster state.
- **Scheduler** considers resource requests, affinity rules, taints/tolerations when placing Pods.
- **Controller Manager** runs controllers like Deployment Controller, ReplicaSet Controller, Node Controller.

---

### Q3. What is a Namespace and when do you use it?

**Answer:**
A Namespace is a logical partition within a cluster to isolate resources. It provides scope for names — two resources can have the same name if they are in different namespaces.

**Common use cases:**
- Environment separation (`dev`, `staging`, `production`)
- Team isolation
- Resource quota enforcement per namespace

**Default namespaces:** `default`, `kube-system`, `kube-public`, `kube-node-lease`

```bash
kubectl get namespaces
kubectl get pods -n kube-system
```

**Interview Point:**
Not all resources are namespaced. Nodes, PersistentVolumes, ClusterRoles are cluster-scoped.

---

### Q4. What are Labels and Selectors?

**Answer:**
**Labels** are key-value pairs attached to Kubernetes objects for identification.
**Selectors** are used to filter/select objects based on their labels.

```yaml
# Label
metadata:
  labels:
    app: payment-service
    env: production

# Selector (in a Service)
selector:
  app: payment-service
```

**Interview Point:**
Services use selectors to discover Pods. If labels on Pods do not match the Service selector, traffic will not reach the Pods — this is a very common troubleshooting scenario.

---
### Q5. Declarative vs Imperative approach ⭐ MUST KNOW

**Answer:**

| Imperative                            | Declarative                            |
| ------------------------------------- | -------------------------------------- |
| `kubectl run nginx --image=nginx`     | `kubectl apply -f deployment.yaml`     |
| Direct commands                       | YAML manifests                         |
| Good for quick tasks                  | Production standard                    |
| No version history                    | Version controlled (GitOps)            |
| Hard to reproduce                     | Reproducible and auditable             |

**Interview Point:**
In production and DevSecOps workflows, always use the **declarative** approach. Manifests should be stored in Git and deployed via CI/CD pipelines. `kubectl apply` is declarative; `kubectl create` is imperative.


# Section 2 — Kubernetes Workloads


### Q6. What is a Pod and what is a Deployment? ⭐ MUST KNOW

**Answer:**
A **Pod** is the smallest deployable unit in Kubernetes. It contains one or more containers that share networking (same IP) and storage (shared volumes).

A **Deployment** is a higher-level object that manages Pods via ReplicaSets. It provides:
- Desired replica count
- Rolling updates and rollbacks
- Self-healing (recreates failed Pods)

```bash
kubectl get pods
kubectl get deployments
kubectl rollout status deployment/my-app
kubectl rollout undo deployment/my-app
```

**Interview Point:**
You almost never create Pods directly in production. You create Deployments, which create ReplicaSets, which create Pods.

---

### Q7. Deployment vs StatefulSet vs DaemonSet vs Statci Pod (etcd) ⭐ MUST KNOW

**Answer:**

| Deployment                  | StatefulSet                  | DaemonSet                       |
| --------------------------- | ---------------------------- | ------------------------------- |
| Stateless workloads         | Stateful workloads           | One Pod per Node                |
| Pods are interchangeable    | Stable network identity      | Runs on every (or selected) Node|
| Random Pod names            | Ordered names (app-0, app-1) | Use case: log agents, monitoring|
| Shared storage (optional)   | Per-Pod persistent storage   | Automatically added to new Nodes|
| Rolling update default      | Ordered rolling update       | Rolling update                  |
| Example: web API, frontend  | Example: databases, Kafka    | Example: Fluentd, Datadog agent |

**Interview Point:**
- StatefulSet Pods have **stable DNS names** (`pod-0.service.namespace.svc.cluster.local`) and **persistent volume per Pod**.
- DaemonSet ensures exactly one Pod copy runs on every qualifying Node — essential for cluster-level agents.
- `kube-proxy` runs as a DaemonSet, meaning Kubernetes automatically ensures one copy runs on every designated node.
- **Static Pods** - managed directly by the kubelet from manifests (`/etc/kubernetes/manifests`) on the node, rather than by the API server/scheduler. 
- Components like `etcd`, `kube-apiserver`, `kube-controller-manager`,& `kube-scheduler` are indeed - Static Pods.
- CoreDNS is normally a regular Deployment, not a static Pod.


---

### Q8. What are Init Containers and Sidecar Containers?

**Answer:**
**Init Containers** run before the main application container starts. They must complete successfully before the app container begins. Used for setup tasks like waiting for a dependency, populating shared volumes, or running migrations.

**Sidecar Containers** run alongside the main container in the same Pod for the entire Pod lifecycle. Used for logging, proxying (Envoy/Istio), or monitoring.

```yaml
initContainers:
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nc -z db-service 5432; do sleep 2; done']
```

**Interview Point:**
From Kubernetes 1.28+, there is native sidecar support via `restartPolicy: Always` on init containers, so they run for the full Pod lifecycle.

---

### Q9. What are Jobs and CronJobs?

**Answer:**
A **Job** creates one or more Pods and ensures they run to successful completion. Used for batch processing, data migration, backups.

A **CronJob** creates Jobs on a recurring schedule (cron syntax).

```yaml
# CronJob — runs every day at 2 AM
schedule: "0 2 * * *"
```

```bash
kubectl get jobs
kubectl get cronjobs
```

**Interview Point:**
- Jobs have `backoffLimit` (retry count) and `activeDeadlineSeconds` (timeout).
- CronJobs have `concurrencyPolicy` — `Allow`, `Forbid`, or `Replace`.

# Section 3 — kubectl Commands

### Q10. What are the most important kubectl commands for production support? ⭐ MUST KNOW

**Answer:**

**Inspection & Debugging:**
```bash
kubectl get pods -n <namespace>              # List pods
kubectl get pods -A                           # All namespaces
kubectl get pods -o wide                      # Show node, IP
kubectl describe pod <pod> -n <ns>            # Detailed info + events
kubectl logs <pod> -n <ns>                    # Container logs
kubectl logs <pod> -c <container> -n <ns>     # Specific container logs
kubectl logs <pod> -f                         # Follow/stream logs
kubectl logs <pod> --previous                 # Previous crashed container logs
kubectl exec -it <pod> -- /bin/sh             # Shell into container
kubectl get events -n <ns> --sort-by='.lastTimestamp'  # Recent events
```

**Deployment & Management:**
```bash
kubectl apply -f manifest.yaml                # Apply config
kubectl delete -f manifest.yaml               # Delete resources
kubectl rollout status deployment/<name>      # Check rollout
kubectl rollout history deployment/<name>     # Rollout history
kubectl rollout undo deployment/<name>        # Rollback
kubectl scale deployment/<name> --replicas=5  # Scale
```

**Cluster & Networking:**
```bash
kubectl get nodes                             # Node list
kubectl describe node <node>                  # Node details
kubectl get svc -n <ns>                       # Services
kubectl get ingress -n <ns>                   # Ingress rules
kubectl get pvc -n <ns>                       # Persistent Volume Claims
kubectl top pods -n <ns>                      # Resource usage
kubectl top nodes                             # Node resource usage
```

**Interview Point:**
`kubectl describe` and `kubectl get events` are your first tools during troubleshooting. Always check the **Events** section at the bottom of `describe` output.

# Section 4 — Services & Kubernetes Networking

### Q11. ClusterIP vs NodePort vs LoadBalancer ⭐ MUST KNOW

**Answer:**

| Type         | Accessible From        | Port Exposure            | Use Case                        |
| ------------ | ---------------------- | ------------------------ | ------------------------------- |
| ClusterIP    | Inside cluster only    | Cluster-internal IP      | Internal service-to-service     |
| NodePort     | Outside via Node IP    | Static port (30000-32767)| Dev/testing, direct node access |
| LoadBalancer | External via cloud LB  | Cloud provider LB        | Production external traffic     |

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer    # or ClusterIP / NodePort
  selector:
    app: my-app
  ports:
    - port: 80          # Service port
      targetPort: 8080  # Container port
```

**Interview Point:**
- `LoadBalancer` creates an actual cloud load balancer (costs money on GKE/AKS).
- In production, prefer **Ingress** over multiple LoadBalancer services to save cost and centralize routing.
- `ClusterIP` is the default Service type.

---

### Q12. What is an Ingress and an Ingress Controller?

**Answer:**
**Ingress** is a Kubernetes resource that defines HTTP/HTTPS routing rules (host-based, path-based) to backend Services.

**Ingress Controller** is the actual component (e.g., NGINX Ingress Controller, Traefik, GKE Ingress) that implements the rules defined in the Ingress resource. Without an Ingress Controller, Ingress resources do nothing.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

**Interview Point:**
Ingress provides a single entry point (single LoadBalancer) for multiple services — cost-effective in cloud environments.

---

### Q13. How does Pod-to-Pod and Service-to-Pod communication work?

**Answer:**
- **Pod-to-Pod:** Every Pod gets a unique IP. Pods can communicate directly using Pod IPs across Nodes (flat network — no NAT). The CNI plugin (Calico, Cilium, Azure CNI, GKE VPC-native) handles this.
- **Service-to-Pod:** A Service provides a stable virtual IP (ClusterIP). kube-proxy programs iptables/IPVS rules to route traffic from the Service IP to healthy Pod IPs behind it.
- **DNS:** Kubernetes runs CoreDNS. Services are accessible at `<service>.<namespace>.svc.cluster.local`.

```bash
# From inside a Pod
curl http://payment-service.production.svc.cluster.local:8080
```

**Interview Point:**
If a Service is not reaching Pods, check: (1) label/selector mismatch, (2) no Endpoints (`kubectl get endpoints <svc>`), (3) Pod readiness probe failing.

---

### Q14. What is a NetworkPolicy?

**Answer:**
A NetworkPolicy controls traffic flow at the Pod level — which Pods can talk to which Pods. By default, all Pods can communicate with all other Pods. NetworkPolicy restricts this.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

**Interview Point:**
- NetworkPolicy requires a CNI that supports it (Calico, Cilium — yes; Flannel — no).
- In a DevSecOps context, use default-deny policies and explicitly allow required traffic.
- On GKE, you must enable network policy support on the cluster. AKS supports it with Azure CNI + Calico.


# Section 5 — ConfigMap & Secrets

### Q15. ConfigMap vs Secret ⭐ MUST KNOW

**Answer:**

| ConfigMap                           | Secret                                  |
| ----------------------------------- | --------------------------------------- |
| Non-sensitive configuration         | Sensitive data (passwords, tokens, keys)|
| Stored as plain text in etcd        | Stored as base64-encoded in etcd        |
| Mounted as env vars or volumes      | Mounted as env vars or volumes          |
| No encryption by default            | Not encrypted by default (only encoded) |

```bash
kubectl create configmap app-config --from-literal=ENV=production
kubectl create secret generic db-creds --from-literal=password=s3cret
```

**Ways to consume:**
1. Environment variable
2. Volume mount (files)
3. Command-line arguments

**Interview Point (DevSecOps):**
- Kubernetes Secrets are only **base64-encoded, NOT encrypted** by default.
- Enable **encryption at rest** for etcd in production.
- For HDFC/banking workloads, use external secret managers: **HashiCorp Vault**, **Azure Key Vault** (with AKS), **GCP Secret Manager** (with GKE), or the **External Secrets Operator**.
- Avoid hardcoding secrets in YAML files stored in Git.

---

### Q16. How do you manage secrets securely in Kubernetes for production?

**Answer:**
1. **Enable etcd encryption at rest** — encrypts Secrets in etcd storage
2. **Use external secret managers** — Vault, Azure Key Vault, GCP Secret Manager
3. **Use External Secrets Operator or Sealed Secrets** — syncs external secrets into K8s
4. **RBAC** — restrict who can `get`/`list` secrets
5. **Avoid env vars for large secrets** — prefer volume mounts (env vars appear in logs, `describe` output)
6. **Rotate secrets regularly**
7. **Audit access** — enable audit logging for secret access

**Interview Point:**
In a banking/financial services context, secrets management is critical. Always mention external secret management and encryption at rest.

# Section 6 — Storage

### Q17. PV vs PVC vs StorageClass ⭐ MUST KNOW

**Answer:**

| Concept       | What It Is                                         | Who Creates It     |
| ------------- | -------------------------------------------------- | ------------------- |
| PV            | A piece of storage provisioned in the cluster      | Admin (or dynamic)  |
| PVC           | A request for storage by a Pod                     | Developer / manifest|
| StorageClass  | Defines the type/class of storage (SSD, HDD, etc.) | Admin               |

**Flow:**
1. Admin creates a StorageClass (e.g., `premium-ssd`)
2. Developer creates a PVC requesting storage from that class
3. StorageClass dynamically provisions a PV
4. Pod mounts the PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: premium-ssd
  resources:
    requests:
      storage: 10Gi
```

**Access Modes:**
- `ReadWriteOnce (RWO)` — single node read-write
- `ReadOnlyMany (ROX)` — multiple nodes read-only
- `ReadWriteMany (RWX)` — multiple nodes read-write

**Interview Point:**
- **Dynamic provisioning** (via StorageClass) is the standard in cloud (GKE, AKS).
- If a PVC is stuck in `Pending`, check: StorageClass exists, quota not exceeded, access mode supported.

# Section 7 — Scheduling & Resources

### Q18. Requests vs Limits ⭐ MUST KNOW

**Answer:**

| Requests                                 | Limits                                    |
| ---------------------------------------- | ----------------------------------------- |
| Minimum guaranteed resources             | Maximum allowed resources                 |
| Used by Scheduler for Pod placement      | Enforced by kubelet at runtime            |
| Pod won't be scheduled without resources | Pod is throttled (CPU) or killed (memory) |

```yaml
resources:
  requests:
    cpu: "250m"        # 0.25 CPU core
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

**QoS Classes:**
- **Guaranteed** — requests == limits for all containers
- **Burstable** — requests < limits (at least one set)
- **BestEffort** — no requests or limits set (first to be evicted)

**Interview Point:**
- Always set requests and limits in production.
- OOMKilled = container exceeded memory **limit**.
- CPU throttling = container hitting CPU **limit**.
- BestEffort Pods are evicted first under node pressure.

---

### Q19. Taints, Tolerations, and Node Affinity

**Answer:**
**Taints** are applied to Nodes to repel Pods.
**Tolerations** are applied to Pods to allow scheduling on tainted Nodes.
**Node Affinity** attracts Pods to specific Nodes based on node labels.

```bash
# Taint a node
kubectl taint nodes node1 env=production:NoSchedule

# Toleration in Pod spec
tolerations:
  - key: "env"
    operator: "Equal"
    value: "production"
    effect: "NoSchedule"

# Node Affinity
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: disktype
              operator: In
              values: [ "ssd" ]
```

**Interview Point:**
- Taints **repel**, Affinity **attracts**.
- Taint effects: `NoSchedule`, `PreferNoSchedule`, `NoExecute`.
- Use case: Dedicate nodes for specific workloads (GPU nodes, production-only nodes).

---

### Q20. What is a PodDisruptionBudget (PDB)?

**Answer:**
A PDB limits how many Pods of a workload can be unavailable during **voluntary disruptions** (node drain, cluster upgrade, scaling down).

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2       # OR maxUnavailable: 1
  selector:
    matchLabels:
      app: payment-service
```

**Interview Point:**
PDBs are critical for production workloads. During AKS/GKE node pool upgrades, PDBs prevent Kubernetes from draining too many Pods at once, ensuring availability.

# Section 8 — Health Checks

### Q21. Liveness vs Readiness vs Startup Probe ⭐ MUST KNOW

**Answer:**

| Probe      | Purpose                                  | On Failure                          |
| ---------- | ---------------------------------------- | ----------------------------------- |
| Liveness   | Is the container alive/healthy?          | Container is **restarted**          |
| Readiness  | Is the container ready to serve traffic? | Pod removed from **Service endpoints** |
| Startup    | Has the container finished starting?     | Container is **restarted** (after timeout) |

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**Interview Point:**
- Use **startup probe** for slow-starting applications (Java, .NET) to prevent liveness probe from killing the container during startup.
- A failing **readiness** probe means the Pod is alive but not receiving traffic — useful during deployments and dependency waits.
- A failing **liveness** probe triggers a container restart — be careful not to set it too aggressive.

# Section 9 — Kubernetes Troubleshooting

### Q22. Pod stuck in Pending ⭐ MUST KNOW

**Question:** A Pod is stuck in `Pending` status. How do you troubleshoot?

**Likely causes:**
- Insufficient CPU/memory on nodes (requests cannot be satisfied)
- No nodes match nodeSelector, affinity, or tolerations
- PVC bound to a non-existent StorageClass
- Resource quota exceeded in the namespace
- Too many Pods on the node (max pods limit)

**Troubleshooting approach:**
```bash
# 1. Check pod status and events
kubectl describe pod <pod-name> -n <ns>
# Look at Events section — Scheduler messages

# 2. Check node resources
kubectl describe node <node-name>
kubectl top nodes

# 3. Check resource quotas
kubectl get resourcequota -n <ns>

# 4. Check PVC status (if using storage)
kubectl get pvc -n <ns>
```

**Expected observations:** Events section will show `FailedScheduling` with a reason like `Insufficient cpu`, `Insufficient memory`, or `no nodes match`.

---

### Q23. Pod in CrashLoopBackOff

**Question:** A Pod is in `CrashLoopBackOff`. How do you troubleshoot?

**Likely causes:**
- Application error / crash on startup
- Missing configuration (env vars, config files, secrets)
- Incorrect command or entrypoint
- Dependency unavailable (database, external service)
- OOMKilled (memory limit too low)
- Permission issues

**Troubleshooting approach:**
```bash
# 1. Check pod status
kubectl get pod <pod> -n <ns>

# 2. Check events
kubectl describe pod <pod> -n <ns>

# 3. Check current logs
kubectl logs <pod> -n <ns>

# 4. Check previous container logs (crashed container)
kubectl logs <pod> -n <ns> --previous

# 5. Check if OOMKilled
kubectl describe pod <pod> -n <ns> | grep -i oom

# 6. Check env vars and mounted secrets/configmaps
kubectl describe pod <pod> -n <ns>
```

**Expected observations:** Logs will show the application error. `Last State: Terminated` with `Reason: OOMKilled` or `Reason: Error` with an exit code.

---

### Q24. ImagePullBackOff / ErrImagePull

**Question:** A Pod shows `ImagePullBackOff`. How do you fix it?

**Likely causes:**
- Image name or tag is incorrect
- Image does not exist in the registry
- Missing or incorrect `imagePullSecrets` (private registry)
- Registry is unreachable (network/firewall)
- Docker Hub rate limiting

**Troubleshooting approach:**
```bash
# 1. Describe the pod — check Events
kubectl describe pod <pod> -n <ns>

# 2. Verify image name and tag
# 3. Check imagePullSecrets
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.imagePullSecrets}'

# 4. Test pulling the image manually (on node or locally)
docker pull <image>:<tag>
```

**Expected observations:** Events will show `Failed to pull image` with the specific error (authentication, not found, timeout).

---

### Q25. Service not reaching Pods

**Question:** A Service is created but traffic is not reaching the Pods. How do you troubleshoot?

**Likely causes:**
- Label/selector mismatch between Service and Pods
- No endpoints (Pods not ready or not matching)
- Readiness probe failing on Pods
- Wrong `targetPort` in Service spec
- NetworkPolicy blocking traffic

**Troubleshooting approach:**
```bash
# 1. Check service and its selector
kubectl describe svc <svc-name> -n <ns>

# 2. Check if endpoints exist
kubectl get endpoints <svc-name> -n <ns>

# 3. Check pod labels
kubectl get pods -n <ns> --show-labels

# 4. Check readiness of pods
kubectl get pods -n <ns>

# 5. Check network policies
kubectl get networkpolicy -n <ns>

# 6. Test connectivity from another pod
kubectl exec -it <test-pod> -- curl <svc-name>:<port>
```

**Expected observations:** Empty endpoints list indicates selector mismatch or Pods not ready.

# Section 10 — Kubernetes Security

### Q26. What is RBAC in Kubernetes? ⭐ MUST KNOW

**Answer:**
RBAC (Role-Based Access Control) controls who can do what in the cluster.

**Four key objects:**

| Object             | Scope     | Purpose                                  |
| ------------------- | --------- | ---------------------------------------- |
| Role                | Namespace | Defines permissions in a namespace       |
| ClusterRole         | Cluster   | Defines permissions cluster-wide         |
| RoleBinding         | Namespace | Binds a Role to a user/group/SA          |
| ClusterRoleBinding  | Cluster   | Binds a ClusterRole to a user/group/SA   |

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Interview Point:**
Follow the principle of **least privilege** — grant only the permissions required. In banking environments, RBAC must be tightly configured.

---

### Q27. What is a ServiceAccount and why is it important?

**Answer:**
A ServiceAccount provides an identity for Pods to interact with the Kubernetes API. Each namespace has a `default` ServiceAccount.

**Security best practices:**
- Create dedicated ServiceAccounts per application
- Do not use the `default` ServiceAccount in production
- Disable automatic token mounting if API access is not needed: `automountServiceAccountToken: false`
- Bind minimal RBAC permissions to each ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-app-sa
  namespace: production
```

**Interview Point:**
On GKE, use **Workload Identity** to map K8s ServiceAccounts to GCP IAM ServiceAccounts. On AKS, use **Workload Identity Federation** (formerly Pod Identity).

---

### Q28. Kubernetes Security Best Practices (DevSecOps) ⭐ MUST KNOW

**Answer:**

1. **Run containers as non-root:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

2. **Use NetworkPolicies** — default-deny, then allow required traffic
3. **Enable RBAC** — least privilege for users and ServiceAccounts
4. **Scan container images** — use tools like Trivy, Snyk, or cloud-native scanners
5. **Use trusted base images** — minimal images (distroless, Alpine)
6. **Encrypt Secrets at rest** in etcd
7. **Use external secret management** (Vault, Azure Key Vault, GCP Secret Manager)
8. **Enable audit logging** — track who accessed what
9. **Apply Pod Security Standards** (Restricted, Baseline, Privileged)
10. **Keep Kubernetes version updated** — apply security patches
11. **Use private container registries** with vulnerability scanning

**Interview Point:**
For a banking client, emphasize: encryption at rest, RBAC, network segmentation via NetworkPolicies, image scanning in CI/CD, and compliance with security baselines.

# Section 11 — Helm

### Q29. What is Helm and why do we use it?

**Answer:**
Helm is a package manager for Kubernetes. A **Helm chart** is a collection of templated Kubernetes manifests that can be deployed as a single unit.

**Why Helm:**
- Templatize manifests (reuse across environments)
- Manage releases (install, upgrade, rollback)
- Version control deployments
- Share via Helm repositories

**Chart structure:**
```
my-chart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── templates/          # Templated K8s manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── charts/             # Sub-chart dependencies
```

---

### Q30. Helm install, upgrade, rollback — how do they work?

**Answer:**
```bash
# Install a release
helm install my-release ./my-chart -f production-values.yaml

# Upgrade a release
helm upgrade my-release ./my-chart -f production-values.yaml

# Rollback to previous revision
helm rollback my-release 1

# List releases
helm list -n <namespace>

# Check release history
helm history my-release

# Uninstall
helm uninstall my-release
```

**How values are overridden:**
```
Default values.yaml → -f custom-values.yaml → --set key=value
```
Each layer overrides the previous. `--set` has the highest priority.

**Interview Point:**
Helm maintains a **release history** in Kubernetes Secrets (by default), allowing rollback. In CI/CD pipelines, `helm upgrade --install` is commonly used — it installs if the release doesn't exist, or upgrades if it does.

---

# Section 12 — Scenario-Based Questions

---

### Q31. Scenario — Pod in CrashLoopBackOff

**Problem:** A Pod is repeatedly crashing and showing `CrashLoopBackOff`.

**Likely causes:**
- Application startup failure (missing config, wrong command, dependency down)
- OOMKilled (insufficient memory limit)
- File/permission errors inside the container
- Liveness probe misconfiguration (killing container too early)

**Troubleshooting steps:**
1. `kubectl get pod <pod> -n <ns>` — check restart count and status
2. `kubectl describe pod <pod> -n <ns>` — check Events and Last State
3. `kubectl logs <pod> -n <ns> --previous` — check crashed container logs
4. Look for `OOMKilled` in Last State reason
5. Check if liveness probe `initialDelaySeconds` is too short
6. Verify ConfigMaps, Secrets, and env vars are correctly mounted

**Commands to use:**
```bash
kubectl get pod <pod> -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl get events -n <ns> --sort-by='.lastTimestamp'
```

**Expected observations:** Logs show the application error or `OOMKilled` in terminated state.

---

### Q32. Scenario — Deployment successful but users cannot access the application

**Problem:** Deployment is running, Pods are healthy, but users get no response.

**Likely causes:**
- Service not created or wrong type (ClusterIP instead of LoadBalancer)
- Service selector doesn't match Pod labels
- Ingress misconfiguration
- DNS not pointing to the LoadBalancer/Ingress IP
- Application listening on wrong port
- NetworkPolicy blocking external traffic

**Troubleshooting steps:**
1. `kubectl get svc -n <ns>` — verify Service exists and has correct type
2. `kubectl get endpoints <svc> -n <ns>` — verify Pods are in endpoints
3. `kubectl get ingress -n <ns>` — check Ingress rules and host
4. Verify external DNS resolves to the correct IP
5. Test internally: `kubectl exec -it <pod> -- curl localhost:<port>`
6. Check cloud LB health checks (GKE/AKS console)

**Commands to use:**
```bash
kubectl get svc -n <ns>
kubectl get endpoints <svc> -n <ns>
kubectl get ingress -n <ns>
kubectl describe ingress <ingress> -n <ns>
kubectl exec -it <pod> -- curl localhost:8080
```

**Expected observations:** Empty endpoints, wrong ingress host, or Service type mismatch.

---

### Q33. Scenario — Service exists but not forwarding traffic to Pods

**Problem:** Service is created but `kubectl get endpoints` shows no endpoints.

**Likely causes:**
- Label mismatch between Service `selector` and Pod `labels`
- All Pods are failing readiness probes
- Pods are in a different namespace than the Service
- Pods are not running

**Troubleshooting steps:**
1. Compare Service selector with Pod labels
2. Check Pod readiness status
3. Check readiness probe configuration
4. Verify namespace alignment

**Commands to use:**
```bash
kubectl describe svc <svc> -n <ns>         # Check selector
kubectl get pods -n <ns> --show-labels      # Check pod labels
kubectl get endpoints <svc> -n <ns>         # Check endpoints
kubectl describe pod <pod> -n <ns>          # Check readiness
```

**Expected observations:** Selector labels don't match Pod labels, or all Pods show `0/1 Ready`.

---

### Q34. Scenario — Pod stuck in Pending

**Problem:** Pod has been in `Pending` for several minutes.

**Likely causes:**
- Cluster has no node with enough CPU/memory to satisfy requests
- nodeSelector or affinity rules match no available node
- Taint on all nodes with no matching toleration on the Pod
- PVC not bound (waiting for storage)
- Namespace resource quota exhausted

**Troubleshooting steps:**
1. `kubectl describe pod <pod>` — check Scheduler events
2. Check node capacity and allocatable resources
3. Check if PVC is bound
4. Check resource quotas

**Commands to use:**
```bash
kubectl describe pod <pod> -n <ns>
kubectl get nodes
kubectl describe node <node>
kubectl top nodes
kubectl get pvc -n <ns>
kubectl get resourcequota -n <ns>
```

**Expected observations:** Events show `FailedScheduling` with the specific constraint that could not be met.

---

### Q35. Scenario — ImagePullBackOff

**Problem:** Pod shows `ImagePullBackOff` and never starts.

**Likely causes:**
- Wrong image name or tag (typo, tag doesn't exist)
- Private registry without `imagePullSecrets`
- Registry credentials expired
- Network connectivity issue to registry
- Docker Hub rate limit exceeded

**Troubleshooting steps:**
1. `kubectl describe pod` — read the exact error in Events
2. Verify image name and tag exist in the registry
3. Check `imagePullSecrets` on the Pod or ServiceAccount
4. Test pulling the image from a machine with registry access

**Commands to use:**
```bash
kubectl describe pod <pod> -n <ns>
kubectl get pod <pod> -o yaml | grep image
kubectl get secrets -n <ns>
```

**Expected observations:** Events show `Failed to pull image` — authentication required, image not found, or connection timeout.

---

### Q36. Scenario — Node becomes NotReady

**Problem:** A node shows `NotReady` in `kubectl get nodes`.

**Likely causes:**
- kubelet stopped or crashed on the node
- Node ran out of disk, memory, or PIDs (node pressure)
- Network issue between node and control plane
- Container runtime (containerd) failed
- Cloud provider issue (VM stopped, spot instance preempted)

**Troubleshooting steps:**
1. `kubectl describe node <node>` — check Conditions section
2. SSH into the node and check kubelet status
3. Check container runtime status
4. Check system resources (disk, memory)
5. Check cloud provider console for VM status

**Commands to use:**
```bash
kubectl get nodes
kubectl describe node <node>
# On the node:
systemctl status kubelet
journalctl -u kubelet --no-pager -n 100
df -h
free -m
```

**Expected observations:** Node Conditions show `MemoryPressure`, `DiskPressure`, or `KubeletNotReady`. kubelet logs show the root cause.

---

### Q37. Scenario — Pods getting OOMKilled

**Problem:** Pods are repeatedly restarted with reason `OOMKilled`.

**Likely causes:**
- Memory limit set too low for the application
- Application has a memory leak
- JVM heap not configured properly (Java apps)
- Too many connections/threads consuming memory

**Troubleshooting steps:**
1. Confirm OOMKilled in pod description
2. Check current memory usage
3. Review memory limits in the deployment
4. Analyze application memory consumption patterns
5. Increase memory limit or fix the application

**Commands to use:**
```bash
kubectl describe pod <pod> -n <ns> | grep -A5 "Last State"
kubectl top pod <pod> -n <ns>
kubectl get pod <pod> -o yaml | grep -A5 resources
```

**Expected observations:** `Last State: Terminated, Reason: OOMKilled, Exit Code: 137`. Pod memory usage consistently near the limit.

---

### Q38. Scenario — PVC stuck in Pending

**Problem:** A PersistentVolumeClaim stays in `Pending` status.

**Likely causes:**
- StorageClass does not exist or name is misspelled
- No available PersistentVolume matches (static provisioning)
- Dynamic provisioner is not installed or failing
- Requested access mode not supported by the storage backend
- Quota exceeded for storage

**Troubleshooting steps:**
1. `kubectl describe pvc <pvc>` — check Events
2. Verify StorageClass exists
3. Check cloud provisioner logs (CSI driver pods in `kube-system`)
4. Check storage quotas

**Commands to use:**
```bash
kubectl get pvc -n <ns>
kubectl describe pvc <pvc> -n <ns>
kubectl get storageclass
kubectl get events -n <ns> --sort-by='.lastTimestamp'
```

**Expected observations:** Events show `ProvisioningFailed` or `no persistent volumes available`. Missing or incorrect StorageClass name.

---

### Q39. Scenario — Ingress returns 502 Bad Gateway

**Problem:** Users see a 502 error when accessing the application through Ingress.

**Likely causes:**
- Backend Pods are not ready or not running
- Service port or targetPort misconfigured
- Readiness probe failing (Pods removed from endpoints)
- Ingress backend service name or port incorrect
- Application is taking too long to respond (timeout)
- Health check endpoint returning errors

**Troubleshooting steps:**
1. Check if Pods are running and ready
2. Check Ingress configuration (backend service name, port)
3. Check Service endpoints
4. Test the application directly (port-forward or exec)
5. Check Ingress Controller logs

**Commands to use:**
```bash
kubectl get pods -n <ns>
kubectl get endpoints <svc> -n <ns>
kubectl describe ingress <ingress> -n <ns>
kubectl port-forward svc/<svc> 8080:80 -n <ns>
kubectl logs -n <ingress-ns> <ingress-controller-pod>
```

**Expected observations:** No healthy endpoints, Service name mismatch in Ingress, or application returning 5xx errors.

---

### Q40. Scenario — One microservice cannot communicate with another

**Problem:** Service A cannot reach Service B within the cluster.

**Likely causes:**
- Service B does not exist or is in a different namespace (wrong DNS name)
- NetworkPolicy blocking inter-namespace or inter-pod traffic
- Service B's Pods are not ready
- DNS resolution failure (CoreDNS issue)
- Application using wrong port

**Troubleshooting steps:**
1. Verify Service B exists and has endpoints
2. Test DNS resolution from Service A's Pod
3. Test connectivity with curl/wget from Service A's Pod
4. Check NetworkPolicies in both namespaces
5. Check CoreDNS Pods are running

**Commands to use:**
```bash
# From inside Service A's pod
kubectl exec -it <pod-a> -- nslookup service-b.namespace-b.svc.cluster.local
kubectl exec -it <pod-a> -- curl http://service-b.namespace-b.svc.cluster.local:8080

# Check network policies
kubectl get networkpolicy -n <ns-a>
kubectl get networkpolicy -n <ns-b>

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system <coredns-pod>
```

**Expected observations:** DNS resolution fails (CoreDNS issue), connection refused (Pod not listening), or connection timeout (NetworkPolicy blocking).

---

# ⭐ Must-Remember Before Interview

> **Revise these 15 items immediately before your interview:**

| # | Concept / Command / Pattern |
|---|----------------------------|
| 1 | **K8s Architecture** — API Server, etcd, Scheduler, Controller Manager, kubelet, kube-proxy |
| 2 | **Pod → ReplicaSet → Deployment** relationship |
| 3 | **Deployment vs StatefulSet vs DaemonSet (kube proxy) vs Static Pods (etcd)** — when to use each |
| 4 | **ClusterIP vs NodePort vs LoadBalancer** — differences and use cases |
| 5 | **Ingress + Ingress Controller** — why and how |
| 6 | **Requests vs Limits** — scheduling, throttling, OOMKill |
| 7 | **Liveness vs Readiness vs Startup Probe** — what happens on failure |
| 8 | **RBAC** — Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount |
| 9 | **ConfigMap vs Secret** — base64 is not encryption, use Vault / Key Vault in production |
| 10 | **Security Context** — `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false` |
| 11 | **`kubectl describe pod`** — always check Events section first |
| 12 | **`kubectl logs --previous`** — view logs of a crashed container |
| 13 | **CrashLoopBackOff** — check logs → check OOMKilled → check probes → check config |
| 14 | **Pending Pod** — check events → Scheduler → node resources → PVC → quotas |
| 15 | **Labels & Selectors** — Service not reaching Pods = selector mismatch = empty endpoints |

---

*Revision sheet prepared for Cloud/DevSecOps Engineer interview. Focus on practical answers and troubleshooting over theory.*
