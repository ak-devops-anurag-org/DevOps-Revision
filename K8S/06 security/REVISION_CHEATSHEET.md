# K8S Security — Revision Cheatsheet
### Feynman Technique: Explain it simply, test it, then know where it breaks.

> **Topics covered:** TLS/Auth/CSR · KubeConfig · RBAC · ClusterRoles · Service Accounts · Image Security · Security Context · Network Policies

---

## 📋 Index

| # | Topic | Page |
|---|-------|------|
| 1 | [TLS, Auth & CSR](#1-tls-auth--csr) | ↓ |
| 2 | [KubeConfig](#2-kubeconfig) | ↓ |
| 3 | [RBAC — Role & RoleBinding](#3-rbac--role--rolebinding) | ↓ |
| 4 | [ClusterRole & ClusterRoleBinding](#4-clusterrole--clusterrolebinding) | ↓ |
| 5 | [Service Account](#5-service-account) | ↓ |
| 6 | [Image Security](#6-image-security) | ↓ |
| 7 | [Security Context](#7-security-context) | ↓ |
| 8 | [Network Policies](#8-network-policies) | ↓ |

---

## 1. TLS, Auth & CSR

### 🗣️ Elevator Pitch
> *"Before anything happens in Kubernetes, every component must prove who it is. The API server, kubelet, etcd — they all talk over TLS. Your CA is the single source of trust. When you want to add a new user, you generate a private key, create a signing request (CSR), submit it to K8S, get it approved, and now that user has a cert the cluster trusts. RBAC then decides what they can do."*

**The flow:** `Private Key → CSR → Submit to K8S → Approve → Cert → Add to KubeConfig`

**Auth methods ranked (best → worst):**
- ✅ Client certificates (`--client-ca-file`)
- ✅ Bearer tokens (OIDC, ServiceAccount tokens)
- ⚠️  Static token file (`--token-auth-file`) — avoid in prod
- ❌ Basic auth CSV — deprecated

### 🖥️ CLI Commands to Test It
```bash
# Generate key + CSR
openssl genrsa -out myuser.key 2048
openssl req -new -key myuser.key -out myuser.csr -subj "/CN=myuser/O=developers"

# Encode CSR and submit to K8S
cat myuser.csr | base64 -w 0   # paste this into the YAML below

# Apply the CSR object
kubectl apply -f myuser-csr.yaml

# List CSRs and their status
kubectl get csr

# Approve the CSR
kubectl certificate approve myuser-csr

# Retrieve the signed certificate
kubectl get csr myuser-csr -o jsonpath='{.status.certificate}' | base64 --decode > myuser.crt

# Inspect a certificate (check expiry, SANs, CN)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
openssl x509 -in myuser.crt -noout -dates
```

### 💥 Top 3 Production Breaks
1. **Expired certificates** — The API server or etcd cert expires silently. `kubectl` starts throwing `x509: certificate has expired`. Fix: `kubeadm certs renew all` or `openssl x509 -noout -dates` to check ahead of time.
2. **Missing SAN on API server cert** — You access the cluster via a new IP or DNS name not listed in the cert's Subject Alternative Names. Clients get `x509: certificate is valid for X, not Y`. Fix: Regenerate the cert with all required SANs.
3. **CSR stuck in `Pending`** — Someone generated a CSR but forgot to approve it. The user can't authenticate. Fix: `kubectl get csr` and `kubectl certificate approve <name>`. In production, automate approvals via the controller manager or an approval controller.

---

## 2. KubeConfig

### 🗣️ Elevator Pitch
> *"KubeConfig is your kubectl's address book. It holds three lists: clusters (where to connect), users (credentials), and contexts (a named shortcut that pairs a cluster with a user and an optional namespace). `current-context` tells kubectl which entry to use right now. You can have 10 clusters in one file and flip between them with a single command."*

**Structure in one line:**  
`Context = Cluster (server + CA) + User (cert or token) + Namespace`

### 🖥️ CLI Commands to Test It
```bash
# See the full config
kubectl config view
kubectl config view --raw          # show actual cert data (not redacted)

# Where am I pointing right now?
kubectl config current-context

# List all contexts (* = active)
kubectl config get-contexts
kubectl config get-clusters
kubectl config get-users

# Switch to a different context
kubectl config use-context prod-context

# Override namespace for the current context (no YAML edit needed)
kubectl config set-context --current --namespace=kube-system

# Run one command against a different context without switching
kubectl get pods --context=prod-context

# Use a completely separate kubeconfig file
kubectl get pods --kubeconfig=/path/to/other-config.yaml

# Merge multiple kubeconfig files (Linux/Mac)
export KUBECONFIG=~/.kube/config:~/.kube/dev.yaml:~/.kube/prod.yaml
kubectl config get-contexts      # see all merged contexts

# Flatten merged config into one file
kubectl config view --raw --flatten > ~/.kube/merged-config
```

### 💥 Top 3 Production Breaks
1. **Wrong `current-context` in automation** — A CI/CD pipeline runs `kubectl apply` without specifying `--context` or `--kubeconfig`. It accidentally targets production because someone's local shell had the context pointing at prod. Fix: Always pass `--context` or `KUBECONFIG` explicitly in scripts — never rely on the default context.
2. **Expired credentials in kubeconfig** — The client cert embedded in the kubeconfig expires. `kubectl` throws `x509: certificate has expired`. Fix: Regenerate the user cert via CSR, update kubeconfig with `kubectl config set-credentials`.
3. **Kubeconfig file permissions too open** — `kubectl` warns `WARNING: kubeconfig file has group-readable/world-readable permissions`. On shared nodes, another process or user can read your credentials. Fix: `chmod 600 ~/.kube/config`.

---

## 3. RBAC — Role & RoleBinding

### 🗣️ Elevator Pitch
> *"RBAC answers: 'You proved who you are — but what are you allowed to do?' A Role is a list of permissions (verbs on resources) scoped to one namespace. A RoleBinding is the glue that says 'give user X this Role in namespace Y'. Without the binding, the role does nothing."*

**The formula:**  
`Who (Subject) + What (Role/verbs) + Where (Namespace) = RoleBinding`

### 🖥️ CLI Commands to Test It
```bash
# Create role imperatively
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  --namespace=dev

# Bind role to a user
kubectl create rolebinding dev-binding \
  --role=pod-reader \
  --user=jane \
  --namespace=dev

# Bind role to a service account
kubectl create rolebinding sa-binding \
  --role=pod-reader \
  --serviceaccount=dev:my-app-sa \
  --namespace=dev

# ✅ The most important test command — can this user do this?
kubectl auth can-i list pods --as=jane --namespace=dev
kubectl auth can-i delete nodes --as=jane            # should be no

# See everything a user can do
kubectl auth can-i --list --as=jane --namespace=dev

# Inspect existing roles and bindings
kubectl get roles -n dev
kubectl get rolebindings -n dev
kubectl describe rolebinding dev-binding -n dev
```

### 💥 Top 3 Production Breaks
1. **Role exists, binding missing** — A developer complains they can't access pods. The Role is created, but the RoleBinding was never applied. Fix: `kubectl get rolebindings -n <ns>` and check if their username/SA is in the subjects.
2. **Wrong namespace on RoleBinding** — The RoleBinding is created in `default` but the user is trying to access resources in `production`. Roles and RoleBindings are namespace-scoped. Fix: Re-create the binding in the correct namespace, or use a ClusterRole + ClusterRoleBinding.
3. **Subject name mismatch** — The cert's `CN` (Common Name) is `Jane` but the RoleBinding has `jane` (lowercase). K8S user names are case-sensitive. Fix: `openssl x509 -noout -subject -in jane.crt` to verify the exact CN, then match it in the binding.

---

## 4. ClusterRole & ClusterRoleBinding

### 🗣️ Elevator Pitch
> *"Some resources don't live in namespaces — nodes, persistent volumes, namespaces themselves. You can't use a regular Role for those. ClusterRole is the same idea as Role but works cluster-wide. ClusterRoleBinding attaches it to a user/SA across the entire cluster. You can also use a ClusterRole with a regular RoleBinding to give the same permissions in a specific namespace — one role, reused everywhere."*

**Key difference from Role:**
- `Role` → namespace-scoped resources, one namespace
- `ClusterRole` → cluster-scoped resources OR any namespace

### 🖥️ CLI Commands to Test It
```bash
# Create a ClusterRole
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# Bind it cluster-wide to a user
kubectl create clusterrolebinding node-reader-binding \
  --clusterrole=node-reader \
  --user=ops-user

# Bind it to a service account
kubectl create clusterrolebinding monitoring-binding \
  --clusterrole=node-reader \
  --serviceaccount=monitoring:prometheus-sa

# Check permissions
kubectl auth can-i list nodes --as=ops-user            # yes
kubectl auth can-i list nodes --as=ops-user --namespace=kube-system  # yes (cluster-wide)

# Inspect cluster roles
kubectl get clusterroles | grep -v system:   # filter out built-ins
kubectl describe clusterrole node-reader
kubectl describe clusterrolebinding node-reader-binding

# Who has cluster-admin?
kubectl describe clusterrolebinding cluster-admin

# Check if a resource is namespaced or not
kubectl api-resources --namespaced=false     # cluster-scoped
kubectl api-resources --namespaced=true      # namespace-scoped
```

### 💥 Top 3 Production Breaks
1. **Accidentally granting `cluster-admin`** — A quick fix during an incident gives a service account or user `cluster-admin`. It never gets revoked. That SA now has unrestricted access to delete anything in the cluster. Fix: Regular audits with `kubectl get clusterrolebindings -o wide` and alert on any binding to `cluster-admin` outside of system accounts.
2. **Using wildcards `"*"` in rules** — `verbs: ["*"]` or `resources: ["*"]` gives more power than intended. Fix: Always be explicit. Use `kubectl auth can-i --list --as=<subject>` to see the actual effective permissions.
3. **Forgetting ClusterRole ≠ cluster-admin access to namespaced resources by default** — You create a ClusterRole for `nodes` access, but the developer also expected pod access across all namespaces. A ClusterRole only grants what is defined in its rules. Fix: Add the additional resources to the ClusterRole or create a separate binding.

---

## 5. Service Account

### 🗣️ Elevator Pitch
> *"Service Accounts are for pods, not humans. When your app running inside a pod needs to call the Kubernetes API — to list pods, watch configmaps, deploy something — it needs an identity. That's a Service Account. Every namespace gets a `default` SA automatically, but it has zero permissions. You create a custom SA, bind it to a Role, and assign it to your pod."*

**The three steps:** `Create SA → Bind to Role → Assign to Pod`

### 🖥️ CLI Commands to Test It
```bash
# Create a service account
kubectl create serviceaccount my-app-sa -n default

# Inspect it
kubectl describe serviceaccount my-app-sa

# Generate a short-lived token (K8S v1.24+)
kubectl create token my-app-sa
kubectl create token my-app-sa --duration=8h

# Bind the SA to a role
kubectl create rolebinding sa-pod-reader \
  --role=pod-reader \
  --serviceaccount=default:my-app-sa

# Check SA permissions
kubectl auth can-i list pods \
  --as=system:serviceaccount:default:my-app-sa

# See the token mounted inside a running pod
kubectl exec <pod-name> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Verify the SA assigned to a pod
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
```

### 💥 Top 3 Production Breaks
1. **Token auto-mount on pods that don't need it** — Every pod mounts the SA token by default. If the pod is compromised, the attacker gets an API token. Fix: Set `automountServiceAccountToken: false` on the SA or the pod spec for any workload that doesn't need to call the K8S API.
2. **Hardcoded long-lived SA token secrets (pre-v1.24 pattern)** — Teams create a `Secret` of type `service-account-token` and embed it in CI/CD pipelines. If the secret leaks, it's valid forever. Fix: Use `kubectl create token` for short-lived tokens, or use OIDC-based workload identity (e.g., IRSA on EKS).
3. **`default` SA given broad permissions** — Someone binds `cluster-admin` to the `default` SA in a namespace to "fix" an issue quickly. Every pod in that namespace (including user workloads) now has cluster-admin power. Fix: Never bind elevated roles to the `default` SA. Create dedicated SAs per application.

---

## 6. Image Security

### 🗣️ Elevator Pitch
> *"By default, Kubernetes pulls images from Docker Hub — no credentials needed for public images. But if your image is in a private registry, the kubelet needs to know the username and password. You store those in a `docker-registry` Secret and tell the pod to use it via `imagePullSecrets`. To avoid repeating this on every pod, attach the secret to the ServiceAccount instead."*

**The two-step pattern for private registries:**  
`Create docker-registry Secret → Add imagePullSecrets to Pod (or SA)`

### 🖥️ CLI Commands to Test It
```bash
# Create the pull secret
kubectl create secret docker-registry regcred \
  --docker-server=private.registry.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=me@example.com

# Verify the secret type
kubectl get secret regcred
kubectl describe secret regcred

# Decode and inspect the stored credentials
kubectl get secret regcred \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Attach pull secret to a service account (apply to all pods using that SA)
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'

# Verify the SA has the pull secret
kubectl describe serviceaccount default

# Test: Pod with imagePullPolicy: Always to force a fresh pull
kubectl run test-pull \
  --image=private.registry.io/myapp:v1 \
  --overrides='{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}'

# Check events when a pod fails to pull
kubectl describe pod <pod-name> | grep -A5 Events
```

### 💥 Top 3 Production Breaks
1. **`imagePullSecrets` missing on pod or SA** — Pod is stuck in `ImagePullBackOff`. The secret exists but was never attached to the pod spec or ServiceAccount. Fix: `kubectl describe pod` → look at Events for `401 Unauthorized` or `pull access denied`, then add `imagePullSecrets` to the pod or the SA.
2. **Secret in wrong namespace** — Secrets are namespace-scoped. You created `regcred` in `default` but the pod is in `production`. Fix: Recreate the secret in the pod's namespace: `kubectl create secret docker-registry regcred -n production ...`
3. **`imagePullPolicy: Always` on every pod in production** — Every pod restart hits the registry. In a high-churn environment or if the registry goes down, all pods fail to (re)start. Fix: Use specific image tags (not `latest`) with `IfNotPresent` — images are cached on nodes and pods restart instantly.

---

## 7. Security Context

### 🗣️ Elevator Pitch
> *"Security Context is where you tell Kubernetes: 'run this container as a non-root user, don't let it write to the filesystem, and strip all Linux capabilities it doesn't need.' It's your container's OS-level security configuration. Set it at the pod level to apply to all containers, or at the container level to override just that one. Think of it as the last line of defence if the app inside the container gets compromised."*

**The golden rule:** *Drop ALL capabilities, run as non-root, read-only root FS.*

### 🖥️ CLI Commands to Test It
```bash
# Verify which user a container runs as
kubectl exec <pod-name> -- id
kubectl exec <pod-name> -- whoami

# Check the security context in a running pod
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].securityContext}'

# Test that read-only root FS is enforced (should fail)
kubectl exec <pod-name> -- touch /test-file

# Test that privilege escalation is blocked
kubectl exec <pod-name> -- sudo id           # should fail or not exist

# Check capabilities (inside the pod)
kubectl exec <pod-name> -- cat /proc/1/status | grep Cap

# View the full pod spec including security settings
kubectl describe pod <pod-name>

# Run a quick non-root test pod
kubectl run security-test \
  --image=busybox \
  --restart=Never \
  --overrides='{"spec":{"securityContext":{"runAsUser":1000},"containers":[{"name":"security-test","image":"busybox","command":["id"]}]}}' \
  -- id
kubectl logs security-test   # should show uid=1000
```

### 💥 Top 3 Production Breaks
1. **Image runs as root, `runAsNonRoot: true` set** — Pod fails to start with `Error: container has runAsNonRoot and image will run as root`. The Docker image's default user is root (most official images). Fix: Either set a specific `runAsUser` with an existing UID in the image, or rebuild the image with a non-root user.
2. **`readOnlyRootFilesystem: true` breaks the app** — App crashes because it tries to write logs, temp files, or PID files to `/tmp` or `/var/run`. Fix: Mount `emptyDir` volumes at the specific writable paths the app needs (`/tmp`, `/var/run`, `/var/cache`) — keep the root FS read-only everywhere else.
3. **Capabilities mismatch** — A networking tool (e.g., `curl`, custom DNS resolver) needs `NET_ADMIN` but the security context drops all capabilities. Pod starts but silently fails at the feature level. Fix: Audit required capabilities with `kubectl exec <pod> -- cat /proc/1/status | grep Cap` and only add back what is actually needed.

---

## 8. Network Policies

### 🗣️ Elevator Pitch
> *"By default, every pod in Kubernetes can talk to every other pod — no restrictions. Network Policies are firewall rules for pods. Once you apply any policy that selects a pod, all traffic not explicitly allowed is blocked. You write rules for ingress (traffic coming in) and egress (traffic going out). The CNI plugin enforces these rules — if your CNI doesn't support them (like plain Flannel), the policies are silently ignored."*

**The key insight:** No policy = allow all. One policy applied to a pod = deny all except what the policy allows.

### 🖥️ CLI Commands to Test It
```bash
# List network policies
kubectl get networkpolicy              # or: kubectl get netpol
kubectl get netpol -n production
kubectl describe netpol db-allow-api

# Apply a policy
kubectl apply -f network-policy.yaml

# Label a namespace (required for namespaceSelector to work)
kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring

# Verify namespace labels
kubectl get namespace --show-labels

# Test connectivity BEFORE applying a policy (should work)
kubectl exec <pod-a> -- curl http://<pod-b-ip>:80

# Test connectivity AFTER applying deny-all policy (should fail/hang)
kubectl exec <pod-a> -- curl --max-time 5 http://<pod-b-ip>:80

# Quick deny-all test — apply this to isolate a pod
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-test
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Verify your CNI supports network policies (check CNI plugin)
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
```

### 💥 Top 3 Production Breaks
1. **CNI doesn't enforce Network Policies (silent failure)** — You apply a deny-all policy but pods can still talk to each other. Flannel does not enforce Network Policies. The policy is stored in etcd but nothing enforces it. Fix: Confirm your CNI supports policies (`kubectl get pods -n kube-system | grep calico/cilium/weave`). If using Flannel, add Calico in policy-only mode.
2. **`namespaceSelector` stops working after namespace rename** — Your policy selects the `monitoring` namespace by label `env=monitoring`. Someone changes the namespace label during an upgrade or refactor. Suddenly the monitoring stack can't reach production pods. Fix: Use the auto-applied label `kubernetes.io/metadata.name=<ns-name>` which K8S manages automatically (K8S v1.21+) instead of custom labels.
3. **AND vs OR confusion in `from:` rules** — Two items in the same `from:` list are OR (either source is allowed). But `podSelector` + `namespaceSelector` in the **same list item** are AND (both must match). Misplacing a `-` (dash) in YAML means you open access to pods you didn't intend. Fix: Always use `kubectl describe netpol` after applying and trace the logic; test with `kubectl exec` from multiple source pods.

---

## ⚡ Master Quick-Reference

| Topic | Key Object | Critical Command |
|---|---|---|
| TLS/CSR | `CertificateSigningRequest` | `kubectl certificate approve <name>` |
| KubeConfig | `Config` (file) | `kubectl config use-context <ctx>` |
| RBAC | `Role` + `RoleBinding` | `kubectl auth can-i <verb> <resource> --as=<user>` |
| ClusterRole | `ClusterRole` + `ClusterRoleBinding` | `kubectl api-resources --namespaced=false` |
| Service Account | `ServiceAccount` | `kubectl create token <sa-name>` |
| Image Security | `Secret (docker-registry)` | `kubectl create secret docker-registry regcred ...` |
| Security Context | Pod/Container spec field | `kubectl exec <pod> -- id` |
| Network Policy | `NetworkPolicy` | `kubectl exec <pod> -- curl --max-time 5 <target>` |

---

## 🔑 The 3 Universal Security Principles in K8S

1. **Least Privilege** — Give the minimum permissions needed. No wildcards `"*"`, no `cluster-admin` unless absolutely required.
2. **Defence in Depth** — Layer your security: RBAC controls the API, Security Context controls the OS, Network Policies control traffic. No single layer is enough.
3. **Audit Regularly** — Run `kubectl auth can-i --list --as=<user>`, review ClusterRoleBindings, and check for pods mounting the `default` SA token unnecessarily.
