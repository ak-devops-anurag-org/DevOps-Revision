# Configuration & Storage — Interview Revision

> Covers: ConfigMap, Secrets, external secret management, PV, PVC, StorageClass, dynamic provisioning.

## Part 1: Configuration

### Q1. What is a ConfigMap? ⭐ MUST KNOW
**Answer:** A ConfigMap is an API object used to store non-confidential data in key-value pairs. It allows you to decouple environment-specific configuration from your container images.

**How it works:** You can create it from literals, files, or YAML manifests. Pods consume ConfigMaps as environment variables, volume mounts, or command-line arguments.

**Interview point:** Mention that ConfigMaps are strictly for non-sensitive data. Never put passwords or tokens in a ConfigMap.

### Q2. How does updating a ConfigMap affect running Pods? 🟠 IMPORTANT
**Answer:** If mounted as a volume, the file inside the Pod updates automatically (with a slight delay). If injected as environment variables, the Pod will NOT see the update until it is restarted.

**How it works:** Kubelet periodically syncs volume mounts. For env vars, they are set during container creation and cannot be changed dynamically.

**Interview point:** If asked how to handle dynamic updates without restart, suggest tools like Reloader or application-level file watchers.

### Q3. What is a Secret in Kubernetes? ⭐ MUST KNOW
**Answer:** A Secret is an object that contains a small amount of sensitive data such as passwords, tokens, or SSH keys.

**How it works:** Data is stored in `etcd`. By default, Secrets are base64 encoded, **not** encrypted. Types include Opaque (default), `kubernetes.io/tls` (certificates), and `kubernetes.io/dockerconfigjson` (registry credentials).

**Interview point:** Emphasize that base64 is encoding, not encryption. Anyone with access to the Secret object can easily decode it.

### Q4. How do you consume Secrets in a Pod? 🟠 IMPORTANT
**Answer:** Secrets can be injected as environment variables or mounted as data volumes.

**How it works:** When mounted as a volume, each key in the Secret becomes a file containing its value. When used as an env var, the value is populated during container startup.

**Interview point:** Prefer volume mounts over env vars for Secrets, as env vars might be logged or visible in tools like `docker inspect`.

### Q5. ConfigMap vs Secret comparison table ⭐ MUST KNOW
**Answer:**
| Feature | ConfigMap | Secret |
|---------|-----------|--------|
| Purpose | Non-sensitive data | Sensitive data |
| Storage format | Plain text in etcd | Base64 encoded in etcd |
| Size limit | 1MB | 1MB |
| Best practice | General configs | Passwords, certs, keys |

**How it works:** Both use similar consumption methods (volumes/env vars) but target different security levels.

**Interview point:** Keep in mind the 1MB limit for both; they are not meant for large files.

### Q6. How do you secure Kubernetes Secrets? (DevSecOps focus) ⭐ MUST KNOW
**Answer:** 
1. Enable encryption at rest for `etcd`.
2. Use strict RBAC to restrict who can `get` or `list` secrets.
3. Use external secret managers (HashiCorp Vault, AWS Secrets Manager).
4. Never commit plain YAML Secrets to Git.

**How it works:** Encryption at rest ensures the physical data in etcd is secure. RBAC secures the API layer. External secrets remove plain-text data from clusters.

**Interview point:** Mentioning external secret management and Secret rotation strategies shows maturity in enterprise DevSecOps practices.

### Q7. What are External Secrets and Sealed Secrets? 🟠 IMPORTANT
**Answer:** They are mechanisms to manage secrets securely in GitOps workflows. 
- **Sealed Secrets:** Encrypts the secret using a controller's public key so it can be safely committed to Git. The controller decrypts it inside the cluster.
- **External Secrets Operator:** Fetches secrets from external APIs (AWS, GCP, Vault) and automatically creates native K8s Secrets.

**How it works:** They solve the "chicken and egg" problem of storing K8s secrets securely when using declarative deployments.

**Interview point:** External Secrets is usually the preferred enterprise approach over Sealed Secrets.

### Q8. 🎯 SCENARIO: Application is not picking up new ConfigMap values.
**Answer:** Check how the ConfigMap is consumed. If consumed as an environment variable, the Pod must be restarted (e.g., `kubectl rollout restart`).

**How it works:** Env vars are static after container launch. If mounted as a volume, check if the application has logic to hot-reload config files.

**Interview point:** First question to ask the interviewer: "Is the ConfigMap injected as an environment variable or a volume mount?"

### Q9. 🎯 SCENARIO: A Secret is visible in plain text in a pod's logs. How do you secure it?
**Answer:** The Secret was likely passed as an environment variable and printed by the app, or logged during a crash. Change the Pod to mount the Secret as a volume instead.

**How it works:** Reading from a file (volume mount) is generally safer and less likely to be accidentally dumped to standard output.

**Interview point:** Also suggest application code reviews to ensure sensitive data is masked in logs.

### Q10. 🎯 SCENARIO: How to manage secrets across multiple environments (Dev, QA, Prod)?
**Answer:** Use an external secret manager like HashiCorp Vault or cloud provider secret managers alongside the External Secrets Operator.

**How it works:** The central manager handles rotation, auditing, and environment-specific values. The K8s cluster just syncs what it needs securely.

**Interview point:** Avoid storing plain text secrets anywhere. External secret management is the industry standard for multi-environment scaling.

### Q11. 🎯 SCENARIO: A Pod cannot access a Secret. How do you troubleshoot?
**Answer:** 
1. Check if the Secret exists in the **same namespace** as the Pod.
2. Check if the Pod ServiceAccount has RBAC permissions (if accessing via API).
3. Verify the Secret name and keys match the Pod YAML exactly.

**How it works:** Secrets are strictly namespace-scoped. A Pod in `namespace-a` cannot mount a Secret from `namespace-b`.

**Interview point:** Mention namespace scoping immediately; it's the most common trap.

## Part 2: Storage

### Q12. What are the common volume types in Kubernetes? 🟠 IMPORTANT
**Answer:**
- `emptyDir`: Temporary storage created with the Pod, deleted when the Pod is deleted.
- `hostPath`: Mounts a file/directory from the host node (security risk, avoid in prod).
- `PersistentVolumeClaim (PVC)`: Requests persistent cluster-level storage.
- `configMap` / `secret`: Injects configuration data as files.

**How it works:** The `volumes` array in a Pod spec defines the storage, and `volumeMounts` maps it to a container path.

**Interview point:** Clearly distinguish between ephemeral (`emptyDir`) and persistent (`PVC`) storage.

### Q13. What is a PersistentVolume (PV)? ⭐ MUST KNOW
**Answer:** A PV is a cluster-level storage resource provisioned by an administrator or dynamically via a StorageClass.

**How it works:** It represents a piece of physical storage capacity (e.g., an AWS EBS volume or NFS share) and has details like capacity, access modes, and reclaim policies.

**Interview point:** PVs exist independently of any individual Pod's lifecycle.

### Q14. What is a PersistentVolumeClaim (PVC)? ⭐ MUST KNOW
**Answer:** A PVC is a request for storage by a user/developer.

**How it works:** A PVC specifies size and access modes. Kubernetes automatically binds the PVC to a suitable PV. The Pod then references the PVC to mount the storage.

**Interview point:** Think of PV as the "node" and PVC as the "pod". The PVC requests resources (storage) that the PV provides.

### Q15. What is a StorageClass? ⭐ MUST KNOW
**Answer:** A StorageClass defines the "type" of storage and enables dynamic provisioning of PVs.

**How it works:** When a PVC requests a specific StorageClass, the cloud provider automatically provisions the underlying storage disk and creates the PV on the fly. Parameters depend on the cloud provider.

**Interview point:** Know common examples: GKE uses `pd-standard` or `pd-ssd`, AKS uses `managed-premium`, AWS uses `gp3`.

### Q16. Flow diagram of Dynamic Provisioning 🟠 IMPORTANT
**Answer:**
```
Developer creates PVC
    ↓
StorageClass provisions PV dynamically
    ↓
PVC binds to PV
    ↓
Pod mounts PVC
    ↓
Container accesses storage at mount path
```

**How it works:** This removes the need for admins to manually pre-provision disks.

**Interview point:** Dynamic provisioning is the cloud-native standard for storage.

### Q17. Static vs Dynamic Provisioning 🟠 IMPORTANT
**Answer:**
| Feature | Static Provisioning | Dynamic Provisioning |
|---------|---------------------|----------------------|
| Creation | Admin creates PVs manually | StorageClass auto-creates PVs |
| Management | High manual overhead | Automated |
| Flexibility | Limited to pre-created sizes | Exact requested size allocated |

**How it works:** Static requires guessing what developers need; dynamic reacts to actual PVC requests.

**Interview point:** Always recommend dynamic provisioning for cloud environments.

### Q18. What are the PV Access Modes? ⭐ MUST KNOW
**Answer:**
- **ReadWriteOnce (RWO):** Volume can be mounted as read-write by a single node.
- **ReadOnlyMany (ROX):** Volume can be mounted read-only by many nodes.
- **ReadWriteMany (RWX):** Volume can be mounted read-write by many nodes.
- **ReadWriteOncePod (RWOP):** Volume can be mounted read-write by a single Pod (K8s 1.22+).

**How it works:** These dictate how many nodes/pods can attach the storage simultaneously.

**Interview point:** Block storage (EBS) is usually RWO. File storage (EFS/NFS) is RWX.

### Q19. What are PV Reclaim Policies? 🟠 IMPORTANT
**Answer:**
- **Retain:** PV is kept after PVC is deleted (requires manual cleanup).
- **Delete:** PV and underlying storage asset are deleted when PVC is deleted.
- **Recycle:** (Deprecated) Scourges the data and makes PV available again.

**How it works:** It determines what happens to the underlying storage when the user releases it.

**Interview point:** Default for dynamic provisioning is usually `Delete`. For critical databases, change it to `Retain`.

### Q20. How does a StatefulSet handle storage differently than a Deployment? ⭐ MUST KNOW
**Answer:** StatefulSets use `volumeClaimTemplates` to generate a unique PVC for each Pod replica.

**How it works:** If you have 3 Pods, you get 3 separate PVCs and 3 separate disks. If a Pod is rescheduled, it reconnects to its exact same PVC.

**Interview point:** Deployments share the same PVC among all replicas (which fails if the disk is RWO). StatefulSets are mandatory for distributed stateful workloads.

### Q21. 🎯 SCENARIO: PVC is stuck in Pending state.
**Answer:** 
1. Check if a suitable PV exists (for static).
2. Check if the requested StorageClass exists and is default (for dynamic).
3. Check PVC events (`kubectl describe pvc <name>`) for provisioning errors (e.g., cloud quota hit).

**How it works:** A Pending PVC means K8s cannot find or create a matching PV.

**Interview point:** Mention `kubectl describe` as your first debugging step.

### Q22. 🎯 SCENARIO: Application loses data after a Pod restart.
**Answer:** The Pod is likely using an `emptyDir` volume instead of a PersistentVolumeClaim.

**How it works:** `emptyDir` is ephemeral, tied to the Pod's lifecycle, and shared between containers in the pod.

**Interview point:** To fix this, create a PVC and update the Pod spec to mount the PVC instead.

### Q23. 🎯 SCENARIO: Pod cannot mount a volume, stuck in ContainerCreating.
**Answer:** 
1. The PV might be an RWO disk attached to a different Node.
2. The underlying cloud API might be slow or failing to attach the disk.
3. Check `kubectl describe pod` for attachment errors.

**How it works:** A Node must successfully attach the block device before the Kubelet can mount it to the container.

**Interview point:** Multi-AZ clusters often hit this if the disk is in AZ-A but the Pod is scheduled in AZ-B.

### Q24. 🎯 SCENARIO: How do you share storage between two Pods?
**Answer:** If they are on the same node, you can use `hostPath` (not recommended). If across nodes, you must use a PV with `ReadWriteMany` (RWX) access mode.

**How it works:** Standard block storage (EBS) only supports RWO, preventing multi-node concurrent writes.

**Interview point:** Interviewers love this question to test if you know the difference between block (RWO) and file (RWX, like EFS/NFS) storage.

### Q25. Comparison tables: PV vs PVC and emptyDir vs PV 🟠 IMPORTANT
**Answer:**
**PV vs PVC:**
| PV | PVC |
|----|-----|
| Actual storage resource | Request for storage |
| Admin / Cluster scoped | Developer / Namespace scoped |
| "The Disk" | "The Claim" |

**emptyDir vs PV:**
| emptyDir | PersistentVolume |
|----------|------------------|
| Ephemeral | Persistent |
| Deleted with Pod | Survives Pod deletion |
| Best for caches/scratch | Best for databases/state |

**Interview point:** Keep analogies simple. PVC is to PV what a Pod is to a Node.

---
### Quick Reference
- **ConfigMap:** Non-sensitive, plain text, 1MB limit.
- **Secret:** Sensitive, base64 encoded, use volumes over env vars, 1MB limit.
- **Dynamic Provisioning:** Developer (PVC) -> StorageClass -> Provider (PV).
- **RWO:** Block storage, single node. **RWX:** File storage, multi-node. 
- **StatefulSet:** `volumeClaimTemplates` for stable per-Pod storage.
