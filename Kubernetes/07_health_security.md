# Health Checks & Security — Interview Revision

> Covers: Liveness, Readiness, Startup probes, RBAC, SecurityContext, Pod Security, image security.
> Critical for DevSecOps interviews.

## Part 1: Health Checks

### Probes Overview
```text
Liveness  → Is the container alive?       → Fail = restart container
Readiness → Should it receive traffic?    → Fail = remove from Service endpoints
Startup   → Has it finished starting?     → Fail = restart (blocks liveness/readiness)
```

| Probe | Purpose | On Failure | Container Restarted? |
|-------|---------|------------|---------------------|
| Liveness | Is it alive? | Restart container | Yes |
| Readiness | Ready for traffic? | Remove from endpoints | No |
| Startup | Started up? | Restart container | Yes |

### Q1. What are the three types of health checks in Kubernetes? ⭐ MUST KNOW

**Answer:** 
Kubernetes uses three probes: Liveness, Readiness, and Startup. 
- Liveness checks if the container is running healthy.
- Readiness checks if it can accept traffic.
- Startup checks if the app has finished booting.

**How it works:** 
The kubelet constantly executes these probes (HTTP GET, TCP socket, or Exec). If they fail, it reacts by either restarting the container or manipulating network routing.

**Interview point:** 
Interviewers want to see that you know *how* K8s reacts to failure for each (restarting vs. stopping traffic).

---

### Q2. How does a Liveness probe work? 🟠 IMPORTANT

**Answer:** 
It checks if the container is in a healthy state. If it fails, the kubelet kills the container and restarts it according to its restart policy.

**How it works:** 
Use it to detect deadlocks or hung processes. Key parameters are `initialDelaySeconds`, `periodSeconds`, `failureThreshold`, and `timeoutSeconds`.

**Interview point:** 
Always emphasize that liveness probes cause container restarts. Do not use them to check external dependencies (like databases).

---

### Q3. How does a Readiness probe differ from Liveness? ⭐ MUST KNOW

**Answer:** 
Readiness determines if the Pod should receive network traffic. If it fails, the Pod is removed from the Service endpoints, but the container is **NOT** restarted.

**How it works:** 
Useful for apps that need time to load data into memory, warm up caches, or verify connections before serving users. 

**Interview point:** 
Failing readiness = invisible to traffic. Failing liveness = container killed.

---

### Q4. Why use a Startup probe instead of a high initialDelaySeconds? 🟠 IMPORTANT

**Answer:** 
A Startup probe is designed for slow-starting apps (like Java or .NET). It disables liveness and readiness checks until it succeeds. 

**How it works:** 
If you just set a massive `initialDelaySeconds` on a Liveness probe, your app will take that long to restart later even if it crashes quickly. A startup probe protects the initial boot process without compromising fast failure detection later.

**Interview point:** 
Mention that failing a startup probe still results in a container restart, but it lets you decouple boot time from runtime monitoring.

---

### Q5. 🎯 SCENARIO: Container keeps restarting shortly after deployment. What's the issue?

**Answer:** 
The Liveness probe is likely too aggressive. 

**How it works:** 
If `initialDelaySeconds` is too low, the probe starts checking before the app is fully ready. It fails, restarts the container, and loops endlessly.

**Interview point:** 
Suggest adding a Startup probe or increasing the `initialDelaySeconds` on the Liveness probe.

---

### Q6. 🎯 SCENARIO: Pod shows 'Running' but receives no traffic. Why?

**Answer:** 
The Readiness probe is failing.

**How it works:** 
The Pod is up, but the app itself is reporting it's not ready to accept connections (e.g., returning HTTP 500 on the `/healthz` endpoint, or a DB connection is down). The Service removes it from the endpoint list.

**Interview point:** 
Check the pod events (`kubectl describe pod`) and app logs to see why the readiness probe is failing.

---

### Q7. 🎯 SCENARIO: Slow Java app keeps getting killed during startup. Fix?

**Answer:** 
Implement a Startup probe.

**How it works:** 
```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10 # 300s total startup allowance
```
**Interview point:** 
This prevents the liveness probe from stepping in and killing the container before the JVM fully initializes.

---

### Q8. 🎯 SCENARIO: What happens during a rolling update if the Readiness probe fails?

**Answer:** 
The rollout halts. 

**How it works:** 
The Deployment controller waits for new Pods to become Ready before scaling down old ones. If the new Pod's Readiness probe fails, it never becomes Ready, and the old Pods keep serving traffic.

**Interview point:** 
This is a built-in safety net (Deployment rollout status) to prevent shipping broken updates.

---

### Q9. How do you choose between httpGet, tcpSocket, and exec probes?

**Answer:** 
- **httpGet:** Best for web apps (checks for 200-399 status code).
- **tcpSocket:** Best for TCP services like databases (checks if a port opens).
- **exec:** Best for custom scripts or apps without an HTTP server (runs a command; pass = exit code 0).

**How it works:** 
Matches the probe type to the protocol your application naturally exposes.

**Interview point:** 
Keep `exec` scripts extremely lightweight, as they run inside the container and consume CPU/Memory.

---

### Q10. What are the best practices for configuring Kubernetes probes? 🟠 IMPORTANT

**Answer:** 
1. Always set `initialDelaySeconds` for liveness to avoid startup kills.
2. Use startup probes for slow-starting apps instead of huge liveness delays.
3. Don't make Liveness and Readiness probes identical (they serve different purposes).
4. Liveness should be lightweight (don't query a database).

**How it works:** 
Separation of concerns ensures the cluster routes traffic correctly without unnecessarily crashing Pods.

**Interview point:** 
Checking external databases in a Liveness probe is an anti-pattern. If the DB goes down, all your app containers will restart simultaneously, causing a cascading failure.


## Part 2: Kubernetes Security

### RBAC Overview
```text
Who (Subject) → What permissions (Role) → Bound by (RoleBinding)

User/Group/ServiceAccount
        ↓
  RoleBinding / ClusterRoleBinding
        ↓
  Role / ClusterRole
        ↓
  Resources + Verbs
```

---

### Q11. Explain the Kubernetes RBAC model. ⭐ MUST KNOW

**Answer:** 
Role-Based Access Control regulates access to K8s API resources. It connects a Subject (User, Group, or ServiceAccount) to a set of permissions (Role) using a Binding.

**How it works:** 
By default, access is denied. You explicitly grant access to specific Verbs (`get`, `list`, `create`, `delete`) on specific Resources (`pods`, `secrets`).

**Interview point:** 
Be able to clearly articulate the Subject -> Binding -> Role relationship.

---

### Q12. What is the difference between Role and ClusterRole? 🟠 IMPORTANT

**Answer:** 
- **Role:** Namespace-scoped. Defines permissions within a specific namespace.
- **ClusterRole:** Cluster-scoped. Defines permissions across the entire cluster.

**How it works:** 
Use a Role for managing pods in `production`, but use a ClusterRole for managing nodes or PersistentVolumes, which are cluster-wide resources.

**Interview point:** 
| Role | ClusterRole |
|------|-------------|
| Namespace-scoped | Cluster-scoped |
| Permissions in one namespace | Permissions across all namespaces |

---

### Q13. How do RoleBinding and ClusterRoleBinding differ?

**Answer:** 
- **RoleBinding:** Applies a Role or ClusterRole within a single namespace. 
- **ClusterRoleBinding:** Applies a ClusterRole across the entire cluster.

**How it works:** 
You can use a RoleBinding to bind a ClusterRole (like "view-all") strictly to a single namespace. You cannot bind a standard Role with a ClusterRoleBinding.

**Interview point:** 
| RoleBinding | ClusterRoleBinding |
|-------------|--------------------|
| Grants access in one namespace | Grants access everywhere |

---

### Q14. 🎯 SCENARIO: How to restrict a developer to only view Pods in their namespace?

**Answer:** 
Create a namespace-scoped `Role` with `get`, `list`, `watch` verbs on `pods`, and bind it to the developer using a `RoleBinding`.

**How it works:** 
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-ns
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

**Interview point:** 
Explain that you'd use a `RoleBinding` to tie this to the user in `dev-ns`.

---

### Q15. What is a ServiceAccount and why shouldn't we use the 'default' one? ⭐ MUST KNOW

**Answer:** 
A ServiceAccount (SA) provides an identity for Pods interacting with the K8s API. Every namespace has a `default` SA.

**How it works:** 
If you use the default SA, it might accumulate broad permissions over time. The best practice is to create a dedicated, minimally-privileged ServiceAccount per application.

**Interview point:** 
Mention external integrations like GKE Workload Identity or AKS Workload Identity Federation, which map K8s ServiceAccounts to cloud IAM roles.

---

### Q16. How do you prevent K8s from automatically injecting API tokens into Pods? 🟠 IMPORTANT

**Answer:** 
Set `automountServiceAccountToken: false`.

**How it works:** 
By default, K8s mounts an API token into every Pod at `/var/run/secrets/kubernetes.io/serviceaccount`. If an attacker breaches the pod, they can use this token to talk to the K8s API.

**Interview point:** 
If the application does not need to communicate with the K8s API server, always disable this mount at the Pod or ServiceAccount level.

---

### Q17. What is a SecurityContext in Kubernetes? ⭐ MUST KNOW

**Answer:** 
`securityContext` defines privilege and access control settings for a Pod or Container.

**How it works:** 
It controls the user ID the process runs as, filesystem permissions, Linux capabilities, and whether privilege escalation is allowed.

**Interview point:** 
It bridges Kubernetes configuration directly to Linux kernel security features.

---

### Q18. Explain the key container-level securityContext settings. 🟠 IMPORTANT

**Answer:** 
```yaml
securityContext:
  runAsNonRoot: true         # Mandates the container runs as a non-root user
  runAsUser: 1000            # Explicitly sets the UID
  readOnlyRootFilesystem: true # Prevents writes to the container image OS layer
  allowPrivilegeEscalation: false # Prevents child processes gaining more privileges
  capabilities:
    drop: ["ALL"]            # Drops all Linux root capabilities (e.g., NET_ADMIN)
```

**How it works:** 
These settings harden the container boundary, meaning even if the app has a vulnerability, the attacker is heavily restricted.

**Interview point:** 
Memorize these five fields. They are the core of DevSecOps container hardening.

---

### Q19. 🎯 SCENARIO: Pod is running as root. How to prevent this?

**Answer:** 
Enforce `runAsNonRoot: true` in the pod's `securityContext`.

**How it works:** 
The kubelet will refuse to start the container if the image tries to run as root (UID 0). 

**Interview point:** 
You should also fix the underlying Dockerfile by adding `USER 1000` (or another non-root UID).

---

### Q20. 🎯 SCENARIO: Container has excessive permissions. How to lock it down?

**Answer:** 
Drop all Linux capabilities.

**How it works:** 
Add `capabilities: drop: ["ALL"]` to the `securityContext`. 

**Interview point:** 
By default, Docker/K8s grants a subset of root capabilities to containers (like `CHOWN`, `SETUID`). Dropping all capabilities adheres to the principle of least privilege.

---

### Q21. What are Kubernetes Pod Security Standards (PSS) and Admission (PSA)?

**Answer:** 
PSS defines three policies (Privileged, Baseline, Restricted) governing pod security. PSA is the admission controller that enforces them.

**How it works:** 
PSA replaces the deprecated PodSecurityPolicies (PSP). You configure PSA at the namespace level to either `enforce` (block), `audit` (log), or `warn` (alert) on non-compliant pods.

**Interview point:** 
Know the three levels: Privileged (open), Baseline (blocks obvious risks), Restricted (highly locked down, requires `runAsNonRoot`, drops capabilities).

---

### Q22. What are the best practices for Container Image Security? 🟠 IMPORTANT

**Answer:** 
- Use minimal base images (distroless, Alpine) to reduce attack surface.
- Scan images in CI/CD pipelines (using Trivy, Snyk, etc.).
- Pin image tags with SHA hashes (avoid `:latest`).
- Sign and verify images (using Sigstore/Cosign).

**How it works:** 
Securing the supply chain ensures you don't deploy vulnerable or compromised code into the cluster.

**Interview point:** 
Distroless images are great because they lack package managers and shells, making it harder for attackers to move laterally if they achieve Remote Code Execution.

---

### Q23. 🎯 SCENARIO: How to implement a complete Least Privilege model for a Pod?

**Answer:** 
Combine RBAC, SecurityContext, and NetworkPolicies.

**How it works:** 
1. **Network**: Default-deny NetworkPolicy (only allow required ports).
2. **Identity**: Dedicated ServiceAccount with `automountServiceAccountToken: false` and minimal RBAC Roles.
3. **Runtime**: Restricted `securityContext` (non-root, read-only FS, drop all capabilities).

**Interview point:** 
This shows you understand defense-in-depth across the network, API, and runtime layers.

---

### Quick Reference: Container Security Best Practices
1. Run as non-root
2. Read-only root filesystem
3. Drop all capabilities
4. No privilege escalation
5. Scan images in CI/CD
6. Use NetworkPolicies for micro-segmentation
7. RBAC with least privilege (Dedicated SA)
8. Encrypt secrets at rest & use external managers
9. Enable K8s API audit logging
10. Keep Kubernetes nodes and components updated
