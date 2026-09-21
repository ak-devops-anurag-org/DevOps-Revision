# Kubernetes Architecture & Workloads — Interview Revision

> Focused revision notes for Cloud/DevOps engineer interviews.
> Covers: Cluster architecture, control plane, worker nodes, workload types.

## Part 1: Kubernetes Architecture

### Q1. What is a Kubernetes cluster? 🟠 IMPORTANT

**Answer:**
A Kubernetes cluster is a set of nodes (machines) running containerized applications. It consists of a Control Plane that manages the cluster state, and Worker Nodes that run the actual application workloads.

**How it works:**
The Control Plane exposes an API and schedules workloads, while the Worker Nodes execute those workloads using a container runtime. 

**Interview point:**
Emphasize the separation of concerns: Control Plane manages *state*, Worker Nodes run *compute*.

---

### Q2. What are the Control Plane components and their roles? ⭐ MUST KNOW

**Answer:**
The Control Plane includes four main components: API Server (gateway), etcd (data store), Scheduler (workload placement), and Controller Manager (state maintenance).

**How it works:**
They work together to monitor the cluster, detect drift from the desired state, and take actions to reconcile it without running actual application containers.

**Interview point:**
If asked "what happens if the control plane goes down?", state that existing workloads continue running, but you cannot make changes, deploy new pods, or auto-heal failures.

---

### Q3. What are the components of a Worker Node? ⭐ MUST KNOW

**Answer:**
A Worker Node contains three main components: kubelet (node agent), kube-proxy (networking), and the Container Runtime (e.g., containerd).

**How it works:**
Kubelet registers the node and manages pods. Kube-proxy handles network routing (iptables/IPVS). The Container Runtime pulls images and runs the containers.

**Interview point:**
Kubelet is the only component that runs as a systemd service directly on the OS; others often run as static pods or daemonsets.

---

### Q4. Why is the API Server the central component? ⭐ MUST KNOW

**Answer:**
The API Server (`kube-apiserver`) is the only component that communicates directly with `etcd`. It acts as the front door for all cluster interactions.

**How it works:**
It authenticates, authorizes, and validates all requests from users (kubectl), control plane components, and worker nodes.

**Interview point:**
No component talks directly to another (except for API server to etcd). Everything goes through the API Server via REST calls.

---

### Q5. What is etcd and what happens if it is lost? ⭐ MUST KNOW

**Answer:**
etcd is a distributed, consistent, key-value store used to hold the entire state and configuration of the Kubernetes cluster.

**How it works:**
It stores what workloads *should* be running, secrets, configmaps, etc. It uses the Raft consensus algorithm to ensure high availability.

**Interview point:**
If etcd is lost and unrecoverable, the cluster state is completely destroyed. Backing up etcd is the most critical disaster recovery task.

---

### Q6. How does the Scheduler decide where to place Pods? 🟠 IMPORTANT

**Answer:**
The Scheduler (`kube-scheduler`) watches for newly created Pods with no assigned node and selects the best node for them based on constraints and available resources.

**How it works:**
It uses a two-step process: **Filtering** (eliminating nodes that lack resources, taint tolerances, or node selectors) and **Scoring** (ranking remaining nodes to pick the optimal one).

**Interview point:**
The scheduler doesn't run the pod; it just updates the pod's `nodeName` in the API. The node's kubelet takes over from there.

---

### Q7. What is the Controller Manager and the reconciliation loop? ⭐ MUST KNOW

**Answer:**
The Controller Manager (`kube-controller-manager`) runs background control loops (like ReplicaSet controller, Node controller) that regulate the state of the cluster.

**How it works:**
It continuously runs a **Reconciliation Loop**: Watch Current State → Compare with Desired State → Take Action to fix any drift.

**Interview point:**
This declarative model is K8s' superpower. You don't tell K8s *how* to do things; you tell it *what* you want, and controllers make it happen.

---

### Q8. What does the kubelet do on each node? ⭐ MUST KNOW

**Answer:**
The kubelet is the primary node agent that ensures containers are running in a Pod according to the PodSpecs provided by the API server.

**How it works:**
It watches the API Server for pod assignments, instructs the container runtime to start containers, monitors their health (liveness/readiness probes), and reports status back.

**Interview point:**
Kubelet is the bridge between the Kubernetes Control Plane and the physical/virtual machine it runs on.

---

### Q9. What is kube-proxy and how does it handle networking? 🟠 IMPORTANT

**Answer:**
kube-proxy is a network proxy that maintains network rules on nodes, enabling communication to Pods from inside or outside the cluster.

**How it works:**
It typically uses Linux `iptables` or `IPVS` to translate Service IPs (ClusterIPs) into actual Pod IPs, load balancing traffic across backend Pods.

**Interview point:**
kube-proxy doesn't route traffic itself; it configures the underlying OS networking rules to do the routing.

---

### Q10. What is a Container Runtime and CRI? 🟠 IMPORTANT

**Answer:**
The Container Runtime (e.g., containerd, CRI-O) is the software responsible for actually running containers. 

**How it works:**
Kubernetes communicates with it via the Container Runtime Interface (CRI), a standard API that allows K8s to use different runtimes seamlessly without recompiling kubelet.

**Interview point:**
Docker was deprecated in K8s (Dockershim removed) in favor of runtimes that natively support CRI, like containerd.

---

### Q11. Explain Desired State vs Current State and Declarative model. 🎯 SCENARIO

**Answer:**
The Declarative model means you define the **Desired State** (e.g., "I want 3 Nginx pods") in YAML, and K8s continuously works to match the **Current State** to it.

**How it works:**
If a node crashes, the current state drops to 2 pods. The Controller Manager detects the mismatch against the desired state of 3, and creates a new pod to reconcile the difference.

**Interview point:**
Compare this to Imperative models (running commands step-by-step). Declarative is self-healing and idempotent.

---

### Q12. Step-by-Step: What happens when you run `kubectl apply -f deployment.yaml`? ⭐ MUST KNOW

**Answer:**
Here is the exact flow of operations:

```text
kubectl
   ↓ (1. Validates and sends REST POST request)
API Server
   ↓ (2. Authenticates, authorizes, and persists state)
etcd
   ↓ (3. API server replies OK to kubectl. Controllers get notified)
Controllers (Deployment/ReplicaSet)
   ↓ (4. Sees new ReplicaSet, creates Pod objects in API. State saved to etcd)
Scheduler
   ↓ (5. Sees unscheduled Pods, picks a Node, updates API. State saved to etcd)
Worker Node (kubelet)
   ↓ (6. Kubelet notices pod assigned to its node)
Container Runtime
   ↓ (7. Pulls image and starts container)
Pod (Running!)
```

**Interview point:**
Interviewers ask this to see if you understand that components react asynchronously via watches, rather than calling each other sequentially.

---

## Part 2: Workloads

### Q13. What is a Pod? 🟠 IMPORTANT

**Answer:**
A Pod is the smallest, most basic deployable object in Kubernetes. It represents a single instance of a running process.

**How it works:**
A Pod can contain one or more containers that share the same network namespace (same IP), storage volumes, and lifecycle.

**Interview point:**
Rarely deploy bare Pods. Always use higher-level controllers (Deployments) so Pods are recreated if they fail.

---

### Q14. What is a ReplicaSet? 🟠 IMPORTANT

**Answer:**
A ReplicaSet ensures that a specified number of identical Pod replicas are running at any given time.

**How it works:**
It uses label selectors to identify its Pods. If the count drops, it creates new ones; if it exceeds, it terminates the excess.

**Interview point:**
You almost never create a ReplicaSet directly. You create a Deployment, which manages the ReplicaSet.

---

### Q15. What is a Deployment? ⭐ MUST KNOW

**Answer:**
A Deployment is a controller that provides declarative updates for Pods and ReplicaSets, handling rolling updates and rollbacks.

**How it works:**
When you update an image version, the Deployment creates a *new* ReplicaSet, scales it up gradually, and scales the *old* ReplicaSet down.

**Interview point:**
Deployments are meant for stateless applications (web servers, APIs).

---

### Q16. What is a StatefulSet? ⭐ MUST KNOW

**Answer:**
A StatefulSet manages stateful applications, providing strict guarantees about the ordering, uniqueness, and stability of Pods.

**How it works:**
Pods get sticky, unique identities (e.g., `db-0`, `db-1`) rather than random hashes. They are created sequentially and maintain stable persistent storage via PersistentVolumeClaims.

**Interview point:**
Use for databases (MySQL, MongoDB) or message queues (Kafka) where data persistence and network identity per instance are mandatory.

---

### Q17. What is a DaemonSet? 🟠 IMPORTANT

**Answer:**
A DaemonSet ensures that a copy of a specific Pod runs on *all* (or some matching) Nodes in the cluster.

**How it works:**
When a new node joins the cluster, a DaemonSet automatically provisions the pod on it. When a node is removed, the pod is garbage collected.

**Interview point:**
Perfect for cluster-level background tasks: log shipping (Fluentd), monitoring (Prometheus Node Exporter), and networking plugins (Calico).

---

### Q18. What are Jobs and CronJobs? 🟠 IMPORTANT

**Answer:**
A Job creates Pods that run a specific task to completion and then terminate. A CronJob manages Jobs on a time-based schedule.

**How it works:**
Unlike a Deployment (where pods restart if they exit), a Job expects the process to exit successfully (exit code 0). 

**Interview point:**
Use Jobs for one-off tasks (database migrations, batch processing) and CronJobs for recurring tasks (nightly backups).

---

### Workload Comparisons (Crucial for Interviews)

| Feature | Deployment | StatefulSet |
| :--- | :--- | :--- |
| **Pod Names** | Random (`app-7b8c...`) | Sequential (`app-0`, `app-1`) |
| **Storage** | Usually shared or none | Independent, sticky PVC per Pod |
| **Updates/Scaling** | Parallel | Ordered and graceful |
| **Use Case** | Stateless (Web APIs) | Stateful (Databases, Kafka) |

| Feature | Deployment | DaemonSet |
| :--- | :--- | :--- |
| **Placement** | Scheduler decides (can have 0 or 5 on one node) | Strictly 1 pod per Node |
| **Scaling** | Manual or HPA | Scales automatically with Node count |
| **Use Case** | App Workloads | Infrastructure/Agents (Logging, CNI) |

| Feature | Job | CronJob |
| :--- | :--- | :--- |
| **Execution** | Runs once immediately | Runs on a schedule (cron format) |
| **Object created** | Creates Pod(s) | Creates Job(s) at scheduled times |
| **Use Case** | DB Migration, Batch processing | Nightly backups, periodic syncs |

| Feature | Pod | ReplicaSet | Deployment |
| :--- | :--- | :--- | :--- |
| **Self-Healing** | No (dies permanently) | Yes (recreates Pods) | Yes |
| **Rollouts/Updates** | N/A | No (must delete Pod manually) | Yes (handles seamless updates) |
| **Hierarchy** | Smallest unit | Manages Pods | Manages ReplicaSets |

---

### Q19. Scenario: When would you use a StatefulSet over a Deployment? 🎯 SCENARIO

**Answer:**
I would use a StatefulSet when deploying an Elasticsearch cluster or PostgreSQL database. 

**How it works:**
These applications require stable network identifiers (so replicas know exactly who the primary is) and persistent, isolated storage (so `db-0` always gets `db-0`'s disk even if rescheduled). Deployments cannot guarantee this.

---

### Q20. Scenario: What happens if you delete a Pod managed by a Deployment? 🎯 SCENARIO

**Answer:**
The Pod terminates, and a replacement Pod is immediately scheduled and started.

**How it works:**
The ReplicaSet (managed by the Deployment) notices the actual Pod count (e.g., 2) doesn't match the desired count (3), so it instantly requests a new Pod to fulfill the contract.

---

### Q21. Scenario: How does a rolling update work? 🎯 SCENARIO

**Answer:**
A rolling update replaces old version Pods with new version Pods gradually, ensuring zero downtime.

**How it works:**
When you update a Deployment's image, it creates a new ReplicaSet. It scales up the new ReplicaSet by 1, waits for readiness probes to pass, then scales down the old ReplicaSet by 1, repeating until complete.

**Interview point:**
Mention `maxSurge` (how many extra pods allowed) and `maxUnavailable` (how many pods can be offline during the update) as the settings that control this behavior.

---

### Q22. Scenario: What is the exact relationship between Deployment → ReplicaSet → Pod? 🎯 SCENARIO

**Answer:**
A Deployment is a higher-level abstraction that manages ReplicaSets. The ReplicaSet is what actually manages the Pods. 

**How it works:**
If you change a Deployment's configuration (like an env var), it creates a *new* ReplicaSet. The old ReplicaSet is kept around (scaled to 0) to allow for quick rollbacks (`kubectl rollout undo`). The Pods belong strictly to the active ReplicaSet.

---

# Quick Reference
* **Control Plane:** API Server (brain/door), etcd (memory), Scheduler (placement), Controller Manager (reconciliation).
* **Worker Node:** Kubelet (captain), Kube-proxy (network), Runtime (engine).
* **StatefulSet:** Ordered, persistent, sticky identity.
* **DaemonSet:** One per node (agents).
* **Deployment:** Stateless, rolling updates via ReplicaSets.
* **Declarative:** Declare desired state; controllers reconcile automatically.
