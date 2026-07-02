## 1. Rolling Updates and Rollbacks
* **Concept:** When you release a new version of your app (e.g., v1 to v2), you don't want to take the whole system offline. A **Rolling Update** replaces old Pods with new ones gradually. A **Rollback** is the "undo" button if v2 crashes.
* **How it works:** Managed entirely by the `Deployment` object. It spins up a new ReplicaSet for the new version and scales it up, while slowly scaling down the old ReplicaSet.
* **Key Commands:**
  * **Trigger an update:** `kubectl set image deployment/my-app my-container=my-app:v2`
  * **Watch the update:** `kubectl rollout status deployment/my-app`
  * **Check history:** `kubectl rollout history deployment/my-app`
  * **Undo (Rollback):** `kubectl rollout undo deployment/my-app` (Reverts to the last working version)

**Example `deployment-update.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1       # Can create 1 extra pod during update (Total 5)
      maxUnavailable: 1 # Can take down 1 old pod at a time (Leaves 3 running)
  # ... (selector and template)
```

# 🧾 Rolling Updates & Rollback – Quick Revision

* ❌ **No auto rollback** in Kubernetes by default
* 🔁 Manual rollback → `kubectl rollout undo`
* ⚙️ Auto rollback requires tools like Argo Rollouts / Flagger

---

## 🚨 Failure Scenarios

* **Case A:** Pods run but app is broken
  → ❌ Traffic goes to bad version → **Full outage risk**

* **Case B:** Pods fail (CrashLoop / image issue)
  → ⚠️ Rollout stuck → **Partial or degraded service**

---

## 🛡️ Protection Mechanisms

* ✅ **Readiness Probes**
  → Only send traffic to healthy pods

* ✅ **Rolling Update Strategy**
  → Old pods are removed **only after new pods are healthy**

---

# 🧠 One-line memory

👉 **“Kubernetes deploys automatically, but rollback and safety checks are your responsibility.”**
