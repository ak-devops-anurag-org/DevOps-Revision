# ⚙️ Kubernetes: Taints, Tolerations, Node Selector & Node Affinity

A minimal, example-driven reference guide for intelligent Pod scheduling using:

- 🧪 Taints & Tolerations  
- 📌 Node Selector  
- 🎯 Node Affinity  

---

## 🧪 Taints and Tolerations

### 🔍 View Taints on a Node

```bash
kubectl describe node <node-name> | grep -i taint
```

### 🚧 Add a Taint to a Node

```bash
kubectl taint node worker-node gpu=true:NoSchedule
```

➡️ Prevents Pods from being scheduled on `worker-node` unless they **tolerate** this taint.

### ❌ Remove a Taint

```bash
kubectl taint node worker-node gpu=true:NoSchedule-
```

### ✅ Pod YAML With Toleration

```yaml
tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

📘 **Concept**:  
- **Taints** = rules on Nodes to repel Pods  
- **Tolerations** = rules on Pods to tolerate taints  
- Matching requires `key`, `value`, and `effect`  

---

## 📌 Node Selector (Simplest Scheduling Rule)

A Pod will only be scheduled on nodes with matching key-value **labels**.

### 🏷️ Label a Node

```bash
kubectl label node node1 size=large
```

### 📝 Use Node Selector in Pod Spec

```yaml
spec:
  nodeSelector:
    size: large
```

📘 **Limitations**:
- Only exact matches (`key: value`)
- No expressions or logic
- No preferences — hard constraint

---

## 🎯 Node Affinity (Advanced Scheduling)

More expressive and flexible than `nodeSelector`.

### ✳️ Required (Hard Rule)

Pod **must** match at scheduling time, or it won't be scheduled.

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: size
              operator: In
              values:
                - large
```

### 💡 Preferred (Soft Rule)

Try to schedule on matching nodes, but not mandatory.

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
            - key: zone
              operator: In
              values:
                - us-east-1a
```

📘 **Affinity Types**:
- `requiredDuringSchedulingIgnoredDuringExecution`: Must match
- `preferredDuringSchedulingIgnoredDuringExecution`: Try to match
- `requiredDuringSchedulingRequiredDuringExecution`: Rare, applies at runtime (not widely supported)

### 🔢 Supported Operators

- `In`, `NotIn`
- `Exists`, `DoesNotExist`
- `Gt`, `Lt` (numeric only)

---

## 🔎 View Node Labels

```bash
kubectl get nodes --show-labels
```

---

## 🧠 TL;DR Summary

| Feature               | Simple Match | Logic & Operators | Preferences |
|----------------------|--------------|-------------------|-------------|
| Node Selector         | ✅           | ❌                | ❌          |
| Node Affinity         | ✅           | ✅                | ✅          |
| Taints & Tolerations  | ❌ (Node-based) | ✅              | ❌          |

- 🧪 Taints: Repel unwanted Pods from specific nodes  
- ✅ Tolerations: Let Pods run on tainted nodes  
- 📌 Node Selector: Basic key-value matching  
- 🎯 Affinity: Expression-based, rule-driven scheduling  

---

Happy Scheduling! 🚀
