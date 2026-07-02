# Network Policies - Revision Notes

## Table of Contents
1. [What is a Network Policy?](#what-is-a-network-policy)
2. [Default Behaviour Without Network Policy](#default-behaviour-without-network-policy)
3. [Key Concepts](#key-concepts)
4. [Network Policy Structure](#network-policy-structure)
5. [Ingress Rules](#ingress-rules)
6. [Egress Rules](#egress-rules)
7. [Selectors — podSelector, namespaceSelector, ipBlock](#selectors)
8. [Common Examples](#common-examples)
9. [Key Commands](#key-commands)
10. [Quick Reference](#quick-reference)

---

## What is a Network Policy?

A **Network Policy** is a Kubernetes resource that controls **which pods can communicate with each other** and with external endpoints (at the IP/port level).

> Without Network Policies, **all pods can talk to all pods** across all namespaces — no restrictions.

### Requirements
- Your CNI plugin **must support** Network Policies (e.g., **Calico, Cilium, Weave**).
- **Flannel does NOT support** Network Policies by default.

---

## Default Behaviour Without Network Policy

| Scenario                         | Default Behaviour          |
|----------------------------------|----------------------------|
| Pod → Pod (same namespace)       | ✅ Allowed                 |
| Pod → Pod (different namespace)  | ✅ Allowed                 |
| Pod → External internet          | ✅ Allowed                 |
| External → Pod                   | Depends on Services        |

Once you **apply any Network Policy to a pod**, all traffic NOT explicitly allowed is **denied**.

---

## Key Concepts

| Term                | Meaning                                                                 |
|---------------------|-------------------------------------------------------------------------|
| `podSelector`       | Selects which pods this policy applies to (in the same namespace)       |
| `policyTypes`       | Declares if policy controls `Ingress`, `Egress`, or both                |
| `ingress`           | Rules for **incoming** traffic to selected pods                         |
| `egress`            | Rules for **outgoing** traffic from selected pods                       |
| `namespaceSelector` | Match pods from a specific namespace                                    |
| `ipBlock`           | Allow/deny specific IP ranges (CIDR)                                    |

---

## Network Policy Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-network-policy
  namespace: default           # policy applies in this namespace

spec:
  podSelector:                 # which pods this policy targets
    matchLabels:
      app: my-app

  policyTypes:                 # what traffic types this policy manages
  - Ingress
  - Egress

  ingress:                     # rules for incoming traffic
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80

  egress:                      # rules for outgoing traffic
  - to:
    - podSelector:
        matchLabels:
          role: db
    ports:
    - protocol: TCP
      port: 5432
```

---

## Ingress Rules

Controls **who can send traffic IN** to the selected pods.

```yaml
ingress:
- from:
  - podSelector:               # allow from pods with this label
      matchLabels:
        app: frontend
  - namespaceSelector:         # allow from pods in this namespace
      matchLabels:
        env: production
  - ipBlock:                   # allow from this IP range
      cidr: 192.168.0.0/16
      except:
      - 192.168.1.0/24         # except this sub-range
  ports:
  - protocol: TCP
    port: 8080
```

> ⚠️ **Multiple entries in `from:` are OR conditions** — any matching source is allowed.  
> ⚠️ `podSelector` + `namespaceSelector` in the **same list item** = AND condition.

---

## Egress Rules

Controls **where pods can send traffic OUT**.

```yaml
egress:
- to:
  - podSelector:
      matchLabels:
        role: db
  ports:
  - protocol: TCP
    port: 5432
- to:
  - ipBlock:
      cidr: 0.0.0.0/0          # allow all outbound internet
  ports:
  - protocol: TCP
    port: 443                   # only on HTTPS
```

---

## Selectors

### podSelector

```yaml
# Match pods with a label
- podSelector:
    matchLabels:
      app: frontend

# Match ALL pods in the namespace (empty selector)
- podSelector: {}
```

### namespaceSelector

```yaml
# Match pods from a specific namespace (namespace must have matching label)
- namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: monitoring
```

> Label namespaces using: `kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring`

### AND condition — podSelector + namespaceSelector together

```yaml
# Only pods with role=api IN the production namespace
- from:
  - namespaceSelector:
      matchLabels:
        env: production
    podSelector:               # same list item = AND
      matchLabels:
        role: api
```

### ipBlock

```yaml
- ipBlock:
    cidr: 10.0.0.0/8           # allow this entire range
    except:
    - 10.0.1.0/24              # except this sub-range
```

---

## Common Examples

### Example 1 — Deny All Ingress (Isolate a pod)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  podSelector: {}        # applies to ALL pods in namespace
  policyTypes:
  - Ingress
  # no ingress rules = deny all incoming traffic
```

### Example 2 — Deny All Egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  # no egress rules = deny all outgoing traffic
```

### Example 3 — Allow only DB access from API pods

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-api
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db                     # applies to db pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api                # only api pods can reach db
    ports:
    - protocol: TCP
      port: 5432
```

### Example 4 — Allow cross-namespace traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: production
spec:
  podSelector: {}                  # all pods in production namespace
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring  # from monitoring namespace only
```

---

## Key Commands

```bash
# List network policies
kubectl get networkpolicy
kubectl get netpol              # short alias
kubectl get netpol -n <namespace>

# Describe a network policy
kubectl describe networkpolicy db-allow-api

# Apply a network policy
kubectl apply -f network-policy.yaml

# Delete a network policy
kubectl delete networkpolicy db-allow-api

# Check namespace labels (for namespaceSelector)
kubectl get namespace --show-labels

# Label a namespace
kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring
```

---

## Quick Reference

| Goal                              | How                                                              |
|-----------------------------------|------------------------------------------------------------------|
| Deny all ingress to a pod         | `policyTypes: [Ingress]` with no `ingress:` rules               |
| Deny all egress from a pod        | `policyTypes: [Egress]` with no `egress:` rules                 |
| Allow from specific pods          | `ingress.from.podSelector.matchLabels`                           |
| Allow from specific namespace     | `ingress.from.namespaceSelector.matchLabels`                     |
| Allow from specific IP range      | `ingress.from.ipBlock.cidr`                                      |
| Allow to specific pods (egress)   | `egress.to.podSelector.matchLabels`                              |
| Apply to ALL pods in namespace    | `podSelector: {}`                                                |
| OR between sources                | Multiple items in `from:` list                                   |
| AND (pod + namespace)             | Same list item has both `podSelector` and `namespaceSelector`    |

---

## Summary

- **Network Policy** controls ingress (in) and egress (out) traffic for pods
- Default = **all traffic allowed**; once a policy selects a pod, **unmatched traffic is denied**
- Requires a CNI that supports Network Policies (Calico, Cilium, Weave — NOT Flannel)
- Use `podSelector: {}` to target **all pods** in a namespace
- `from:` / `to:` list items are **OR**; keys within the same list item are **AND**
- Always label namespaces if using `namespaceSelector`
