# Understanding Kubernetes Secrets

**Secrets** are similar to ConfigMaps but designed specifically for **sensitive data** like passwords, API keys, certificates, and tokens.

## What are Secrets?

**Secret = Secure storage for sensitive configuration data**

### Key Differences from ConfigMaps:

| ConfigMap | Secret |
| :-- | :-- |
| Plain text data | **Base64 encoded** data |
| Non-sensitive config | **Sensitive information** |
| Visible to everyone | **RBAC controlled** access |
| Database URLs, log levels | **Passwords, API keys, certificates** |

### Key Points:

- **Base64 encoded** (not encrypted, just obscured)
- **Access controlled** by Kubernetes RBAC
- **Automatically mounted** with restrictive permissions
- **Different types** for different use cases
- **Size limit**: 1MB per Secret


## When to Use Secrets?

### ✅ Use Secrets For:

- **Passwords** (database, user accounts)
- **API keys** and tokens
- **TLS certificates** and SSH keys
- **OAuth tokens**
- **Registry credentials** (Docker Hub, etc.)
- **Encryption keys**


### ❌ Don't Use Secrets For:

- Database hostnames or ports
- Log levels or feature flags
- Public configuration settings
- Non-sensitive environment variables

**Rule of thumb**: If you wouldn't want it in your Git repository, use a Secret!

## Types of Secrets

### 1. Generic Secrets (Most Common)

```bash
# Any key-value sensitive data
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=super-secret-123
```


### 2. Docker Registry Secrets

```bash
# For pulling private Docker images
kubectl create secret docker-registry my-registry-secret \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com \
  --docker-server=myregistry.com
```


### 3. TLS Secrets

```bash
# For HTTPS certificates
kubectl create secret tls my-tls-secret \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key
```


## Creating Secrets

### Imperative Commands

#### From Literal Values

```bash
kubectl create secret generic database-secret \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=mypassword123 \
  --from-literal=API_KEY=abc123xyz789
```


#### From Files

```bash
# Create files with sensitive data
echo -n 'admin' > username.txt
echo -n 'superSecret123' > password.txt

# Create secret from files
kubectl create secret generic file-secret \
  --from-file=username.txt \
  --from-file=password.txt
```


#### From Environment File

```bash
# Create .env file
echo "DB_USER=admin" > secret.env
echo "DB_PASSWORD=mypassword123" >> secret.env

kubectl create secret generic env-secret --from-env-file=secret.env
```


### Declarative YAML

#### Basic Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: basic-secret
  namespace: default
type: Opaque  # Generic secret type
data:
  # Values must be base64 encoded
  username: YWRtaW4=      # "admin" in base64
  password: bXlwYXNzd29yZDEyMw==  # "mypassword123" in base64
```


#### Using stringData (Easier)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: easy-secret
type: Opaque
stringData:  # Kubernetes automatically encodes these
  username: admin
  password: mypassword123
  api-key: abc123xyz789
  db-connection: "mysql://admin:mypassword123@db-server:3306/myapp"
```


#### Docker Registry Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJteXJlZ2lzdHJ5LmNvbSI6eyJ1c2VybmFtZSI6Im15dXNlciIsInBhc3N3b3JkIjoibXlwYXNzd29yZCIsImVtYWlsIjoibXllbWFpbEBleGFtcGxlLmNvbSIsImF1dGgiOiJiWGwxYzJWeU9tMTVjR0Z6YzNkdmNtUT0ifX19
```


## Using Secrets

### Method 1: Environment Variables

#### Single Environment Variable

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    env:
    - name: DATABASE_USER
      valueFrom:
        secretKeyRef:
          name: basic-secret
          key: username
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: basic-secret
          key: password
```


#### All Keys as Environment Variables

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-envfrom-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    envFrom:
    - secretRef:
        name: basic-secret
```


### Method 2: Volume Mounts

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: basic-secret
      defaultMode: 0400  # Read-only for owner only
```

**Result**: Files created at `/etc/secrets/username` and `/etc/secrets/password`

### Method 3: ImagePullSecrets (For Private Images)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  containers:
  - name: app
    image: myregistry.com/private/myapp:latest
  imagePullSecrets:
  - name: registry-secret
```


## Real-World Example: Web Application with Database

### 1. Create Database Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: production
type: Opaque
stringData:
  DB_HOST: "prod-mysql-cluster.example.com"
  DB_PORT: "3306"
  DB_NAME: "myapp_production"
  DB_USER: "app_user"
  DB_PASSWORD: "verySecurePassword123!"
  DB_ROOT_PASSWORD: "superSecretRootPass456!"
```


### 2. Create API Keys Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-secrets
  namespace: production
type: Opaque
stringData:
  STRIPE_API_KEY: "sk_live_abcdef123456"
  AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"
  AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  JWT_SECRET: "myJWTSecretKey123XYZ"
```


### 3. Create TLS Certificate Secret

```bash
kubectl create secret tls app-tls-secret \
  --cert=./app.crt \
  --key=./app.key \
  --namespace=production
```


### 4. Use Secrets in Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: myregistry.com/web-app:v2.1.0
        
        # Environment variables from secrets
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DB_HOST
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DB_PASSWORD
        
        # Load all API keys as env vars
        envFrom:
        - secretRef:
            name: api-secrets
        
        # Mount TLS certificates
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/ssl/certs/app
          readOnly: true
        
        ports:
        - containerPort: 8080
        - containerPort: 8443  # HTTPS port
        
      volumes:
      - name: tls-certs
        secret:
          secretName: app-tls-secret
      
      # For pulling private images
      imagePullSecrets:
      - name: registry-secret
```


## Useful Commands

### View Secrets

```bash
# List secrets
kubectl get secrets

# Describe secret (won't show values)
kubectl describe secret basic-secret

# View secret YAML (base64 encoded values)
kubectl get secret basic-secret -o yaml

# Decode secret value
kubectl get secret basic-secret -o jsonpath='{.data.username}' | base64 -d
```


### Update Secrets

```bash
# Edit secret
kubectl edit secret basic-secret

# Update specific key
kubectl patch secret basic-secret -p '{"stringData":{"password":"newPassword123"}}'

# Replace from file
kubectl replace -f updated-secret.yaml
```


### Create Base64 Values Manually

```bash
# Encode value
echo -n 'mypassword' | base64
# Output: bXlwYXNzd29yZA==

# Decode value
echo 'bXlwYXNzd29yZA==' | base64 -d
# Output: mypassword
```


## Best Practices

### 1. Use stringData for Creation

```yaml
# ✅ Good - Easy to read and maintain
stringData:
  password: "mySecretPassword"

# ❌ Avoid - Hard to maintain
data:
  password: "bXlTZWNyZXRQYXNzd29yZA=="
```


### 2. Proper File Permissions

```yaml
volumes:
- name: secret-volume
  secret:
    secretName: my-secret
    defaultMode: 0400  # Read-only for owner
```


### 3. Use Specific Keys

```yaml
# ✅ Good - Only mount what you need
volumes:
- name: db-credentials
  secret:
    secretName: database-secret
    items:
    - key: password
      path: db-password
      mode: 0400
```


### 4. Separate Secrets by Purpose

```bash
# ✅ Good organization
database-secret       # Database credentials
api-keys-secret      # External API keys
tls-certificates     # SSL/TLS certs
registry-credentials # Docker registry
```


### 5. Use Namespaces for Isolation

```yaml
# Production secrets
metadata:
  name: app-secret
  namespace: production

# Development secrets  
metadata:
  name: app-secret
  namespace: development
```


## Security Considerations

### ⚠️ Important Security Notes:

1. **Secrets are base64 encoded, NOT encrypted**
    - Anyone with cluster access can decode them
    - Use external secret management for high security
2. **RBAC is crucial**

```yaml
# Limit who can read secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
```

3. **Avoid logging secrets**

```yaml
env:
- name: DEBUG_MODE
  value: "false"  # Don't log env vars in production
```

4. **Use external secret management**
    - AWS Secrets Manager
    - HashiCorp Vault
    - Azure Key Vault
    - External Secrets Operator

## Troubleshooting

### Common Issues

1. **Base64 encoding problems**

```bash
# Wrong: includes newline
echo 'password' | base64

# Correct: no newline
echo -n 'password' | base64
```

2. **Secret key not found**

```bash
kubectl describe secret my-secret  # Check available keys
```

3. **Permission denied**

```bash
# Check secret file permissions in pod
kubectl exec pod-name -- ls -la /etc/secrets/
```


## Quick Reference Commands

```bash
# Create generic secret
kubectl create secret generic NAME --from-literal=key=value

# Create from file
kubectl create secret generic NAME --from-file=path/to/file

# Create docker registry secret
kubectl create secret docker-registry NAME \
  --docker-username=USER --docker-password=PASS

# View secret keys (not values)
kubectl get secret NAME -o yaml

# Decode secret value
kubectl get secret NAME -o jsonpath='{.data.KEY}' | base64 -d

# Delete secret
kubectl delete secret NAME
```

**Key Takeaway**: Secrets are for **sensitive data** that you don't want exposed. They provide **better security** than ConfigMaps through access controls and proper file permissions, but remember they're **base64 encoded, not encrypted**. For production systems, consider using external secret management solutions for additional security layers.

