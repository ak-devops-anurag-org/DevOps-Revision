# Pods & Containers — Interview Revision

> Focused revision notes covering Pods, containers, multi-container patterns, lifecycle, and image handling.

### Q1. What is a Pod? Why not just containers? ⭐ MUST KNOW
**Answer:**
A Pod is the smallest, most basic deployable object in Kubernetes. It represents a single instance of a running process in your cluster and can contain one or multiple containers.

**How it works:**
Kubernetes doesn't manage containers directly. It manages Pods, which wrap containers to provide shared networking, storage, and lifecycle management.

**Interview point:**
Emphasize that Pods provide the abstraction layer over container runtimes, allowing K8s to switch runtimes (like Docker to containerd) without changing the API.

### Q2. Pod vs Container 🟠 IMPORTANT
**Answer:**
Containers are the underlying execution environment for code; Pods are the K8s wrapper around them.

| Feature | Container | Pod |
|---|---|---|
| Level | Runtime level (Docker, containerd) | Kubernetes API level |
| Scope | Single process/app | One or more tightly coupled containers |
| Networking | Gets IP from Docker bridge (default) | Gets IP from CNI (shared by containers inside) |
| Lifecycle | Controlled by Pod | Managed by Kubernetes Controllers |

**Interview point:**
If asked "Can I deploy just a container?", say "No, you must wrap it in a Pod."

### Q3. Why does Kubernetes use Pods as the smallest unit? 🟠 IMPORTANT
**Answer:**
Pods allow tightly coupled processes to run together, sharing the same execution environment while remaining somewhat isolated in their own containers.

**How it works:**
If Kubernetes only deployed single containers, complex apps needing helper processes (like log forwarders) would be hard to orchestrate on the same node.

**Interview point:**
Pods solve the "co-location" problem—ensuring helper apps always land on the exact same worker node as the main app.

### Q4. Single-container Pod vs Multi-container Pod 🟠 IMPORTANT
**Answer:**
Single-container Pods are the standard use case (1 app = 1 Pod). Multi-container Pods are for tightly coupled helper processes.

| Type | Use Case | Example |
|---|---|---|
| Single | Standard application deployment | A web server |
| Multi | Tightly coupled helper processes | Web server + log forwarder |

**Interview point:**
Unless containers *must* scale together and share disk/network, they belong in separate Pods.

### Q5. 🎯 Scenario: If two containers are in the same Pod, how do they communicate? ⭐ MUST KNOW
**Answer:**
They communicate via `localhost`.

**How it works:**
All containers within a single Pod share the same network namespace. This means they share the same IP address and port space.

**Interview point:**
Mention port conflicts: Two containers in the same Pod cannot bind to the same port (e.g., both trying to use 8080 will crash).

```
Pod (shared network namespace, IP: 10.244.1.5)
│
├── Container A (port 8080)
│       │
│   localhost:9090 ──→ Container B
│
├── Container B (port 9090)
│
└── Shared Volume
```

**Key Points to Explain:**
- Two containers in the same Pod share the same network namespace
- They share the same IP address
- They communicate via localhost
- They can share volumes
- They are scheduled on the same node

### Q6. Shared volumes between containers 🟠 IMPORTANT
**Answer:**
Containers in a Pod can mount the exact same volume to share files.

**How it works:**
A volume is defined at the Pod level. Each container in the Pod can mount that volume into its own filesystem at a specific path.

**Interview point:**
Commonly used when an init container downloads data, or when a main container writes logs and a sidecar reads them.

### Q7. 🎯 Scenario: Why would you run multiple containers in a single Pod? (Sidecar Pattern) ⭐ MUST KNOW
**Answer:**
To augment or enhance the main application without modifying its code.

**How it works:**
The Sidecar pattern runs a helper container alongside the main one.
Examples:
- **Logging:** A sidecar parsing and forwarding logs to Splunk.
- **Proxy:** A service mesh proxy (like Istio Envoy) handling mTLS.
- **Monitoring:** A sidecar exposing metrics.

**Interview point:**
Sidecars share the lifecycle of the main container but run concurrently.

### Q8. What is an Init Container? 🟠 IMPORTANT
**Answer:**
A specialized container that runs and must successfully complete *before* the main app containers start.

**How it works:**
If an init container fails, K8s repeatedly restarts the Pod until it succeeds (based on restart policy). Multiple init containers run sequentially.

**Interview point:**
Init containers do not support `lifecycle`, `livenessProbe`, `readinessProbe`, or `startupProbe`.

### Q9. 🎯 Scenario: When would you use an init container? ⭐ MUST KNOW
**Answer:**
When you need setup steps to block app startup.

**Examples:**
- Waiting for a database to be ready.
- Running database migrations.
- Downloading config files or secrets from an external API.
- Setting specific file permissions on a shared volume.

**Interview point:**
Contrast it with sidecars: Init containers finish and exit; sidecars run forever.

### Q10. Init container vs Sidecar container 🟠 IMPORTANT
| Feature | Init Container | Sidecar Container (Pre-1.28) |
|---|---|---|
| Execution | Runs *before* main containers | Runs *concurrently* with main |
| Lifecycle | Must exit with 0 to proceed | Runs continuously |
| Probes | No probes supported | Supports standard probes |
| Use case | Setup, migrations, waiting | Logging, metrics, proxy |

### Q11. Native sidecar containers (K8s 1.28+) 🟠 IMPORTANT
**Answer:**
K8s 1.28 introduced native sidecars by adding `restartPolicy: Always` to init containers.

**How it works:**
Previously, sidecars were just regular containers, which made Job completion and Pod termination messy (the sidecar kept the Pod alive). Now, native sidecars start *before* main containers but keep running, and are automatically killed when main containers exit.

**Interview point:**
Mention this if asked about the "Job sidecar problem" or new K8s features.

### Q12. Pod lifecycle phases 🟠 IMPORTANT
**Answer:**
The `status.phase` of a Pod.
1. **Pending:** Accepted by K8s, but one or more containers not created (e.g., waiting for scheduling or downloading images).
2. **Running:** Bound to a node, all containers created, at least one is running/starting/restarting.
3. **Succeeded:** All containers terminated successfully (exit code 0).
4. **Failed:** All containers terminated, at least one failed (non-zero exit).
5. **Unknown:** State cannot be obtained (node communication issue).

**Interview point:**
"Pending" usually means scheduler issues or ImagePullBackOff.

### Q13. Pod Restart Policies ⭐ MUST KNOW
**Answer:**
Defines when K8s restarts containers in a Pod.

| Policy | Behavior | Use Case |
|---|---|---|
| `Always` | Restarts regardless of exit code | Deployments, long-running apps (Default) |
| `OnFailure` | Restarts only if it crashes (non-zero) | Jobs that might fail and need retries |
| `Never` | Never restarts, even on crash | One-off tasks, testing |

**Interview point:**
Restart policies apply to all containers in the Pod.

### Q14. 🎯 Scenario: What happens when a container in a Pod crashes? 🟠 IMPORTANT
**Answer:**
The kubelet restarts the container on the same node based on the Pod's `restartPolicy`.

**How it works:**
The Pod itself is not recreated or rescheduled to another node. The container is just restarted in place, meaning data on emptyDir volumes is preserved, but temporary container filesystem changes are lost.

**Interview point:**
Crash retries happen with an exponential back-off delay (10s, 20s, 40s...) capped at 5 minutes (`CrashLoopBackOff`).

### Q15. Container States 🟠 IMPORTANT
**Answer:**
While Pods have phases, individual containers have states.
1. **Waiting:** Pulling image, applying secrets (default starting state).
2. **Running:** Executing without issues.
3. **Terminated:** Stopped executing (success or failure).

**Interview point:**
Check container states (via `kubectl describe pod`) when a Pod phase is stuck in "Pending".

### Q16. Container Runtime and CRI 🟠 IMPORTANT
**Answer:**
The software responsible for actually running containers (e.g., containerd, CRI-O).

**How it works:**
K8s kubelet talks to the runtime via the Container Runtime Interface (CRI), a standard API.

**Interview point:**
Docker was deprecated (Dockershim removed in 1.24) because it wasn't natively CRI compliant; K8s now uses containerd or CRI-O directly.

### Q17. Image vs Container & OCI Basics 🟠 IMPORTANT
**Answer:**
An image is a static, read-only template containing code, libraries, and dependencies. A container is a running, writable instance of that image.

**How it works:**
OCI (Open Container Initiative) defines standards:
- **Image Spec:** How to build an image.
- **Runtime Spec:** How to unpack and run it.

**Interview point:**
Containers are just isolated Linux processes using Namespaces (isolation) and cgroups (resource limits).

### Q18. ImagePullPolicy Options ⭐ MUST KNOW
**Answer:**
Determines when the kubelet pulls an image.

| Policy | Behavior | Best For |
|---|---|---|
| `Always` | Pulls image every time | `latest` tags, ensuring freshness |
| `IfNotPresent` | Pulls only if not on node | Stable tags (v1.0), faster startups |
| `Never` | Only uses local images | Local dev (Minikube), air-gapped |

**Interview point:**
If the tag is `:latest`, the default policy automatically becomes `Always`. For other tags, it defaults to `IfNotPresent`.

### Q19. 🎯 Scenario: A Pod is in ImagePullBackOff — what do you check? ⭐ MUST KNOW
**Answer:**
It means K8s cannot pull the container image.

**Troubleshooting steps:**
1. Check the image name and tag for typos.
2. Verify registry authentication (are `imagePullSecrets` correct?).
3. Check if the image actually exists in the registry.
4. Verify node network access to the container registry.

**Interview point:**
Always use `kubectl describe pod <pod-name>` and look at the "Events" section at the bottom for the exact reason.

### Q20. Container command and args (Entrypoint Override) 🟠 IMPORTANT
**Answer:**
You can override a container's default startup command in K8s.

**How it works:**
- K8s `command` overrides Docker `ENTRYPOINT`.
- K8s `args` overrides Docker `CMD`.

**Interview point:**
Useful for running a debug shell (`command: ["sleep", "3600"]`) when a container keeps crashing immediately on startup.

### Q21. Environment variables and Volume mounts 🟠 IMPORTANT
**Answer:**
Ways to inject configuration into a container.

**How it works:**
- **Env vars:** Injected via `env` or `envFrom` (using ConfigMaps/Secrets). Great for simple strings or API endpoints.
- **Volume mounts:** Mounting files (ConfigMaps/Secrets) into the container's filesystem. Great for complex config files (like `nginx.conf`).

**Interview point:**
Volume-mounted ConfigMaps auto-update when changed; env vars require a Pod restart to pick up changes.

---

### Quick Reference Commands
- `kubectl run mypod --image=nginx` (Create a simple pod)
- `kubectl describe pod mypod` (Check events for ImagePullBackOff or CrashLoopBackOff)
- `kubectl logs mypod -c mycontainer` (View logs of a specific container in a multi-container pod)
- `kubectl exec -it mypod -- sh` (Get a shell inside the pod)
