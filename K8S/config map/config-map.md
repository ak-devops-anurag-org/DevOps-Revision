# ConfigMap Complete Guide for Revision

## Understanding Key Concepts

### 1. "Easy Configuration Changes Without Rebuilding Images"

**Traditional Problem:**

```dockerfile
# Bad approach - hardcoded in Dockerfile
ENV DATABASE_URL="mysql://prod-server:3306/db"
ENV API_KEY="hardcoded-key-123"
```

**With this approach:**

- Need to **rebuild Docker image** for each configuration change
- **Separate images** for dev/staging/prod environments
- **Slow deployment** process (build → push → deploy)

**ConfigMap Solution:**

```yaml
# Same image, different ConfigMaps
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-prod
data:
  DATABASE_URL: "mysql://prod-server:3306/db"
  API_KEY: "prod-key-456"
```

**Benefits:**

- **One image** works everywhere
- **Change config** → just update ConfigMap → restart pods
- **No rebuilding** or re-pushing images


### 2. Reusable Settings Across Environments

Here's how to use **same application** with **different configurations**:

#### Development Environment

```yaml
# dev-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: development
data:
  DATABASE_URL: "mysql://dev-db:3306/myapp_dev"
  API_KEY: "dev-api-key-123"
  LOG_LEVEL: "debug"
  CACHE_SIZE: "100"
  FEATURE_FLAGS: "all_enabled"
```


#### Staging Environment

```yaml
# staging-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: staging
data:
  DATABASE_URL: "mysql://staging-db:3306/myapp_staging"
  API_KEY: "staging-api-key-456"
  LOG_LEVEL: "info"
  CACHE_SIZE: "500"
  FEATURE_FLAGS: "limited_features"
```


#### Production Environment

```yaml
# prod-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  DATABASE_URL: "mysql://prod-db-cluster:3306/myapp"
  API_KEY: "prod-api-key-789"
  LOG_LEVEL: "error"
  CACHE_SIZE: "1000"
  FEATURE_FLAGS: "stable_only"
```


#### Single Deployment Template for All Environments

```yaml
# app-deployment.yaml (same for all environments)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app:v1.2.0  # Same image everywhere!
        envFrom:
        - configMapRef:
            name: app-config  # Same ConfigMap name, different content
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_URL
```

**Deploy to different environments:**

```bash
# Deploy to dev
kubectl apply -f dev-config.yaml -n development
kubectl apply -f app-deployment.yaml -n development

# Deploy to staging  
kubectl apply -f staging-config.yaml -n staging
kubectl apply -f app-deployment.yaml -n staging

# Deploy to production
kubectl apply -f prod-config.yaml -n production
kubectl apply -f app-deployment.yaml -n production
```


***

# Complete ConfigMap Documentation

## Table of Contents

1. [What is ConfigMap?](#what-is-configmap)
2. [Creating ConfigMaps](#creating-configmaps)
3. [Using ConfigMaps](#using-configmaps)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)

## What is ConfigMap?

**ConfigMap** = External configuration storage for Kubernetes applications

### Key Features:

- **Stores key-value pairs** (text data only)
- **Decouples configuration** from container images
- **Hot-swappable** configurations
- **Namespace-scoped** resource
- **Non-confidential data only** (use Secrets for passwords)

***

## Creating ConfigMaps

### Imperative Commands

#### 1. From Literal Values

```bash
kubectl create configmap app-config \
  --from-literal=DATABASE_URL="mysql://localhost:3306/mydb" \
  --from-literal=API_KEY="api-key-123" \
  --from-literal=DEBUG_MODE="true"
```


#### 2. From Environment File

```bash
# Create app.properties file first
echo "DATABASE_URL=mysql://localhost:3306/mydb" > app.properties
echo "API_KEY=api-key-123" >> app.properties
echo "DEBUG_MODE=true" >> app.properties

# Create ConfigMap from env file
kubectl create configmap app-config --from-env-file=app.properties
```


#### 3. From Regular Files

```bash
# Create nginx.conf file
echo "server { listen 80; }" > nginx.conf

# Create ConfigMap from file
kubectl create configmap nginx-config --from-file=nginx.conf

# Multiple files
kubectl create configmap web-config \
  --from-file=nginx.conf \
  --from-file=app.properties
```


#### 4. From Directory

```bash
# Create ConfigMap from all files in directory
mkdir config-files
echo "key1=value1" > config-files/app.env
echo "server { listen 80; }" > config-files/nginx.conf

kubectl create configmap dir-config --from-file=config-files/
```


### Declarative YAML

#### Basic ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: basic-config
  namespace: default
data:
  # Simple key-value pairs
  database_host: "mysql-server"
  database_port: "3306"
  log_level: "info"
```


#### ConfigMap with File Content

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: file-config
data:
  # Configuration file content
  nginx.conf: |
    server {
        listen 80;
        server_name example.com;
        
        location / {
            proxy_pass http://backend;
        }
    }
  
  app.properties: |
    database.host=localhost
    database.port=5432
    database.name=myapp
    
  config.json: |
    {
      "api": {
        "version": "v1",
        "timeout": 30
      },
      "features": {
        "authentication": true,
        "caching": false
      }
    }
```


***

## Using ConfigMaps

### Method 1: Environment Variables

#### Single Environment Variable

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: basic-config
          key: database_host
    - name: DATABASE_PORT
      valueFrom:
        configMapKeyRef:
          name: basic-config
          key: database_port
```


#### All Keys as Environment Variables

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: envfrom-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: basic-config
```


### Method 2: Volume Mounts - pod will not restart even if we update the config file

#### Mount All Files

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: file-config
```


#### Mount Specific Files

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: selective-volume-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/conf.d/default.conf
      subPath: nginx.conf
  volumes:
  - name: nginx-config
    configMap:
      name: file-config
      items:
      - key: nginx.conf
        path: nginx.conf
```


### Method 3: Combined Usage

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: full-example-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: full-example
  template:
    metadata:
      labels:
        app: full-example
    spec:
      containers:
      - name: web-server
        image: nginx:alpine
        
        # Environment variables from ConfigMap
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: basic-config
              key: log_level
        
        # All env vars from ConfigMap
        envFrom:
        - configMapRef:
            name: basic-config
        
        # Mount config files
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/
        - name: app-config
          mountPath: /app/config/
          
      volumes:
      - name: nginx-config
        configMap:
          name: file-config
          items:
          - key: nginx.conf
            path: default.conf
      - name: app-config
        configMap:
          name: file-config
          items:
          - key: app.properties
            path: application.properties
```


***

## Useful Commands

### View ConfigMaps

```bash
# List all ConfigMaps
kubectl get configmaps

# Describe ConfigMap
kubectl describe configmap basic-config

# View ConfigMap YAML
kubectl get configmap basic-config -o yaml

# View specific key
kubectl get configmap basic-config -o jsonpath='{.data.database_host}'
```


### Update ConfigMaps

```bash
# Edit ConfigMap
kubectl edit configmap basic-config

# Replace from file
kubectl replace -f updated-configmap.yaml

# Patch specific key
kubectl patch configmap basic-config -p '{"data":{"new_key":"new_value"}}'
```


### Delete ConfigMaps

```bash
kubectl delete configmap basic-config
```


***

## Best Practices

### 1. Naming Conventions

```bash
# Good naming patterns
app-config-dev
app-config-staging
app-config-prod
nginx-config-v1
database-config-mysql
```


### 2. Organization Strategies

#### By Environment

```yaml
# Separate ConfigMaps per environment
metadata:
  name: app-config
  namespace: development
---
metadata:
  name: app-config
  namespace: production
```


#### By Component

```yaml
# Separate ConfigMaps per service
metadata:
  name: database-config
---
metadata:
  name: cache-config
---
metadata:
  name: api-config
```


### 3. Security Considerations

```yaml
# ❌ DON'T store secrets in ConfigMaps
data:
  password: "mysecretpassword"  # Visible in plain text!

# ✅ DO use Secrets for sensitive data
# Use ConfigMap for non-sensitive configuration only
data:
  database_host: "mysql-server"
  log_level: "info"
```


### 4. Size Limitations

- **Maximum size**: 1MB per ConfigMap
- **Best practice**: Keep ConfigMaps small and focused
- **Split large configs** into multiple ConfigMaps

***

## Troubleshooting

### Common Issues

#### 1. ConfigMap Not Found

```bash
# Error: configmap "app-config" not found
kubectl get configmap  # Check if ConfigMap exists
kubectl get configmap -n <namespace>  # Check correct namespace
```


#### 2. Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Common issues:
# - ConfigMap key doesn't exist
# - ConfigMap in wrong namespace
# - Invalid file permissions
```


#### 3. Configuration Not Updating

```bash
# ConfigMap changes don't automatically restart pods
kubectl rollout restart deployment/<deployment-name>

# Or delete pods to force restart
kubectl delete pod -l app=<your-app>
```


#### 4. File Permission Issues

```yaml
# Set specific file permissions
volumes:
- name: config-volume
  configMap:
    name: file-config
    defaultMode: 0644  # rw-r--r--
```


### Debugging Commands

```bash
# Check ConfigMap content
kubectl get configmap <name> -o yaml

# Check pod environment variables
kubectl exec <pod-name> -- env

# Check mounted files
kubectl exec <pod-name> -- ls -la /path/to/mounted/config
kubectl exec <pod-name> -- cat /path/to/config/file

# Check pod configuration
kubectl get pod <pod-name> -o yaml | grep -A 20 configMap
```


***

## Real-World Example: Multi-Environment Web Application

### Directory Structure

```
project/
├── configs/
│   ├── dev-config.yaml
│   ├── staging-config.yaml
│   └── prod-config.yaml
├── app-deployment.yaml
└── nginx-configmap.yaml
```


### Complete Example Files

#### configs/dev-config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: development
data:
  # Database settings
  DATABASE_HOST: "dev-mysql"
  DATABASE_PORT: "3306"
  DATABASE_NAME: "myapp_dev"
  
  # API settings
  API_BASE_URL: "https://api-dev.example.com"
  API_TIMEOUT: "30"
  
  # Feature flags
  FEATURE_NEW_UI: "true"
  FEATURE_ANALYTICS: "false"
  
  # Logging
  LOG_LEVEL: "debug"
  LOG_FORMAT: "json"
  
  # Application config file
  app.yaml: |
    server:
      port: 8080
      host: "0.0.0.0"
    
    database:
      pool_size: 10
      timeout: 30
    
    cache:
      enabled: false
      ttl: 300
```


#### configs/prod-config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  # Database settings
  DATABASE_HOST: "prod-mysql-cluster"
  DATABASE_PORT: "3306"
  DATABASE_NAME: "myapp"
  
  # API settings
  API_BASE_URL: "https://api.example.com"
  API_TIMEOUT: "10"
  
  # Feature flags
  FEATURE_NEW_UI: "false"
  FEATURE_ANALYTICS: "true"
  
  # Logging
  LOG_LEVEL: "warn"
  LOG_FORMAT: "structured"
  
  # Application config file
  app.yaml: |
    server:
      port: 8080
      host: "0.0.0.0"
    
    database:
      pool_size: 50
      timeout: 10
    
    cache:
      enabled: true
      ttl: 3600
```


#### app-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
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
        image: my-web-app:v2.1.0
        
        # Environment variables from ConfigMap
        envFrom:
        - configMapRef:
            name: app-config
        
        # Mount configuration file
        volumeMounts:
        - name: app-config-volume
          mountPath: /app/config/
        
        ports:
        - containerPort: 8080
        
      volumes:
      - name: app-config-volume
        configMap:
          name: app-config
          items:
          - key: app.yaml
            path: application.yaml
```


### Deployment Commands

```bash
# Deploy to development
kubectl apply -f configs/dev-config.yaml
kubectl apply -f app-deployment.yaml -n development

# Deploy to production
kubectl apply -f configs/prod-config.yaml
kubectl apply -f app-deployment.yaml -n production

# Update configuration (example: change log level in prod)
kubectl patch configmap app-config -n production \
  -p '{"data":{"LOG_LEVEL":"error"}}'

# Restart deployment to pick up changes
kubectl rollout restart deployment/web-app -n production
```

This comprehensive guide covers all aspects of ConfigMaps for your revision. The key benefits are **flexibility**, **reusability**, and **separation of configuration from code**, making your applications much easier to manage across different environments.

