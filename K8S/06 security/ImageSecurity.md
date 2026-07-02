# Image Security - Revision Notes

## Table of Contents
1. [Image Naming Convention](#image-naming-convention)
2. [Private Registry](#private-registry)
3. [imagePullSecret](#imagepullsecret)
4. [imagePullPolicy](#imagepullpolicy)
5. [Key Commands](#key-commands)
6. [Quick Reference](#quick-reference)

---

## Image Naming Convention

When you specify an image in a pod spec, Kubernetes resolves the full image path:

```
[registry/][repository/]image[:tag]
```

| What you write       | What K8S actually pulls                          |
|----------------------|--------------------------------------------------|
| `nginx`              | `docker.io/library/nginx:latest`                 |
| `nginx:1.25`         | `docker.io/library/nginx:1.25`                   |
| `myorg/myapp`        | `docker.io/myorg/myapp:latest`                   |
| `gcr.io/myapp:v1`   | `gcr.io/myapp:v1` (GCR registry)                 |
| `private.reg.io/app` | `private.reg.io/app:latest` (private registry)   |

> Default registry is **`docker.io`**. Default tag is **`latest`**.

---

## Private Registry

To pull images from a **private registry**, Kubernetes needs credentials.

### Step 1 — Create a `docker-registry` Secret

```bash
kubectl create secret docker-registry regcred \
  --docker-server=private.registry.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=me@example.com
```

This creates a Secret of type `kubernetes.io/dockerconfigjson`.

### Step 2 — Reference the Secret in the Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-app
spec:
  containers:
  - name: app
    image: private.registry.io/myapp:v1
  imagePullSecrets:           # 👈 reference the secret here
  - name: regcred
```

---

## imagePullSecret

`imagePullSecrets` is a pod-level field — it tells the kubelet which credentials to use when pulling images.

```yaml
spec:
  imagePullSecrets:
  - name: regcred        # name of the docker-registry secret
```

### Attaching to a Service Account (Preferred for reuse)

Instead of adding `imagePullSecrets` to every pod, attach it to a **Service Account**:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
imagePullSecrets:
- name: regcred          # all pods using this SA will use this secret
```

> Any pod using `my-app-sa` will automatically use `regcred` to pull images — no need to repeat it per pod.

---

## imagePullPolicy

Controls **when** Kubernetes pulls the image.

```yaml
spec:
  containers:
  - name: app
    image: nginx:1.25
    imagePullPolicy: IfNotPresent   # 👈 set pull policy
```

| Policy          | Behaviour                                                         |
|-----------------|-------------------------------------------------------------------|
| `Always`        | Always pull from registry (even if already cached on node)        |
| `IfNotPresent`  | Pull only if image is NOT already on the node *(default for tagged images)* |
| `Never`         | Never pull — use only what is already on the node                 |

> If tag is `latest` or omitted, default policy is **`Always`**.  
> If a specific tag is given, default is **`IfNotPresent`**.

---

## Key Commands

```bash
# Create a private registry secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<user> \
  --docker-password=<pass>

# Verify the secret was created
kubectl get secret regcred
kubectl describe secret regcred

# View the secret content (base64 encoded)
kubectl get secret regcred -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# List secrets of docker-registry type
kubectl get secrets --field-selector type=kubernetes.io/dockerconfigjson
```

---

## Quick Reference

| Task                             | How                                                          |
|----------------------------------|--------------------------------------------------------------|
| Pull from private registry       | Create `docker-registry` secret + add `imagePullSecrets`    |
| Reuse pull creds for all pods    | Attach `imagePullSecrets` to a ServiceAccount                |
| Always pull fresh image          | `imagePullPolicy: Always`                                    |
| Use locally cached image         | `imagePullPolicy: IfNotPresent`                              |
| Never pull from registry         | `imagePullPolicy: Never`                                     |

---

## Summary

- Full image path = `registry/repo/image:tag` — defaults to `docker.io` and `latest`
- Use `kubectl create secret docker-registry` to store private registry credentials
- Reference the secret in pod spec via `imagePullSecrets`
- Attach `imagePullSecrets` to a **ServiceAccount** to avoid repeating it on every pod
- `imagePullPolicy` controls when the image is pulled — default varies by tag
