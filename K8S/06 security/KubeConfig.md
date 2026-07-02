# KubeConfig - Revision Notes

## Table of Contents
1. [What is KubeConfig?](#what-is-kubeconfig)
2. [Config Object Structure](#config-object-structure)
3. [Clusters vs Users vs Contexts](#clusters-vs-users-vs-contexts)
4. [Multi-Cluster KubeConfig Example](#multi-cluster-kubeconfig-example)
5. [Key Commands](#key-commands)
6. [Merging Multiple KubeConfig Files](#merging-multiple-kubeconfig-files)
7. [Quick Reference](#quick-reference)

---

## What is KubeConfig?

**KubeConfig** is a YAML file that tells `kubectl` **how to connect** to a Kubernetes cluster — which server to hit, which user to authenticate as, and which namespace to use by default.

- Default location: `~/.kube/config` (Linux/Mac) or `%USERPROFILE%\.kube\config` (Windows)
- You can override it using `--kubeconfig` flag or `KUBECONFIG` env variable

> Think of it like a **address book** — it stores all cluster addresses, user credentials, and named shortcuts (contexts) to switch between them.

---

## Config Object Structure

The kubeconfig file is a Kubernetes API object of `kind: Config`.

```yaml
apiVersion: v1
kind: Config

# Which context to use when kubectl runs
current-context: dev-context

# List of clusters (where to connect)
clusters: []

# List of users (how to authenticate)
users: []

# List of contexts (which user talks to which cluster)
contexts: []
```

### Field Overview

| Field             | Purpose                                              |
|-------------------|------------------------------------------------------|
| `apiVersion`      | Always `v1`                                          |
| `kind`            | Always `Config`                                      |
| `current-context` | The active context kubectl uses by default           |
| `clusters`        | List of cluster endpoints + CA certificate           |
| `users`           | List of credentials (certs, tokens, etc.)            |
| `contexts`        | Named combinations of cluster + user + namespace     |

---

## Clusters vs Users vs Contexts

### 🔵 Clusters
Defines **where** to connect — the API server address and the CA certificate to trust.

```yaml
clusters:
- name: prod-cluster
  cluster:
    server: https://prod.api-server.com:6443
    certificate-authority: /etc/kubernetes/pki/ca.crt
    # OR inline (base64 encoded):
    # certificate-authority-data: <base64-encoded-ca-cert>
```

| Field                        | Description                              |
|------------------------------|------------------------------------------|
| `name`                       | Unique name to reference this cluster    |
| `server`                     | API server URL                           |
| `certificate-authority`      | Path to the cluster's CA certificate     |
| `certificate-authority-data` | Base64 inline CA cert (portable)         |

---

### 🟢 Users
Defines **who** is connecting — how to authenticate with the cluster.

```yaml
users:
- name: prod-admin
  user:
    client-certificate: /etc/kubernetes/pki/admin.crt
    client-key: /etc/kubernetes/pki/admin.key
    # OR using a token:
    # token: eyJhbGciOiJSUzI1NiIsI...
```

| Auth Method              | When to Use                                      |
|--------------------------|--------------------------------------------------|
| `client-certificate/key` | Certificate-based auth (most common in kubeadm) |
| `token`                  | ServiceAccount tokens, OIDC tokens               |
| `username/password`      | Basic auth (deprecated, avoid)                   |
| `exec`                   | Plugin-based auth (e.g., aws eks get-token)      |

---

### 🟠 Contexts
Defines a **named shortcut** — a pairing of cluster + user + (optional) namespace.

```yaml
contexts:
- name: dev-context
  context:
    cluster: dev-cluster
    user: dev-user
    namespace: development   # optional default namespace
```

> `kubectl` uses the `current-context` to know which cluster+user+namespace to apply to every command.

---

## Multi-Cluster KubeConfig Example

A real-world kubeconfig managing **dev** and **prod** environments:

```yaml
apiVersion: v1
kind: Config
current-context: dev-context

clusters:
- name: dev-cluster
  cluster:
    server: https://dev.api.company.com:6443
    certificate-authority: /home/user/.kube/certs/dev-ca.crt
- name: prod-cluster
  cluster:
    server: https://prod.api.company.com:6443
    certificate-authority: /home/user/.kube/certs/prod-ca.crt

users:
- name: dev-user
  user:
    client-certificate: /home/user/.kube/certs/dev-user.crt
    client-key: /home/user/.kube/certs/dev-user.key
- name: prod-admin
  user:
    client-certificate: /home/user/.kube/certs/prod-admin.crt
    client-key: /home/user/.kube/certs/prod-admin.key

contexts:
- name: dev-context
  context:
    cluster: dev-cluster
    user: dev-user
    namespace: development
- name: prod-context
  context:
    cluster: prod-cluster
    user: prod-admin
    namespace: production
```

---

## Key Commands

### View the Config

```bash
# View full kubeconfig (merged)
kubectl config view

# View kubeconfig with secrets (certs not redacted)
kubectl config view --raw

# Use a specific kubeconfig file
kubectl config view --kubeconfig=/path/to/custom-config.yaml
```

### Get Current Context

```bash
# See which context is currently active
kubectl config current-context
```

### List Contexts, Clusters, Users

```bash
# List all contexts (shows current with *)
kubectl config get-contexts

# List only cluster names
kubectl config get-clusters

# List only users
kubectl config get-users
```

### Switch Context (Update Current Context)

```bash
# Switch to a different context
kubectl config use-context prod-context

# Verify it changed
kubectl config current-context
```

### Run a Command as a Specific User (without switching)

```bash
# One-off command using a specific context
kubectl get pods --context=prod-context

# One-off command using a specific namespace
kubectl get pods --context=dev-context --namespace=kube-system
```

### Set / Update Context Fields

```bash
# Set a namespace for the current context
kubectl config set-context --current --namespace=dev

# Set namespace for a specific context
kubectl config set-context prod-context --namespace=production

# Modify a context's user
kubectl config set-context dev-context --user=new-dev-user --cluster=dev-cluster
```

### Add Cluster, User, Context Manually

```bash
# Add a new cluster
kubectl config set-cluster new-cluster \
  --server=https://new.api.server:6443 \
  --certificate-authority=/path/to/ca.crt

# Add a new user (cert-based)
kubectl config set-credentials new-user \
  --client-certificate=/path/to/user.crt \
  --client-key=/path/to/user.key

# Add a new context
kubectl config set-context new-context \
  --cluster=new-cluster \
  --user=new-user \
  --namespace=default
```

### Delete Context / Cluster / User

```bash
kubectl config delete-context dev-context
kubectl config delete-cluster dev-cluster
kubectl config unset users.dev-user
```

---

## Merging Multiple KubeConfig Files

You may have separate kubeconfig files for different clusters. Merge them using the `KUBECONFIG` environment variable:

```bash
# Linux / Mac
export KUBECONFIG=~/.kube/config:~/.kube/dev-config:~/.kube/prod-config

# Windows (PowerShell)
$env:KUBECONFIG = "$HOME\.kube\config;$HOME\.kube\dev-config;$HOME\.kube\prod-config"

# Now all contexts from all files are available
kubectl config get-contexts

# Flatten and save to a single file
kubectl config view --raw --flatten > ~/.kube/merged-config
```

---

## Quick Reference

| Task                              | Command                                                      |
|-----------------------------------|--------------------------------------------------------------|
| View config                       | `kubectl config view`                                        |
| Current context                   | `kubectl config current-context`                             |
| List all contexts                 | `kubectl config get-contexts`                                |
| Switch context                    | `kubectl config use-context <context-name>`                  |
| Set default namespace for context | `kubectl config set-context --current --namespace=<ns>`      |
| Run with a specific context       | `kubectl <cmd> --context=<context-name>`                     |
| Use a different kubeconfig file   | `kubectl <cmd> --kubeconfig=/path/to/config`                 |
| Add cluster                       | `kubectl config set-cluster <name> --server=<url>`           |
| Add user (token)                  | `kubectl config set-credentials <name> --token=<token>`      |
| Delete context                    | `kubectl config delete-context <name>`                       |

---

## Summary

- **KubeConfig** = config file for `kubectl` to know *where* and *who* to connect as
- **Clusters** = API server addresses + CA certs
- **Users** = credentials (cert/key or token)
- **Contexts** = named cluster + user + namespace combos
- `current-context` = the active default for all `kubectl` commands
- Use `kubectl config use-context` to switch, `--context` flag for one-off commands
