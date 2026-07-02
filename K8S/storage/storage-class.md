<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Kubernetes Storage Provisioning: Static vs Dynamic and StorageClasses

## Introduction

Kubernetes supports two approaches for provisioning PersistentVolumes (PVs):

- **Static Provisioning**: Cluster administrators manually create PV objects that map to existing storage.
- **Dynamic Provisioning**: Kubernetes automatically provisions PVs on demand using StorageClasses.

StorageClasses define *how* to dynamically provision storage by specifying a provisioner and parameters.

***

## 1. Static Provisioning

In static provisioning, an administrator creates PVs ahead of time. Developers request storage by creating PersistentVolumeClaims (PVCs) that bind to available PVs.

### Workflow

1. **Admin** creates one or more PVs.
2. **Developer** creates a PVC matching size, access modes, and optionally `storageClassName`.
3. Kubernetes finds a matching PV and binds the PVC.
4. **Developer** creates a Pod referencing the PVC.

### Example

**pv-manual.yaml**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-static
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  nfs:                            # Or hostPath, AWS EBS, etc.
    server: 10.0.0.1
    path: "/export/data"
```

**pvc-manual.yaml**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-static
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: manual
```

**pod-manual.yaml**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-static
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-static
```

**Commands**

```bash
kubectl apply -f pv-manual.yaml
kubectl apply -f pvc-manual.yaml
kubectl apply -f pod-manual.yaml
kubectl get pv,pvc
```


***

## 2. Dynamic Provisioning

Dynamic provisioning allows Kubernetes to automatically create PVs when a PVC is submitted, eliminating the need for pre-created PVs. This uses a **StorageClass**.

### StorageClass

A StorageClass defines:

- **provisioner**: The driver name (e.g., `kubernetes.io/aws-ebs`, `kubernetes.io/nfs`, or CSI drivers)
- **parameters**: Storage-specific settings (volume type, filesystem, replication)
- **reclaimPolicy**, **volumeBindingMode**, and more


### Example StorageClass

**storageclass-standard.yaml**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs    # Or any CSI driver
parameters:
  type: gp2
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: Immediate
```


### PVC Without Pre-Created PV

When a PVC specifies `storageClassName: standard`, Kubernetes uses the StorageClass to provision a PV automatically.

**pvc-dynamic.yaml**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

**pod-dynamic.yaml**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-dynamic
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /data
      name: dynamic-storage
  volumes:
  - name: dynamic-storage
    persistentVolumeClaim:
      claimName: pvc-dynamic
```

**Commands**

```bash
kubectl apply -f storageclass-standard.yaml
kubectl apply -f pvc-dynamic.yaml
kubectl get pvc,pv            # Watch PV appear after PVC is created
kubectl apply -f pod-dynamic.yaml
```


***

## 3. Static vs Dynamic Provisioning Comparison

| Aspect | Static Provisioning | Dynamic Provisioning |
| :-- | :-- | :-- |
| PV Creation | Manual by admin | Automatic via StorageClass |
| Flexibility | Low – must pre-create PVs | High – PVs created on demand |
| StorageClass | Optional | Required |
| ReclaimPolicy | Defined per PV | Defined in StorageClass |
| Operator Effort | Higher | Lower |
| Use Case | Fixed, specialized storage | General-purpose, cloud/native environments |


***

## Summary

- **Static**: Good for specialized storage setups where capacity and parameters are strictly controlled.
- **Dynamic**: Ideal for cloud-native environments, enabling self-service storage provisioning by developers.
- **StorageClass**: Central to dynamic provisioning; defines how and what type of storage to provision.

Use the method that best matches your operational model and infrastructure.

