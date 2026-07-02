# Kubernetes Scheduling: Core Revision Notes

## 1. Manual Scheduling
* **Concept:** Bypassing the Kube-Scheduler completely to place a Pod on a specific node.
* **Why it matters:** Useful if the scheduler is down, or if you have a strict requirement to place a workload on a specific machine.
* **How:** You explicitly set the `nodeName` field in the Pod specification.

**Example `pod-manual.yaml`**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: manual-scheduled-pod
spec:
  nodeName: worker-node-01 # Bypasses scheduler and forces placement here
  containers:
  - name: nginx
    image: nginx:alpine
```

---

## 2. Labels, Selectors, and nodeSelector
* **Concept:** The simplest form of scheduling constraints. 
* **Why it matters:** You label a node (e.g., `disktype: ssd`) and tell the Pod to only schedule on nodes with that label using `nodeSelector`.
* **Limitation:** It only supports strict, exact matches. You cannot say "NOT this label" or "EITHER this OR that".

**Example `pod-nodeselector.yaml`**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
  - name: web
    image: nginx
  nodeSelector:
    disktype: ssd # Node must have the label 'disktype=ssd'
```

---

## 3. Taints and Tolerations
* **Concept:** Node-side restrictions. 
  * **Taint (The Lock):** Applied to a *Node* to repel Pods. 
  * **Toleration (The Key):** Applied to a *Pod* to allow it to be scheduled on a tainted node.
* **Crucial Point to Remember:** Taints **DO NOT** guarantee a Pod will be scheduled on that node. They only guarantee that Pods *without* the toleration will be kept away.
* **Taint Effects:**
  * `NoSchedule`: Won't schedule new pods.
  * `PreferNoSchedule`: Tries not to schedule, but isn't strict.
  * `NoExecute`: Evicts existing pods that don't tolerate the taint.
* **Toleration Operators:**
  * `Equal`: The `key` and `value` in the toleration must exactly match the taint on the node.
  * `Exists`: Only checks if the `key` exists on the node. The `value` is ignored (leave the `value` field completely out).

**Command to Taint a Node:**
`kubectl taint nodes node1 key=value:NoSchedule`

**Example `pod-toleration.yaml` (Showing both operators)**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  containers:
  - name: ml-app
    image: my-ml-app
  tolerations:
  # Example 1: 'Equal' Operator
  # The node must have a taint exactly matching: gpu=true:NoSchedule
  - key: "gpu"
    operator: "Equal" 
    value: "true"
    effect: "NoSchedule"
  
  # Example 2: 'Exists' Operator
  # The node just needs a taint with the key 'dedicated-node', regardless of its value.
  - key: "dedicated-node"
    operator: "Exists"
    effect: "NoSchedule"
```

---

## 4. Node Affinity
* **Concept:** Pod-side attraction. The advanced, highly expressive version of `nodeSelector`.
* **Why it matters:** Allows complex logical operators (`In`, `NotIn`, `Exists`, `DoesNotExist`).
* **Types:**
  * **Required** (`requiredDuringSchedulingIgnoredDuringExecution`): Hard rule. If no node matches, the pod stays pending.
  * **Preferred** (`preferredDuringSchedulingIgnoredDuringExecution`): Soft rule. The scheduler tries to match it, but if it can't, it will place the pod somewhere else anyway.

**Example `pod-affinity.yaml`**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: big-data-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: # Hard Rule
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: In # Can be In, NotIn, Exists, etc.
            values:
            - Large
            - ExtraLarge
  containers:
  - name: data-processor
    image: data-app
```

---

## 5. Taints/Tolerations vs. Node Affinity (The Ultimate Combo)
* **The Problem:** * Tolerations allow a Pod onto a dedicated node, but don't stop that Pod from going to a regular node instead.
  * Affinity pulls a Pod to a dedicated node, but doesn't stop regular Pods from invading that dedicated node.
* **The Solution (Dedicated Nodes):** Use both together! 
  1. Apply a **Taint** to the node so regular pods stay away.
  2. Add a **Toleration** to your special Pod so it can enter.
  3. Add **Node Affinity** to your special Pod so it is forced to choose that node and doesn't wander off.

---

## 6. DaemonSets
* **Concept:** Ensures that a copy of a Pod runs on **ALL** (or some) Nodes.
* **Why it matters:** Essential for cluster-wide infrastructure tasks like log collection (Fluentd), monitoring agents (Prometheus Node Exporter), or networking plugins (kube-proxy, Calico).
* **Key Point:** As new nodes are added to the cluster, DaemonSets automatically add the Pod to the new node.

**Example `daemonset.yaml`**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd
```

---

## 7. Static Pods
* **Concept:** Pods managed directly by the `kubelet` on a specific node, without the API server observing them.
* **Why it matters:** Used to bootstrap the Kubernetes Control Plane itself. Since the API server isn't running yet, the kubelet reads YAML files directly from a directory on the server (usually `/etc/kubernetes/manifests`) and starts components like `etcd`, `kube-apiserver`, and `kube-controller-manager`.
* **Key Point:** You cannot manage these via regular `kubectl deployment` commands. If you delete the YAML file from the directory, the kubelet kills the pod.

---

## 8. Priority Classes
* **Concept:** Tells the scheduler which Pods are more important.
* **Why it matters in Production:** If your cluster runs out of CPU/Memory, the scheduler will proactively evict (kill) lower-priority Pods to make room for higher-priority Pods (Preemption).
* **How:** Create a PriorityClass object, then reference it in your Pod spec.

**Example `priority.yaml`**
```yaml
# 1. Create the Priority Class
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority-app
value: 1000000 # Higher number = higher priority
globalDefault: false
description: "Used for mission-critical apps."
---
# 2. Use it in a Pod
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
spec:
  priorityClassName: high-priority-app
  containers:
  - name: app
    image: my-critical-app
```
```