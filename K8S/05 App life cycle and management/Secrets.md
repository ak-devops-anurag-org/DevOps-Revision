### **Kubernetes Secrets: Quick Revision Notes**

**What is it?**
A Kubernetes Secret is an object that lets you store and manage sensitive information, such as passwords, OAuth tokens, and SSH keys, separately from your Pod definitions and container images.

**Why do we need it?**

* **Security:** Keeps sensitive data out of your application code and Git repositories.
* **Flexibility:** Allows you to update passwords or keys without needing to rebuild your Docker images or recreate your Pods.

---

### **1. The Golden Rule of YAML Secrets: `data` vs. `stringData**`**

When defining Secrets declaratively in YAML, this is the most common area for mistakes.

* **`data`**: Used for **Base64 encoded** values. You must encode your values before pasting them here.
* **`stringData`**: Used for **plain-text** values. Kubernetes will automatically Base64 encode these for you when the object is created. *This is highly preferred for manual YAML creation.*

**Real-World Example (Database Credentials):**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cep-db-secret 
type: Opaque  # 'Opaque' is the default type for arbitrary key-value pairs
stringData:
  # Using stringData means we write plain text here!
  username: db_admin
  password: SuperSecurePassword123!

```

---

### **2. How to Create Secrets (Imperative vs. Declarative)**

While YAML (Declarative) is best for tracking in version control, the command line (Imperative) is incredibly useful for quickly generating secrets without accidentally saving plain-text files on your hard drive.

**Imperative (Command Line):**

```bash
kubectl create secret generic cep-db-secret \
  --from-literal=username=db_admin \
  --from-literal=password=SuperSecurePassword123!

```

**Declarative (YAML):**

```bash
kubectl apply -f my-secret.yaml

```

---

### **3. How to Consume Secrets in a Pod**

Once the Secret exists in the cluster, your application needs to use it. There are two primary ways to inject a Secret into a container:

#### **Method A: As Environment Variables (`env` vs. `envFrom`)**

This is the most common approach for web applications and database connections. You have two options here depending on your needs:

* **`env` (with `valueFrom`):** Use this to cherry-pick **specific** keys from a Secret. You must map every single variable one by one. This is best if you only need one specific password or if you need to rename the variable for your application.
* **`envFrom`:** Use this when you want to take **every single key-value pair** inside a Secret and dump them all into the container automatically. It makes your YAML much cleaner. The keys in your Secret (e.g., `DB_User`) become the exact environment variable names inside the container.

**Real-World Example (`envFrom` - The Clean Bulk Method):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-backend-app
spec:
  containers:
  - name: backend-container
    image: my-company/backend:v1
    # Dumps all keys from cep-db-secret into the container
    envFrom:
    - secretRef:
        name: cep-db-secret 

```

**Real-World Example (`env` - The Specific Mapping Method):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-backend-app
spec:
  containers:
  - name: backend-container
    image: my-company/backend:v1
    env:
      # Injecting and potentially renaming a specific key
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: cep-db-secret
            key: password

```

#### **Method B: Mounted as a Data Volume**

Best for configuration files or TLS certificates that the application expects to read from a physical file path.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-container
    image: my-company/app:v1
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/secrets"
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: cep-db-secret

```

*Result: The container will have a physical file at `/etc/secrets/username` and `/etc/secrets/password`.*

---

### **4. Crucial Security Realities**

* **Base64 is NOT Encryption:** The default Kubernetes Secret is just encoded, not encrypted. Anyone with access to the cluster (or the `etcd` database) can decode it instantly (`echo "cGFzc3dvcmQ=" | base64 --decode`).
* **Never commit Secrets to Git:** If you use `stringData` in a YAML file, do not push that file to GitHub or GitLab.
* **Use RBAC:** Restrict which users and service accounts are allowed to run `kubectl get secrets`.


You are completely right, that is a crucial omission for real-world application. Let's add that section to your revision notes.

Here is the breakdown of the most common Kubernetes Secret types and exactly when you would use them in a production setting.

---

### **5. Types of Kubernetes Secrets (Real-World Scenarios)**

While you can technically shove any data into the default secret type, Kubernetes provides built-in types to enforce specific data structures for common use cases. This prevents configuration errors before they reach the Pod.

#### **Type 1: `Opaque` (The Default)**

This is the standard, arbitrary key-value pair secret. If you don't specify a `type` in your YAML, it defaults to `Opaque`.

* **When to use it:** For standard application credentials, API keys, or custom configuration tokens.
* **Real-World Scenario:** Storing the PostgreSQL username and password required to establish a connection from your GKE pods to the backend Cloud SQL database for the corporate employee portal.
* **Example structure:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cep-prod-db-credentials
type: Opaque
stringData:
  username: db_admin
  password: secure_password_here

```



#### **Type 2: `kubernetes.io/dockerconfigjson` (Registry Authentication)**

This type is exclusively used to authenticate your Kubernetes cluster with a private container registry.

* **When to use it:** Whenever your deployment needs to pull a proprietary Docker image from a private registry (like Google Artifact Registry, AWS ECR, or a private Docker Hub account).
* **Real-World Scenario:** Deploying the `hbl-uat-cep-prj` application. Since the bank's application code is proprietary, the container image cannot be public. You create this secret containing the registry credentials, and then tell your Deployment to use it via the `imagePullSecrets` field.
* **Example (Command Line is best here):**
```bash
kubectl create secret docker-registry my-private-registry-secret \
  --docker-server=https://gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat service-account-key.json)"

```



#### **Type 3: `kubernetes.io/tls` (SSL/TLS Certificates)**

This type strictly enforces that the secret contains exactly two keys: `tls.crt` (the public certificate) and `tls.key` (the private key).

* **When to use it:** To enable HTTPS/SSL termination for your web applications.
* **Real-World Scenario:** Securing the frontend ingress of the employee portal. You want to ensure that all traffic accessing the portal is encrypted in transit. You load the SSL certificate into this secret, and the Kubernetes Ingress controller automatically reads it to secure the domain.
* **Example structure:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cep-tls-cert
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-public-cert>
  tls.key: <base64-encoded-private-key>

```



#### **Type 4: `kubernetes.io/service-account-token` (System Auth)**

* **When to use it:** You rarely create these manually anymore (modern Kubernetes handles this via the TokenRequest API), but you will see them in the cluster. They are used by Pods to talk securely to the Kubernetes API server itself.
* **Real-World Scenario:** If you are running an auditing or security tool inside your cluster (like a Prisma Cloud Defender) that needs permission to query the API server to generate a CSPM report on your GKE workloads, it uses a service account token to prove its identity.

---


### External Secret Vault

Implementing an External Secret Vault (like GCP Secret Manager with the External Secrets Operator) **does not** resolve the `kubectl exec` security loophole.

If a user can run `kubectl exec webapp-pod -- env`, they will still be able to see the plain-text passwords, regardless of whether the secret originated from GCP or a manual YAML file.

---

### Why doesn't it fix the issue?

To understand why, you have to look at how the External Secrets Operator (ESO) works under the hood.

ESO is a "bridge." Its entire job is to securely fetch a secret from GCP and **create a standard Kubernetes `Secret` object** inside your cluster.

Once ESO creates that native Kubernetes Secret, the Pod mounts it exactly as it always has (via `env`, `envFrom`, or a volume mount). Because the application running inside the container needs the actual plain-text password to connect to the database, the password *must* exist unencrypted in the container's environment or filesystem.

Therefore, anyone with `exec` access into that container can still read it.

### What does an External Vault actually solve?

It is crucial to understand that External Vaults solve a different set of security problems:

* **The GitOps Problem:** It ensures no plain-text passwords or Base64 strings are ever committed to your Git repositories.
* **The `etcd` Sprawl Problem:** It ensures your Kubernetes database (`etcd`) isn't the authoritative master source of your company's most sensitive credentials.
* **The Rotation & Auditing Problem:** It allows your security team to centrally rotate passwords and audit access logs in a unified cloud dashboard (like GCP), rather than hunting through individual Kubernetes clusters.

### How do you actually fix the `exec` loophole?

To close the `exec` vulnerability, you must address access at the Kubernetes API and Node levels.

1. **Strict RBAC on `exec`:** You must explicitly deny or simply not grant `create` permissions on the `pods/exec` subresource in your RBAC Roles. In production, no human should have `exec` access.
2. **Admission Controllers (Gatekeeper / Kyverno):**
You can write policies that block users from creating *new* Pods that mount sensitive secrets. This prevents an attacker from deploying a dummy pod just to mount the secret and steal it.
3. **Application-Level Fetching (Advanced):**
Instead of mounting the secret into the Pod's environment variables via Kubernetes, the application code itself is written to authenticate directly with GCP Secret Manager (using Workload Identity) and fetch the password into memory at runtime. This bypasses Kubernetes Secrets entirely, meaning `kubectl exec -- env` will show nothing.

---

### Using Secrets with static Pods
You cannot use ConfigMaps or Secrets with static Pods.

### Immutable Secrets

Kubernetes lets you mark specific Secrets (and ConfigMaps) as immutable. Preventing changes to the data of an existing Secret has the following benefits:

protects you from accidental (or unwanted) updates that could cause applications outages

Marking a Secret as immutable
You can create an immutable Secret by setting the immutable field to true. For example,

```yaml
apiVersion: v1
kind: Secret
metadata: ...
  data: ...
  immutable: true
```
