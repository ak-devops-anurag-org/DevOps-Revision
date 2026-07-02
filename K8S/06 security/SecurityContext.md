# Security Context - Revision Notes

## Table of Contents
1. [What is Security Context?](#what-is-security-context)
2. [Pod-level vs Container-level](#pod-level-vs-container-level)
3. [Common Security Context Fields](#common-security-context-fields)
4. [runAsUser and runAsGroup](#runasuser-and-runasgroup)
5. [Capabilities](#capabilities)
6. [readOnlyRootFilesystem](#readonlyrootfilesystem)
7. [allowPrivilegeEscalation](#allowprivilegeescalation)
8. [Full Example](#full-example)
9. [Key Commands](#key-commands)
10. [Quick Reference](#quick-reference)

---

## What is Security Context?

A **Security Context** defines privilege and access control settings for a **Pod or Container**.

It lets you control:
- Which user/group the container process runs as
- Whether the container can run as root
- Linux capabilities (add or drop)
- Whether the filesystem is read-only
- Whether privilege escalation is allowed

> Think of it as the **"run-as" rules** for containers in Kubernetes.

---

## Pod-level vs Container-level

Security context can be set at **two levels**:

| Level       | Field in YAML          | Scope                                       |
|-------------|------------------------|---------------------------------------------|
| Pod         | `spec.securityContext` | Applies to **all containers** in the pod    |
| Container   | `spec.containers[].securityContext` | Overrides pod-level for that container only |

> **Container-level overrides Pod-level** for overlapping fields.

```yaml
spec:
  securityContext:          # Pod-level (applies to all containers)
    runAsUser: 1000
  containers:
  - name: app
    image: nginx
    securityContext:        # Container-level (overrides pod-level)
      runAsUser: 2000       # This container runs as user 2000
```

---

## Common Security Context Fields

| Field                      | Level          | Purpose                                               |
|----------------------------|----------------|-------------------------------------------------------|
| `runAsUser`                | Pod / Container| UID the container process runs as                     |
| `runAsGroup`               | Pod / Container| Primary GID the container process runs as             |
| `runAsNonRoot`             | Pod / Container| Reject containers that run as root (UID 0)            |
| `fsGroup`                  | Pod only       | GID applied to mounted volumes                        |
| `capabilities`             | Container only | Add/drop Linux capabilities                           |
| `readOnlyRootFilesystem`   | Container only | Mount root filesystem as read-only                    |
| `allowPrivilegeEscalation` | Container only | Prevent `sudo` / `setuid` escalation                 |
| `privileged`               | Container only | Run container in privileged mode (full host access)   |
| `seccompProfile`           | Pod / Container| Apply seccomp syscall filtering profile               |

---

## runAsUser and runAsGroup

Forces the container to run as a specific Linux user/group instead of root.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: run-as-user-demo
spec:
  securityContext:
    runAsUser: 1000       # All containers run as UID 1000
    runAsGroup: 3000      # Primary GID is 3000
    fsGroup: 2000         # Files in mounted volumes owned by GID 2000
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "id && sleep 3600"]
```

```bash
# Verify inside the pod
kubectl exec run-as-user-demo -- id
# uid=1000 gid=3000 groups=3000,2000
```

### runAsNonRoot
```yaml
securityContext:
  runAsNonRoot: true    # Pod will fail to start if image runs as root (UID 0)
```

---

## Capabilities

Linux capabilities let you grant specific **root-like privileges** without giving full root access.

### Drop All + Add Specific (Best Practice)
```yaml
securityContext:
  capabilities:
    drop:
    - ALL              # drop everything first
    add:
    - NET_ADMIN        # add only what is needed
    - SYS_TIME
```

### Common Capabilities

| Capability   | What it allows                               |
|--------------|----------------------------------------------|
| `NET_ADMIN`  | Network interface config, routing            |
| `SYS_TIME`   | Set system clock                             |
| `SYS_PTRACE` | Process tracing (strace, gdb)                |
| `CHOWN`      | Change file ownership                        |
| `NET_BIND_SERVICE` | Bind to ports < 1024 without root     |

> ⚠️ Capabilities are **container-level only** — cannot be set at pod-level.

---

## readOnlyRootFilesystem

Makes the container's root filesystem **read-only**, preventing malicious writes.

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

> If the app needs to write files, mount a writable `emptyDir` volume for those specific paths:

```yaml
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - mountPath: /tmp           # allow writes only here
      name: tmp-storage
    - mountPath: /var/run       # nginx needs to write here
      name: run-storage
  volumes:
  - name: tmp-storage
    emptyDir: {}
  - name: run-storage
    emptyDir: {}
```

---

## allowPrivilegeEscalation

Prevents the container process from gaining more privileges than its parent (e.g., via `sudo` or `setuid` binaries).

```yaml
securityContext:
  allowPrivilegeEscalation: false   # Recommended — always set to false
```

> Always set `allowPrivilegeEscalation: false` unless you have a specific need.

---

## Full Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsUser: 1000          # Pod-level: all containers run as UID 1000
    runAsNonRoot: true       # Reject if image tries to run as root
    fsGroup: 2000            # Volume files owned by GID 2000
  containers:
  - name: secure-app
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: false   # No sudo/setuid escalation
      readOnlyRootFilesystem: true      # Root FS is read-only
      capabilities:
        drop:
        - ALL                           # Drop all Linux capabilities
        add:
        - NET_BIND_SERVICE              # Allow binding to port < 1024
    volumeMounts:
    - name: tmp-dir
      mountPath: /tmp
  volumes:
  - name: tmp-dir
    emptyDir: {}
```

---

## Key Commands

```bash
# Verify user inside pod
kubectl exec <pod-name> -- id
kubectl exec <pod-name> -- whoami

# Check security context of a running pod
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].securityContext}'

# Describe pod to see security settings
kubectl describe pod <pod-name>

# Test writing to read-only FS (should fail)
kubectl exec <pod-name> -- touch /test-file
```

---

## Quick Reference

| Setting                       | Field                               | Best Practice Value         |
|-------------------------------|-------------------------------------|-----------------------------|
| Run as specific user          | `runAsUser: 1000`                   | Non-root UID (≥ 1000)       |
| Prevent root containers       | `runAsNonRoot: true`                | `true`                      |
| Read-only root filesystem     | `readOnlyRootFilesystem: true`      | `true`                      |
| Prevent privilege escalation  | `allowPrivilegeEscalation: false`   | `false`                     |
| Linux capabilities            | `capabilities.drop: [ALL]`          | Drop all, add only needed   |
| Volume ownership              | `fsGroup: 2000`                     | Set per app requirements    |

---

## Summary

- **Security Context** controls Linux security settings for pods and containers
- **Pod-level** applies to all containers; **Container-level** overrides it for specific containers
- Key settings: `runAsUser`, `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities`
- **Capabilities** are container-level only — always drop ALL and add only what is needed
- Use `readOnlyRootFilesystem: true` + `emptyDir` volumes for writable paths
