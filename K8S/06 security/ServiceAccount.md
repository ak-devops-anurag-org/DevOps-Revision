# Service Account - Revision Notes

## Table of Contents
1. [What is a Service Account?](#what-is-a-service-account)
2. [User Account vs Service Account](#user-account-vs-service-account)
3. [Default Service Account](#default-service-account)
4. [Creating a Service Account](#creating-a-service-account)
5. [Service Account Token](#service-account-token)
6. [Assigning SA to a Pod](#assigning-sa-to-a-pod)
7. [RBAC with Service Accounts](#rbac-with-service-accounts)
8. [Key Commands](#key-commands)
9. [Quick Reference](#quick-reference)

---

## What is a Service Account?

A **Service Account** is an identity for **processes running inside Pods** to authenticate with the Kubernetes API server.

> Humans use **User Accounts**. Applications/Pods use **Service Accounts**.

### Common Use Cases
- Prometheus scraping metrics from the K8S API
- A CI/CD pipeline deploying resources via `kubectl`
- An app inside a pod that needs to list/watch other pods

---

## User Account vs Service Account

| Feature              | User Account                        | Service Account                    |
|----------------------|-------------------------------------|------------------------------------|
| Who uses it          | Humans (admins, devs)               | Pods / Applications                |
| Managed by           | External systems (LDAP, certs)      | Kubernetes (inside the cluster)    |
| Namespace-scoped     | No (cluster-wide)                   | Yes (per namespace)                |
| Auto-created         | No                                  | Yes (`default` SA per namespace)   |
| Token auto-mounted   | N/A                                 | Yes (into pod at known path)       |

---

## Default Service Account

Every namespace gets a **`default`** service account automatically.

- If a pod does not specify a `serviceAccountName`, it uses `default`
- The `default` SA has **no extra permissions** by default
- Its token is auto-mounted into pods at: `/var/run/secrets/kubernetes.io/serviceaccount/`

```bash
# See the default SA in the default namespace
kubectl get serviceaccount default

# See the token mounted in a running pod
kubectl exec <pod-name> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

> **Note (K8S v1.24+):** Tokens are no longer auto-created as Secrets. They are projected (short-lived) tokens. Use `kubectl create token` to generate one manually.

---

## Creating a Service Account

### Imperative
```bash
kubectl create serviceaccount my-app-sa
kubectl create serviceaccount my-app-sa -n monitoring   # in a specific namespace
```

### Declarative (YAML)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: monitoring
```

```bash
kubectl apply -f serviceaccount.yaml
```

---

## Service Account Token

### Generate a Token Manually (v1.24+)
```bash
# Generate a short-lived token (default 1 hour)
kubectl create token my-app-sa

# Generate with a custom expiry (e.g., 24h)
kubectl create token my-app-sa --duration=24h
```

### Create a Long-lived Token Secret (if needed)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-sa-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: my-app-sa
type: kubernetes.io/service-account-token
```
> K8S will automatically populate the token in this secret.

---

## Assigning SA to a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod
spec:
  serviceAccountName: my-app-sa   # assign the SA here
  containers:
  - name: app
    image: nginx
```

### Disable Auto-Mounting of Token (if pod doesn't need API access)
```yaml
spec:
  serviceAccountName: my-app-sa
  automountServiceAccountToken: false   # do not mount token
  containers:
  - name: app
    image: nginx
```

> You can also set `automountServiceAccountToken: false` on the ServiceAccount itself to apply to all pods using it.

---

## RBAC with Service Accounts

A Service Account alone has no permissions. You must bind it to a **Role** or **ClusterRole**.

### Example: Allow SA to list pods
```yaml
# 1. Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
# 2. RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: my-app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Imperative binding
```bash
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=default:my-app-sa \
  --namespace=default
```

---

## Key Commands

```bash
# List service accounts
kubectl get serviceaccounts
kubectl get sa -n monitoring

# Describe a SA (see mounted secrets/tokens)
kubectl describe serviceaccount my-app-sa

# Create a token for a SA
kubectl create token my-app-sa

# Check what a SA can do
kubectl auth can-i list pods \
  --as=system:serviceaccount:default:my-app-sa

# Delete a SA
kubectl delete serviceaccount my-app-sa
```

---

## Quick Reference

| Task                              | Command                                                                 |
|-----------------------------------|-------------------------------------------------------------------------|
| Create SA                         | `kubectl create serviceaccount <name>`                                  |
| List SAs                          | `kubectl get sa`                                                        |
| Generate token                    | `kubectl create token <sa-name>`                                        |
| Assign SA to pod                  | `spec.serviceAccountName: <sa-name>` in pod spec                       |
| Disable token auto-mount          | `automountServiceAccountToken: false`                                   |
| Check SA permissions              | `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>` |

---

## Summary

- **Service Accounts** are identities for pods/processes (not humans)
- Every namespace has a `default` SA — but it has no permissions by default
- Assign SA to a pod via `serviceAccountName` in the pod spec
- Tokens are short-lived in K8S v1.24+ — use `kubectl create token` for manual tokens
- Combine SA with **Role + RoleBinding** (or ClusterRole) to grant permissions
