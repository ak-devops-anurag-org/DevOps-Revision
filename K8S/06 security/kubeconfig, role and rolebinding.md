# Kubernetes kubeconfig, RBAC, Roles, and Role Bindings

## Table of Contents
1. [kubeconfig](#kubeconfig)
2. [RBAC (Role-Based Access Control)](#rbac-role-based-access-control)
3. [Role and Role Binding](#role-and-role-binding)

---

## kubeconfig

**kubeconfig** is the configuration file that stores cluster connection info for `kubectl` or other Kubernetes clients.

### Why is kubeconfig important?
- Saves authentication, cluster, and context information in one place
- Lets you manage multiple clusters and users

### Structure
A kubeconfig file has **three main sections**:
- **clusters**: Information about clusters (API server address, CA, etc)
- **users**: How to authenticate (client certificates, tokens, etc)
- **contexts**: Which user talks to which cluster

### Basic Example
```yaml
apiVersion: v1
kind: Config
clusters:
- name: prod-cluster
  cluster:
    server: https://prod-api-server:6443
    certificate-authority: /etc/kubernetes/certs/ca.crt
users:
- name: prod-admin
  user:
    client-certificate: /etc/kubernetes/certs/admin.crt
    client-key: /etc/kubernetes/certs/admin.key
contexts:
- name: prod-context
  context:
    cluster: prod-cluster
    user: prod-admin
current-context: prod-context
```

### Useful Commands
```bash
# View the current kubeconfig
kubectl config view
# Use a different kubeconfig file
kubectl get pods --kubeconfig myconfig.yaml
# List all contexts
kubectl config get-contexts
# Set the current context
kubectl config use-context prod-context
```

---

## RBAC (Role-Based Access Control)

**RBAC** lets cluster admins define what actions users and service accounts can perform in a Kubernetes cluster.

### Key Concepts
- **Role**: A set of permissions, limited to a namespace
- **Role Binding**: Connects a user/service account/group to a Role (namespace-scoped)
- **ClusterRole**: Permissions that apply cluster-wide
- **ClusterRoleBinding**: Cluster-wide association of a ClusterRole

### Why use RBAC?
- Controlled, auditable, and secure Kubernetes API access
- Principle of least privilege

### Typical Usage
- Grant 'developer' access to team for only pods in 'dev' namespace
- Give read-only permissions on all namespaces for monitoring

---

## Role and Role Binding

### What is a Role?
A **Role** is a namespaced set of rules granting permissions (verbs) on specific resources and API groups.

#### Example: Role YAML
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: dev
rules:
- apiGroups: [""]   # core API group
  resources: ["pods"]
  verbs: ["get", "list", "create", "delete"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]
```

### What is a Role Binding?
A **RoleBinding** connects users/groups/service accounts to a Role within a specific namespace. This grants those subjects the role's permissions within that namespace.

#### Example: RoleBinding YAML
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devuser-developer-binding
  namespace: dev
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

### Useful Commands
```bash
# List all roles in the current namespace
kubectl get roles
# List all role bindings in the current namespace
kubectl get rolebindings
# Describe a role
kubectl describe role developer
# Describe a role binding
kubectl describe rolebinding devuser-developer-binding
# Test permissions (for self or another user)
kubectl auth can-i create pods --as dev-user --namespace dev
```

### Resource Name Restrictions
You can restrict access to specific named resources:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: selective-access
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods"]
  resourceNames: ["frontend", "backend"]
  verbs: ["get", "update"]
```

---

## Summary
- **kubeconfig** manages clusters, users, contexts, and namespaces.
- **RBAC** enforces declarative, least-privilege API access.
- **Roles** and **RoleBindings** are namespace-scoped for fine-grained permission allocation, while **ClusterRoles** and **ClusterRoleBindings** allow cluster-wide permissions.