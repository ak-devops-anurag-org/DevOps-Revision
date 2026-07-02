# Kubernetes Persistent Volumes (PV) and Persistent Volume Claims (PVC): Complete Guide

## Introduction

PersistentVolumes (PVs) and PersistentVolumeClaims (PVCs) allow Kubernetes Pods to use storage that outlives Pod restarts and deletions. This makes them essential for stateful applications like databases.

**Key Concepts:**
- **PV:** A cluster-level resource representing physical storage (NFS, cloud disks, hostPath, etc.)
- **PVC:** A user’s request for storage, specifying size and access mode
- **Binding:** Kubernetes matches PVCs to PVs satisfying the PVC’s requirements
- **Lifecycle:** PVs live beyond individual Pods; PVCs bind and unbind to PVs

## Core Components

### 1. PersistentVolume (PV)

A PV is defined by a cluster administrator or dynamically provisioned via StorageClasses. It includes:
- **Capacity** (e.g., 5Gi)
- **AccessModes** (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- **ReclaimPolicy** (Retain, Delete, Recycle)
- **StorageClassName** (for dynamic provisioning)
- **VolumeSource** (NFS, hostPath, AWS EBS, GCE PD, etc.)

**Example (hostPath PV):**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
```

### 2. PersistentVolumeClaim (PVC)

A PVC is created by a developer to request storage without knowing underlying details. It includes:
- **Requested Storage** (e.g., 3Gi)
- **AccessModes** (must match a PV’s modes)
- **StorageClassName** (optional; must match PV)

**Example PVC:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: manual
```

## Binding PVC to PV

When a PVC is created, Kubernetes control plane finds a matching PV and binds them automatically. You can view status:
```bash
kubectl get pv
kubectl get pvc
``` 

A bound PVC shows `STATUS: Bound` and the `VOLUME` column indicates the PV name.

## Using PVC in a Pod

Pods don’t use PVs directly. Instead, they reference PVCs to mount storage.

**Example Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app-container
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: example-pvc
```
```bash
kubectl apply -f example-pod.yaml
kubectl describe pod app-pod
```

## Difference: PV vs Volume

| Aspect                   | Volume                          | PersistentVolume (PV)                |
|--------------------------|---------------------------------|--------------------------------------|
| Scope                    | Pod-scoped                      | Cluster-scoped                       |
| Lifecycle                | Lives with Pod                  | Independent of Pods                  |
| Definition               | Inline in Pod spec              | Separate resource object             |
| Persistence              | Temporary (Pod deletion loses data) | Durable (PVC ensures data survives) | 
| Provisioning             | Automatic on Pod creation       | Static (admin) or dynamic (StorageClass) |
| Access via Pod           | `volumes` in Pod spec           | Via PVC, then `volumes` in Pod spec  |
| Use Cases                | Sharing data between containers in a Pod, configs, cache | Stateful databases, long-term storage |

## Commands Summary

```bash
# Create PV and PVC
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

# Verify binding
kubectl get pv
kubectl get pvc

# Deploy Pod using PVC
kubectl apply -f pod.yaml
kubectl get pods
kubectl describe pod app-pod
```

## Best Practices

- Use StorageClasses for dynamic provisioning
- Set appropriate ReclaimPolicy (`Retain` for backups, `Delete` for throw-away data)
- Label PVs and PVCs for easy management
- Monitor PVC usage and capacity events
