# K8S Storage : The ELI5 Revision Sheet

> **The Barista Analogy:** The coffee shop has counters (pods) where baristas work — but when a barista goes home, their notes vanish. Storage is the **notepad locked in a drawer** that survives shift changes; a PersistentVolume is the drawer, and a PersistentVolumeClaim is the barista's key to that specific drawer.

---

## 1. The Plain-English Map

| Concept | The "Explain Like I'm 5" translation | Why the company actually pays for this |
| :--- | :--- | :--- |
| **Volume** | A USB stick plugged into a pod. Exists only as long as the pod does. | Share files between containers in the same pod; survive container restarts (not pod death). |
| **emptyDir** | A blank sticky note created when the pod starts, shredded when it dies. | Scratch space — cache, temp files, sharing data between two containers in one pod. |
| **hostPath** | Plug the pod directly into a folder on the Node's hard drive. | Debugging, DaemonSets reading node logs. Dangerous in multi-node clusters — pod might land on a different node. |
| **ConfigMap / Secret as Volume** | Mount your app's config file like a USB stick, not an env var. | The app reads config from a file path, not from the environment. |
| **PersistentVolume (PV)** | A pre-provisioned storage slot in the cluster — like a reserved parking spot. | Admins create storage that survives pod death. Decouples storage from the pod lifecycle. |
| **PersistentVolumeClaim (PVC)** | The ticket you hand in to claim that parking spot. | Developers ask for storage without knowing the underlying disk type or cloud provider. |
| **StorageClass** | A vending machine for PVs — insert a PVC, get a fresh PV automatically. | Eliminates manual PV creation (dynamic provisioning). Different tiers: fast SSD, cheap HDD. |
| **Access Modes** | How many pods can plug into this storage at once, and how. | Prevents two database pods from writing to the same disk and corrupting data. |
| **Reclaim Policy** | What happens to the parking spot when the car leaves — keep it, wipe it, or delete it. | Prevents accidental data loss (Retain) or storage leaks (Delete). |

---

## 2. The Mental Wire-Frame

```
STATIC PROVISIONING (Admin pre-creates PVs)
─────────────────────────────────────────────────────────────────
  Admin                   Developer                   Pod
   │                          │                        │
   │  kubectl apply pv.yaml   │                        │
   ├─────────────────────────►│                        │
   │                          │  kubectl apply pvc.yaml│
   │                          ├───────────────────────►│
   │                          │                        │
   │         K8S Control Plane matches PVC → PV        │
   │         (checks: storage size, accessMode,        │
   │          storageClassName, label selectors)       │
   │                          │                        │
   │                          │  PVC status → Bound    │
   │                          │◄───────────────────────┤
   │                          │                        │
   │                          │  Pod mounts PVC at/data│
   │                          │  Data persists even    │
   │                          │  when pod is killed    │


DYNAMIC PROVISIONING (StorageClass auto-creates PVs)
─────────────────────────────────────────────────────────────────

  Developer                   K8S + StorageClass         Cloud / CSI Driver
     │                               │                          │
     │  PVC with storageClassName    │                          │
     ├──────────────────────────────►│                          │
     │                               │  "Provision a 10Gi disk" │
     │                               ├─────────────────────────►│
     │                               │                          │
     │                               │  Disk created, PV auto-  │
     │                               │  generated, PVC Bound    │
     │                               │◄─────────────────────────┤
     │   PVC = Bound                 │                          │
     │◄──────────────────────────────┤                          │
     │                               │                          │
     │   Pod uses PVC → /data        │                          │


ACCESS MODES at a glance:
  ReadWriteOnce (RWO)  → One node reads & writes    [Databases]
  ReadOnlyMany  (ROX)  → Many nodes read, none write [Config files]
  ReadWriteMany (RWX)  → Many nodes read & write     [Shared NFS]
  ReadWriteOncePod     → One *pod* reads & writes    [K8S 1.22+]


RECLAIM POLICY when PVC is deleted:
  Retain  → PV stays, data intact, status = Released (manual cleanup)
  Delete  → PV and underlying disk are deleted automatically
  Recycle → (deprecated) wipes disk with rm -rf, recycles PV
```

---

## 3. The "Bare Minimum" YAML

```yaml
# ── 1. StorageClass (skip this if cluster already has a default) ─────────────
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner   # swap with ebs.csi.aws.com in AWS
volumeBindingMode: WaitForFirstConsumer     # don't bind until a pod claims it
reclaimPolicy: Delete                       # DANGER: deletes the disk when PVC is removed
---
# ── 2. PersistentVolume (static — only needed if NOT using dynamic provisioning) ─
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  hostPath:
    path: /mnt/data                         # DANGER: hostPath ties you to ONE specific node
  persistentVolumeReclaimPolicy: Retain
---
# ── 3. PersistentVolumeClaim (what the developer writes) ─────────────────────
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi                          # DANGER: must be <= PV capacity or claim stays Pending forever
  storageClassName: fast-ssd
---
# ── 4. Pod using the PVC ─────────────────────────────────────────────────────
apiVersion: v1
kind: Pod
metadata:
  name: storage-demo
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html      # path inside the container
      name: web-storage
  volumes:
  - name: web-storage
    persistentVolumeClaim:
      claimName: my-pvc                     # must match PVC name exactly
```

---

## 4. Top 3 Production Breaks (The "Call me at 2 AM" Scenarios)

### Break 1: PVC stuck in `Pending` forever
- **What the dashboard screams:**
  ```
  kubectl get pvc my-pvc
  NAME     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  my-pvc   Pending                                      fast-ssd       8m
  ```
- **The "Why":** No PV matches the PVC's requirements. Common culprits: PVC asks for `5Gi` but PV only offers `4Gi` (K8S won't round up). Or the `storageClassName` in the PVC doesn't match any PV/StorageClass. Or `accessModes` don't match. Or `WaitForFirstConsumer` is set and no pod has been scheduled yet.
- **The Fire Extinguisher:**
  ```bash
  # See the exact reason K8S won't bind it
  kubectl describe pvc my-pvc | grep -A 10 Events

  # Check available PVs and their status
  kubectl get pv

  # See the StorageClass and its binding mode
  kubectl describe storageclass fast-ssd
  ```

---

### Break 2: Pod crashes on restart but PVC is `Bound` — data is gone
- **What the dashboard screams:**
  ```
  Pod restarts fine, app starts clean — but the database is empty.
  kubectl get pvc   →  Bound  ✅  (but data missing)
  ```
- **The "Why":** The PV's reclaim policy was `Delete`. Someone deleted and re-created the PVC (maybe in a Helm upgrade). A new PV was provisioned, the old disk was destroyed, and the new empty disk was mounted. The PVC was green, but the data was gone.
- **The Fire Extinguisher:**
  ```bash
  # BEFORE you delete a PVC, check the reclaim policy
  kubectl get pv -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy

  # Patch reclaim policy to Retain BEFORE any destructive operation
  kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

  # Check PV events for deletion logs
  kubectl describe pv <pv-name>
  ```

---

### Break 3: `hostPath` volume works on dev, breaks on multi-node prod
- **What the dashboard screams:**
  ```
  App pod restarts on a different node.
  The /mnt/data directory is empty on the new node.
  Database corruption or "file not found" errors in app logs.
  ```
- **The "Why":** `hostPath` mounts a directory from the **node the pod lands on**. In a multi-node cluster, the pod can be rescheduled to a different node that has no data in that path. There's no synchronisation between nodes — each node has its own disk.
- **The Fire Extinguisher:**
  ```bash
  # See which node the pod is on
  kubectl get pod storage-demo -o wide

  # Check the node the pod moved to
  kubectl describe pod storage-demo | grep Node:

  # Fix: use a proper network storage (NFS, EBS, GCS) or pin the pod to one node
  # with nodeSelector / nodeName (not ideal) or use a proper StorageClass
  kubectl get storageclass   # find a network-backed one
  ```

---

## 5. The "Gotcha" Trapdoor

**T or F — Answer before you scroll!**

1. ❓ A PVC with `accessMode: ReadWriteOnce` can be mounted by **multiple pods simultaneously** as long as they are on the same node.

2. ❓ When you delete a PVC, the underlying PV is **always** deleted automatically.

3. ❓ A `StorageClass` with `volumeBindingMode: WaitForFirstConsumer` will immediately provision a PV as soon as the PVC is created.

---

<details>
<summary>🔽 Reveal Answers</summary>

1. **TRUE** — RWO means one *node*, not one pod. Multiple pods on the same node can mount it. (But most CSI drivers don't actually support this in practice — they block it at the driver level.)

2. **FALSE** — Depends entirely on the reclaim policy. `Delete` → yes, disk gone. `Retain` → PV stays in `Released` state, data intact, needs manual cleanup.

3. **FALSE** — `WaitForFirstConsumer` means the PV is NOT provisioned until a pod that references the PVC is actually scheduled to a node. PVC sits in `Pending` until then — by design.

</details>
