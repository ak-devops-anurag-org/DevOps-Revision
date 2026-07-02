# Kubernetes Application Lifecycle Management: Core Revision Notes

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
    type: RollingUpdate    # Recreate, RollingUpdate (default)
    rollingUpdate:
      maxSurge: 1       # Can create 1 extra pod during update (Total 5)
      maxUnavailable: 1 # Can take down 1 old pod at a time (Leaves 3 running)
  # ... (selector and template)
```

---

## 2. Commands and Arguments (Docker vs. Kubernetes)
* **Concept:** When a container starts, it runs a default command. You often need to override this behavior.
* **The Confusion:** Docker and Kubernetes use different names for the exact same things.
  * **Docker `ENTRYPOINT`** = **Kubernetes `command`** (The actual executable to run).
  * **Docker `CMD`** = **Kubernetes `args`** (The parameters fed to the executable).

**Example `pod-cmd-args.yaml`**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    # Overriding the default startup behavior
    command: ["sleep"] # The executable
    args: ["3600"]     # The argument passed to 'sleep'
```

---

## 3. Environment Variables and ConfigMaps
* **Concept:** You should never hardcode configuration (like database URLs or port numbers) inside your application code. 
* **ConfigMap:** A K8s object used to store non-sensitive, plain-text configuration data. You can inject this data into your Pods as Environment Variables or mount them as files.

**Step 1: Create the ConfigMap (`configmap.yaml`)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_URL: "mysql-service.database.svc.cluster.local"
  APP_PORT: "8080"
```

**Step 2: Use it in a Pod (`pod-with-cm.yaml`)**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: my-app:latest
    # Injecting ALL data from the ConfigMap as Environment Variables
    envFrom:
    - configMapRef:
        name: app-config
```

---

## 4. Environment Variables and Secrets
* **Concept:** Exactly like ConfigMaps, but used for **sensitive data** (passwords, API keys, SSH keys).
* **Important Security Note:** By default, Secrets are *not* encrypted in Kubernetes! They are only **Base64 encoded** to handle special characters. Anyone with access to the K8s API can decode them. (In production, you must configure "Encryption at Rest" for ETCD, or use tools like HashiCorp Vault).
* **Pro-Tip:** Instead of manually encoding strings to Base64, you can use `stringData` in your YAML, and K8s will encode it for you upon creation.

**Step 1: Create the Secret (`secret.yaml`)**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque # Default type for arbitrary key-value pairs
stringData:  # Lets you type plain text; K8s will encode it for you
  DB_USER: "admin"
  DB_PASS: "SuperSecretPassword123"
```

**Step 2: Use it in a Pod (`pod-with-secret.yaml`)**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-app
spec:
  containers:
  - name: app
    image: my-backend:latest
    env:
    # Injecting a SINGLE specific key from the Secret
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DB_PASS
```
```