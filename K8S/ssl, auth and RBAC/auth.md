# Kubernetes Authentication and Authorization Explained

## What is Authentication and Authorization?

### **Authentication** - "Who are you?"
Authentication is the process of **verifying the identity** of a user, service, or system trying to access the Kubernetes cluster[56][59][62].

### **Authorization** - "What can you do?"
Authorization is the process of **determining what actions** an authenticated user is permitted to perform on specific resources[56][59][62].

### Simple Analogy:
- **Authentication**: Showing your ID card to enter a building
- **Authorization**: Having permission to access specific floors/rooms inside

## Kubernetes Authentication Types

### 1. **X.509 Client Certificates**[39][31]

**How it works:**
- User generates private key and Certificate Signing Request (CSR)
- CSR signed by Kubernetes CA
- Certificate used for authentication

**Key Points:**
- ✅ Most secure method
- ✅ Built into Kubernetes
- ✅ Used by kubeadm by default
- ❌ Complex certificate management

**Example Commands:**
```bash
# Generate private key
openssl genrsa -out user.key 2048

# Create Certificate Signing Request
openssl req -new -key user.key -out user.csr

# Sign certificate with Kubernetes CA
openssl x509 -req -in user.csr -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key -out user.crt -days 30
```

### 2. **Service Account Tokens (JWT)**[44][38][31]

**How it works:**
- Kubernetes automatically creates JWT tokens for service accounts
- Tokens mounted into pods at `/var/run/secrets/kubernetes.io/serviceaccount/token`
- Used for pod-to-API server communication

**Key Points:**
- ✅ Automatic token management
- ✅ Perfect for applications/pods
- ✅ Time-limited tokens (enhanced security)
- ✅ Audience-bound tokens

**Types of Service Account Tokens:**
- **Legacy Tokens**: Stored in secrets (long-lived)
- **TokenRequest API**: Short-lived, bound tokens (recommended)

### 3. **OIDC (OpenID Connect) Tokens**[39][31]

**How it works:**
- External identity provider (Google, Azure AD, etc.) issues tokens
- Kubernetes validates tokens using OIDC provider's public keys
- Supports SSO integration

**Key Points:**
- ✅ Enterprise identity integration
- ✅ Single Sign-On (SSO) support
- ✅ External user management
- ❌ Requires external identity provider

### 4. **Webhook Authentication**[39][31]

**How it works:**
- External service validates authentication tokens
- Kubernetes calls webhook endpoint to verify credentials
- Flexible integration with custom auth systems

**Key Points:**
- ✅ Custom authentication logic
- ✅ Integration with existing systems
- ✅ Flexible implementation
- ❌ External dependency required

### 5. **Static Token Files**[14][31]

**How it works:**
- Predefined tokens stored in files on API server
- Tokens passed via Authorization header

**Key Points:**
- ❌ Not recommended for production
- ❌ Manual token management
- ❌ Requires API server restart for changes
- ✅ Simple for testing/development

### 6. **Bootstrap Tokens**[14][31]

**How it works:**
- Temporary tokens for cluster setup
- Used during node joining process
- Stored as secrets in kube-system namespace

**Key Points:**
- ✅ Cluster initialization
- ✅ Node joining automation
- ❌ Limited use case
- ❌ Should not be used for regular users

## Kubernetes Authorization Types

### 1. **RBAC (Role-Based Access Control)** - **RECOMMENDED**

**How it works:**
- Permissions organized into Roles and ClusterRoles
- Users/groups bound to roles via RoleBindings and ClusterRoleBindings
- Additive permissions model (no explicit deny)

**Key Components:**
- **Role**: Permissions within a namespace
- **ClusterRole**: Cluster-wide permissions
- **RoleBinding**: Links Role to users in a namespace
- **ClusterRoleBinding**: Links ClusterRole to users cluster-wide

**Key Points:**
- ✅ Industry standard approach
- ✅ Granular permissions
- ✅ Scalable for large organizations
- ✅ Default in most Kubernetes distributions

**Example RBAC:**
```yaml
# Role: Can read pods in 'development' namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]

# RoleBinding: Bind pod-reader role to user 'jane'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 2. **ABAC (Attribute-Based Access Control)**[43][47][31]

**How it works:**
- Access decisions based on attributes (user, resource, environment)
- Policies defined in JSON files
- More granular than RBAC but complex to manage

**Key Points:**
- ✅ Fine-grained access control
- ✅ Context-aware permissions
- ❌ Complex policy management
- ❌ Difficult to audit and debug

**Example Attributes:**
- User attributes: username, groups, department
- Resource attributes: namespace, labels, annotations
- Environment attributes: time, IP address, cluster

### 3. **Node Authorization**[61][55][31]

**How it works:**
- Special-purpose authorization for kubelet
- Allows kubelets to access only resources on their nodes
- Prevents cross-node resource access

**Key Points:**
- ✅ Secure kubelet operations
- ✅ Prevents cross-node access
- ✅ Principle of least privilege
- ✅ Automatic with proper setup

**Kubelet Permissions:**
- Read: pods, services, endpoints, secrets (node-bound)
- Write: node status, pod status, events
- Auth: certificate signing requests, token reviews

### 4. **Webhook Authorization**[54][57][31]

**How it works:**
- External service makes authorization decisions
- API server calls webhook with authorization request
- Webhook responds with allow/deny decision

**Key Points:**
- ✅ Custom authorization logic
- ✅ External policy engines (OPA, etc.)
- ✅ Integration with existing systems
- ❌ External dependency and latency

### 5. **AlwaysAllow / AlwaysDeny**[37][57]

**How it works:**
- AlwaysAllow: Permits all requests
- AlwaysDeny: Denies all requests

**Key Points:**
- ❌ Only for testing
- ❌ Never use in production
- ✅ Useful for troubleshooting

## Authentication vs Authorization Flow

### Step-by-Step Process:

#### Step 1: Request Arrives
```
User/Pod → kubectl/API call → Kubernetes API Server
```

#### Step 2: Authentication Phase
```
API Server → Authentication Plugins → Verify Identity
- X.509 certificates
- JWT tokens
- OIDC tokens
- Webhook auth
- Static tokens
```

#### Step 3: Authorization Phase
```
Authenticated Identity → Authorization Plugins → Check Permissions
- RBAC (most common)
- ABAC
- Node authorization
- Webhook authorization
```

#### Step 4: Admission Control
```
Authorized Request → Admission Controllers → Modify/Validate Request
- Resource quotas
- Pod security policies
- Network policies
```

#### Step 5: Action Execution
```
Validated Request → API Server → etcd → Resource Created/Modified
```

## Common Authentication Scenarios

### **Scenario 1: Human Users (kubectl)**
```bash
# Authentication: Client certificate
~/.kube/config contains:
- Client certificate
- Client private key
- Cluster CA certificate

# Authorization: RBAC
User bound to roles via RoleBindings
```

### **Scenario 2: Pods/Applications**
```bash
# Authentication: Service Account Token
Token mounted at: /var/run/secrets/kubernetes.io/serviceaccount/token

# Authorization: RBAC
ServiceAccount bound to roles via RoleBindings
```

### **Scenario 3: kubelet (Node Agent)**
```bash
# Authentication: Node client certificate
Certificate with CN: system:node:<node-name>

# Authorization: Node + RBAC
Node authorization for node-specific operations
RBAC for additional permissions
```

### **Scenario 4: External Systems**
```bash
# Authentication: OIDC tokens or Webhook
Integration with identity providers

# Authorization: RBAC or Webhook
Custom policies based on external attributes
```

## Best Practices

### **Authentication Best Practices:**
- ✅ Use X.509 certificates for cluster components
- ✅ Use Service Account tokens for pods
- ✅ Integrate with enterprise identity (OIDC)
- ✅ Regularly rotate certificates and tokens
- ❌ Avoid static tokens in production

### **Authorization Best Practices:**
- ✅ Use RBAC as primary authorization method
- ✅ Apply principle of least privilege
- ✅ Use namespaces for resource isolation
- ✅ Regular RBAC audits and cleanup
- ✅ Group users by roles, not individual permissions

### **Security Hardening:**
- ✅ Enable multiple authentication methods
- ✅ Use short-lived tokens when possible
- ✅ Monitor authentication failures
- ✅ Implement proper certificate lifecycle management
- ✅ Use admission controllers for additional security

## Common Commands

### **Check Authentication:**
```bash
# Check current user
kubectl auth whoami

# Test authentication
kubectl auth can-i create pods
kubectl auth can-i create pods --as=jane
kubectl auth can-i create pods --as=jane --namespace=development
```

### **RBAC Management:**
```bash
# List roles and bindings
kubectl get roles,rolebindings -A
kubectl get clusterroles,clusterrolebindings

# Describe specific RBAC objects
kubectl describe role pod-reader -n development
kubectl describe clusterrole cluster-admin
```

### **Service Account Management:**
```bash
# Create service account
kubectl create serviceaccount my-service-account

# Get service account token
kubectl create token my-service-account

# Bind service account to role
kubectl create rolebinding my-binding --role=pod-reader --serviceaccount=default:my-service-account
```

## Summary

### **Key Differences:**
| Aspect | Authentication | Authorization |
|--------|---------------|---------------|
| **Purpose** | Verify identity | Control access |
| **Question** | Who are you? | What can you do? |
| **Methods** | Certificates, Tokens, OIDC | RBAC, ABAC, Webhook |
| **Timing** | First step | Second step |
| **Failure** | Access denied | Permission denied |

### **Production Recommendations:**
- **Authentication**: X.509 certificates + OIDC integration
- **Authorization**: RBAC with regular audits
- **Service Accounts**: TokenRequest API with short-lived tokens
- **Monitoring**: Log authentication/authorization failures
- **Automation**: Use tools like cert-manager for certificate lifecycle

This security model ensures that only authenticated entities can access the cluster and they can only perform actions they're authorized for, maintaining a strong security posture in Kubernetes environments.