# Kubernetes Cluster Roles - Complete Guide

## Table of Contents
1. [Basic Definitions](#basic-definitions)
2. [Overview](#overview)
3. [Understanding Cluster Roles vs Regular Roles](#understanding-cluster-roles-vs-regular-roles)
4. [Cluster-Scoped vs Namespaced Resources](#cluster-scoped-vs-namespaced-resources)
5. [Creating Cluster Roles](#creating-cluster-roles)
6. [Cluster Role Bindings](#cluster-role-bindings)
7. [Common Commands](#common-commands)
8. [Practical Examples](#practical-examples)
9. [Best Practices](#best-practices)

## Basic Definitions

### What is RBAC?
**Role-Based Access Control (RBAC)** is a security mechanism in Kubernetes that controls who can access what resources and what actions they can perform. Think of it like permissions in your operating system - some users can read files, others can write, and administrators can do everything.

### What is a Role?
A **Role** is like a job description that lists specific permissions. For example, a "developer" role might have permission to create and view pods, but not delete nodes. Roles work only within a specific namespace (like a department in a company).

### What is a Cluster Role?
A **Cluster Role** is similar to a Role but works across the entire Kubernetes cluster, not just one namespace. It's like having company-wide permissions rather than department-specific ones. Cluster Roles can:
- Manage cluster-wide resources (like nodes, storage)
- Grant access to resources across all namespaces

### What is a Role Binding?
A **Role Binding** connects a user (or service account) to a Role. It's like saying "John gets the developer permissions in the web-app namespace."

### What is a Cluster Role Binding?
A **Cluster Role Binding** connects a user (or service account) to a Cluster Role. It's like saying "Sarah gets the cluster administrator permissions across the entire cluster."

### Key Terms Explained Simply

| Term | Simple Definition | Example |
|------|------------------|---------|
| **Subject** | Who gets the permissions | A user named "john" or a service account "monitoring-sa" |
| **Verb** | What action can be performed | "get" (read), "create" (make new), "delete" (remove) |
| **Resource** | What Kubernetes object to act on | "pods", "nodes", "services" |
| **API Group** | Category of resources | "" (core), "apps" (applications), "networking.k8s.io" |
| **Namespace** | A virtual cluster division | "default", "production", "development" |

## Overview

**Cluster Roles** in Kubernetes are like master keys that can open doors throughout the entire building (cluster), while regular Roles are like department keys that only work in specific rooms (namespaces).

### When to Use Cluster Roles
- Managing cluster infrastructure (nodes, storage)
- Monitoring across all namespaces
- Cluster administration tasks
- Cross-namespace operations

### When to Use Regular Roles
- Application-specific permissions
- Namespace-limited access
- Developer permissions within projects
- Environment-specific access (dev, staging, prod)

## Understanding Cluster Roles vs Regular Roles

| Aspect | Roles | Cluster Roles |
|--------|-------|---------------|
| **Scope** | Namespace-scoped (one department) | Cluster-scoped (entire company) |
| **Resources** | Namespaced resources only | Cluster-scoped resources and namespaced resources across all namespaces |
| **Binding** | RoleBinding | ClusterRoleBinding |
| **Use Case** | Access within specific namespace | Cluster-wide access or cross-namespace access |
| **Example** | "Can manage pods in 'web-app' namespace" | "Can manage all nodes in the cluster" |

## Cluster-Scoped vs Namespaced Resources

### Understanding Resource Scopes

**Think of Kubernetes like an apartment building:**
- **Namespaced resources** are like items inside individual apartments (pods, services, deployments)
- **Cluster-scoped resources** are like building infrastructure (elevators, parking, building management)

### Check Resource Types

```bash
# View namespaced resources (apartment-level)
kubectl api-resources --namespaced=true

# View non-namespaced (cluster-scoped) resources (building-level)
kubectl api-resources --namespaced=false
```

### Common Cluster-Scoped Resources
- **Nodes**: The physical/virtual machines that run your applications
- **ClusterRoles**: Cluster-level permission templates
- **ClusterRoleBindings**: Cluster-level permission assignments
- **PersistentVolumes**: Shared storage available cluster-wide
- **Namespaces**: The "apartments" themselves
- **CustomResourceDefinitions (CRDs)**: Custom resource types you define

### Common Namespaced Resources
- **Pods**: Your running applications
- **Services**: Network endpoints for your apps
- **Deployments**: App deployment configurations
- **ConfigMaps**: Configuration files
- **Secrets**: Passwords and sensitive data

## Creating Cluster Roles

### Basic Concepts Before Code

**A Cluster Role defines three main things:**
1. **API Groups**: Which category of resources (like "core" or "apps")
2. **Resources**: Which specific resources (like "pods" or "nodes")
3. **Verbs**: Which actions are allowed (like "get", "create", "delete")

### Basic Cluster Role YAML Structure

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-administrator
rules:
- apiGroups: [""] # "" means core API group (pods, nodes, services)
  resources: ["nodes"] # Which resources this rule applies to
  verbs: ["get", "list", "delete", "create"] # What actions are allowed
```

### Understanding the YAML Fields

| Field | Purpose | Example Values |
|-------|---------|----------------|
| `apiGroups` | Category of resources | `""` (core), `"apps"`, `"networking.k8s.io"` |
| `resources` | Specific resource types | `"nodes"`, `"pods"`, `"services"` |
| `verbs` | Allowed actions | `"get"`, `"list"`, `"create"`, `"update"`, `"delete"` |

### Common Verbs Explained

| Verb | What it means | Example |
|------|---------------|---------|
| `get` | Read a specific resource | View details of node "worker-1" |
| `list` | Read multiple resources | See all nodes in cluster |
| `watch` | Monitor for changes | Get notified when nodes change |
| `create` | Make new resources | Add a new node to cluster |
| `update` | Modify existing resources | Change node labels |
| `patch` | Partial updates | Update only node status |
| `delete` | Remove resources | Remove a node from cluster |

### Advanced Cluster Role Example

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-manager
rules:
- apiGroups: [""] # Core API group
  resources: ["nodes", "persistentvolumes"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""] # Core API group
  resources: ["namespaces"]
  verbs: ["get", "list", "watch"] # Read-only for namespaces
- apiGroups: ["apps"] # Applications API group
  resources: ["deployments", "daemonsets"]
  verbs: ["get", "list", "watch"] # Read-only for apps
```

### Create Cluster Role Using kubectl

```bash
# Method 1: Create from YAML file
kubectl create -f cluster-role.yaml

# Method 2: Create directly with command (imperative)
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# Method 3: Create for multiple resources
kubectl create clusterrole resource-manager \
  --verb=get,list,create,delete \
  --resource=nodes,persistentvolumes,namespaces
```

## Cluster Role Bindings

### What is a Cluster Role Binding?

A **Cluster Role Binding** is like an assignment letter that says:
- **WHO**: Which user, service account, or group
- **GETS**: Which Cluster Role (set of permissions)
- **WHERE**: Across the entire cluster

### Basic Cluster Role Binding YAML

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-role-binding
subjects: # WHO gets the permissions
- kind: User
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
roleRef: # WHICH permissions they get
  kind: ClusterRole
  name: cluster-administrator
  apiGroup: rbac.authorization.k8s.io
```

### Understanding Subjects (WHO gets permissions)

| Subject Type | Description | Example |
|--------------|-------------|---------|
| `User` | A human user | `name: john@company.com` |
| `ServiceAccount` | An application account | `name: monitoring-sa` |
| `Group` | A group of users | `name: developers` |

### Cluster Role Binding for Service Account

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-cluster-binding
subjects:
- kind: ServiceAccount
  name: monitoring-service-account
  namespace: monitoring # ServiceAccounts belong to namespaces
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
```

### Cluster Role Binding for Group

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developers-cluster-binding
subjects:
- kind: Group
  name: developers # All users in "developers" group
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-developer
  apiGroup: rbac.authorization.k8s.io
```

### Create Cluster Role Binding Using kubectl

```bash
# Method 1: Create from YAML file
kubectl create -f cluster-role-binding.yaml

# Method 2: Create for a user
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-administrator \
  --user=admin-user

# Method 3: Create for a service account
kubectl create clusterrolebinding monitoring-binding \
  --clusterrole=cluster-reader \
  --serviceaccount=monitoring:monitoring-sa

# Method 4: Create for a group
kubectl create clusterrolebinding dev-group-binding \
  --clusterrole=cluster-developer \
  --group=developers
```

## Common Commands

### Viewing Cluster Roles and Bindings

```bash
# List all cluster roles
kubectl get clusterroles

# Count cluster roles
kubectl get clusterroles --no-headers | wc -l

# List cluster roles in JSON format with count
kubectl get clusterroles --no-headers -o json | jq '.items | length'

# List all cluster role bindings
kubectl get clusterrolebindings

# Count cluster role bindings
kubectl get clusterrolebindings --no-headers | wc -l

# Describe specific cluster role (see details)
kubectl describe clusterrole cluster-admin

# Describe specific cluster role binding (see who has what)
kubectl describe clusterrolebinding cluster-admin

# Get cluster role in YAML format (for backup/editing)
kubectl get clusterrole cluster-admin -o yaml

# Get cluster role binding in YAML format
kubectl get clusterrolebinding cluster-admin -o yaml
```

### Checking Permissions (Testing Access)

```bash
# Can I perform this action? (as current user)
kubectl auth can-i create nodes
kubectl auth can-i delete persistentvolumes

# Can someone else perform this action?
kubectl auth can-i create deployments --as dev-user
kubectl auth can-i list nodes --as system:serviceaccount:monitoring:prometheus

# Can I do this in a specific namespace?
kubectl auth can-i create pods --as dev-user --namespace production

# Show all my permissions
kubectl auth can-i --list

# Show all permissions for specific user
kubectl auth can-i --list --as dev-user
```

## Practical Examples

### Example 1: Node Administrator Cluster Role

**Scenario**: You need someone to manage all nodes in your cluster.

```yaml
# node-admin-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-admin
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["*"] # All actions on nodes
- apiGroups: [""]
  resources: ["nodes/status"]
  verbs: ["get", "list", "watch", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-admin-binding
subjects:
- kind: User
  name: node-administrator
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-admin
  apiGroup: rbac.authorization.k8s.io
```

### Example 2: Monitoring Service Account

**Scenario**: Prometheus needs to read metrics from across the entire cluster.

```yaml
# monitoring-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-sa
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/metrics", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "replicasets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-reader-binding
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-reader
  apiGroup: rbac.authorization.k8s.io
```

### Example 3: Developer Access Across Namespaces

**Scenario**: Developers need access to their apps across dev, staging, and prod namespaces.

```yaml
# developer-cluster-access.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-cluster-access
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"] # Can see namespaces but not modify
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-cluster-binding
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-cluster-access
  apiGroup: rbac.authorization.k8s.io
```

## Best Practices

### Security Best Practices

1. **Principle of Least Privilege** (Give minimum permissions needed)
   ```yaml
   # ✅ Good: Specific permissions
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list", "watch"]
   
   # ❌ Avoid: Wildcard permissions (too powerful)
   rules:
   - apiGroups: ["*"]
     resources: ["*"]
     verbs: ["*"]
   ```

2. **Use Resource Names When Possible** (Limit to specific resources)
   ```yaml
   rules:
   - apiGroups: [""]
     resources: ["secrets"]
     verbs: ["get"]
     resourceNames: ["app-secret", "db-secret"] # Only these secrets
   ```

3. **Separate Cluster Roles by Function** (Don't mix responsibilities)
   ```bash
   # Create specific roles for different jobs
   kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
   kubectl create clusterrole pv-manager --verb=get,list,create,delete --resource=persistentvolumes
   ```

### Operational Best Practices

1. **Regular Auditing** (Check who has what access)
   ```bash
   # Review cluster roles and bindings regularly
   kubectl get clusterroles
   kubectl get clusterrolebindings
   
   # Check who has dangerous cluster-admin access
   kubectl describe clusterrolebinding cluster-admin
   ```

2. **Documentation and Naming** (Make it clear what each role does)
   ```yaml
   metadata:
     name: monitoring-cluster-reader
     annotations:
       description: "Read-only access for monitoring systems"
       owner: "platform-team"
       created-by: "admin@company.com"
   ```

3. **Testing Permissions** (Test before applying to production)
   ```bash
   # Test permissions before giving them to users
   kubectl auth can-i --list --as=system:serviceaccount:monitoring:prometheus
   ```

### Common Use Cases for Cluster Roles

| Use Case | Description | Example Resources |
|----------|-------------|------------------|
| **Cluster Monitoring** | Systems like Prometheus, Grafana | nodes, pods, services across all namespaces |
| **Cluster Management** | Node management, cleanup jobs | nodes, persistentvolumes, namespaces |
| **Security Scanning** | Vulnerability scanners, policy engines | pods, deployments, networkpolicies cluster-wide |
| **CI/CD Systems** | Deployment pipelines across environments | deployments, services across namespaces |
| **Backup Solutions** | Cluster-wide backup and restore | all resources for backup purposes |

## Troubleshooting

### Common Issues and Solutions

1. **"Permission Denied" Errors**
   ```bash
   # Check what you can do
   kubectl auth can-i create nodes
   
   # Check what a specific user can do
   kubectl auth can-i create nodes --as username
   
   # Solution: User might need a ClusterRoleBinding to appropriate ClusterRole
   ```

2. **Cluster Role Binding Not Working**
   ```bash
   # Verify the cluster role exists
   kubectl get clusterrole cluster-role-name
   
   # Verify the binding is correct
   kubectl describe clusterrolebinding binding-name
   
   # Common issue: Wrong subject name or namespace for ServiceAccount
   ```

3. **Service Account Issues**
   ```bash
   # Check if service account exists
   kubectl get serviceaccount sa-name -n namespace
   
   # Check what bindings include this service account
   kubectl get clusterrolebindings -o wide | grep sa-name
   
   # Common issue: ServiceAccount in wrong namespace or doesn't exist
   ```

### Quick Debugging Checklist

- [ ] Does the ClusterRole exist? (`kubectl get clusterrole <name>`)
- [ ] Does the ClusterRoleBinding exist? (`kubectl get clusterrolebinding <name>`)
- [ ] Is the subject (user/SA/group) correctly specified?
- [ ] For ServiceAccounts: Is the namespace correct?
- [ ] Test permissions: `kubectl auth can-i <verb> <resource> --as <subject>`

## Summary

**Cluster Roles** are powerful tools for managing cluster-wide permissions in Kubernetes. Remember:

- Use them for cluster-scoped resources (nodes, PVs, namespaces)
- Use them when you need cross-namespace access
- Always follow the principle of least privilege
- Regularly audit who has what permissions
- Test permissions before applying them

**Next Steps**: Now that you understand Cluster Roles, you're ready to learn about Service Accounts and Network Policies!