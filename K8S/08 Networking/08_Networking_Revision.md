# K8S Networking : The ELI5 Revision Sheet

> **The Barista Analogy:** The coffee shop has a massive floor with hundreds of tables (pods). Every table needs to talk to others — a waiter (kube-proxy) runs around sticking address labels on the floor so packets know where to go; a receptionist (CoreDNS) remembers everyone's name so you say "get me the database table" instead of memorising its seat number; and a bouncer at the door (Ingress / API Gateway) decides which outside customers even get to walk in.

---

## 1. The Plain-English Map

| Concept | The "Explain Like I'm 5" translation | Why the company actually pays for this |
| :--- | :--- | :--- |
| **CNI** (Container Network Interface — standard plugin contract) | The electrical socket standard. K8S says "I need networking" and the CNI plugin (Calico, Flannel, Cilium) is the plug. | Lets you swap network plugins without rewriting K8S. Different CNIs = different features and performance. |
| **Cluster Networking** | Every pod gets its own IP. Every pod can talk to every other pod without NAT (translation of addresses). | The flat network model means apps don't need to know they're in a cluster. They just dial an IP. |
| **Pod Networking** | Each pod gets a virtual ethernet card (veth pair — two ends of a virtual cable) hooked into a bridge (switch) on the node. | Isolation between pods, real IPs for each, allows port-level traffic control. |
| **Overlay Network** (virtual network tunnelled over real network) | A walkie-talkie network layered on top of the office LAN. Pods talk pod-to-pod over a virtual tunnel. | Allows pods on different physical nodes to reach each other as if they're on the same switch. |
| **kube-proxy** | The waiter who keeps a constantly updated map of Service IPs → Pod IPs, and rewrites network rules (iptables / IPVS) on every node. | Without it, "Service ClusterIP" is just a number — nothing forwards traffic to the actual pods. |
| **Service: ClusterIP** | An internal phone extension. Only reachable inside the cluster. | Stable VIP (virtual IP — one IP, multiple backends) so pods can find each other without hardcoding IPs. |
| **Service: NodePort** | Open a hole on every node's external port (30000–32767). Traffic in → forwarded to the right pod. | Quick external access without a cloud load balancer. Good for dev, bad for prod (security, port management). |
| **Service: LoadBalancer** | Tell the cloud provider "give me a real public IP and forward it to my pods". | Production-grade external traffic entry. Cloud auto-creates an ELB/ALB and wires it up. |
| **CoreDNS** | The cluster's internal phonebook. Ask "what's the IP of `my-service.default.svc.cluster.local`?" — CoreDNS answers. | Pods use names, not IPs. Names don't change when pods are rescheduled. IPs do. |
| **Ingress** | The front door receptionist + smart router. Routes external HTTP/HTTPS to different Services based on hostname or URL path. | One public IP, many services. `api.company.com` → API service; `app.company.com` → frontend service. |
| **Ingress Controller** | The actual bouncer enforcing the Ingress rules (nginx, Traefik, HAProxy). The Ingress object is just the rulebook; the controller is the one acting on it. | Without a controller, Ingress YAML is ignored. The controller watches for rules and applies them. |
| **API Gateway** | A smarter, application-aware Ingress — handles auth, rate limiting, retries, transformations, not just routing. | Centralise cross-cutting concerns (auth, observability, throttling) at the network edge instead of coding them into every microservice. |
| **NetworkPolicy** | Kubernetes firewall rules for pods. Default = everyone talks to everyone. Apply a policy = only allowed traffic gets through. | Zero-trust (trust nothing by default) network posture inside the cluster. Isolate databases, PCI-scope pods, etc. |

---

## 2. The Mental Wire-Frame

```
──────────────────────────────────────────────────────────────────────
EXTERNAL TRAFFIC FLOW  (outside world → your pod)
──────────────────────────────────────────────────────────────────────

Internet
    │
    │  HTTP/HTTPS request: GET app.company.com/api/orders
    ▼
[Cloud Load Balancer]  ← created by Service type=LoadBalancer
    │
    │  forwards to NodePort on any cluster node
    ▼
[Node: port 443 / NodePort]
    │
    │  kube-proxy rewrites destination via iptables/IPVS rules
    ▼
[Ingress Controller Pod]  (e.g., nginx-ingress)
    │
    │  reads Ingress rules: host=app.company.com, path=/api → svc:orders-svc
    ▼
[Service: orders-svc  (ClusterIP)]
    │
    │  kube-proxy load-balances across healthy pod endpoints
    ├──────────────────────────────────────┐
    ▼                                      ▼
[orders-pod-1]                        [orders-pod-2]
    │                                      │
    │  Pod needs to talk to DB             │
    ▼                                      │
CoreDNS: "where is postgres-svc?"          │
    │  answer: 10.96.0.100                 │
    ▼                                      │
[Service: postgres-svc (ClusterIP)]        │
    │                                      │
    │ NetworkPolicy check: is orders-pod   │
    │ allowed to reach postgres-svc?       │
    ▼                                      │
[postgres-pod]  ← only if NetworkPolicy    │
                   allows it               │

──────────────────────────────────────────────────────────────────────
POD-TO-POD NETWORKING (same or different node)
──────────────────────────────────────────────────────────────────────

  Node A                                Node B
  ┌──────────────────────┐              ┌──────────────────────┐
  │  Pod A  (10.244.0.5) │              │  Pod B  (10.244.1.7) │
  │    │                 │              │    │                 │
  │  veth0               │              │  veth0               │
  │    │                 │              │    │                 │
  │  cni0 (bridge)       │              │  cni0 (bridge)       │
  │    │                 │              │    │                 │
  │  eth0 (node NIC)─────┼── Overlay ───┼──eth0 (node NIC)     │
  └──────────────────────┘  (tunnel or  └──────────────────────┘
                              BGP route)

  veth pair = virtual ethernet cable (one end in pod, one end in node)
  cni0/bridge = virtual switch connecting pods on the same node
  Overlay = the virtual tunnel between nodes (VXLAN in Flannel, BGP in Calico)

──────────────────────────────────────────────────────────────────────
DNS RESOLUTION CHAIN
──────────────────────────────────────────────────────────────────────

  Pod wants to reach "orders-svc"
      │
      │  /etc/resolv.conf inside pod says:
      │  nameserver 10.96.0.10  (CoreDNS ClusterIP)
      │  search default.svc.cluster.local svc.cluster.local cluster.local
      │
      ▼
  CoreDNS (running as a Deployment in kube-system)
      │
      │  Looks up: orders-svc.default.svc.cluster.local
      │  Returns:  10.96.44.200  (the Service's ClusterIP)
      ▼
  kube-proxy iptables/IPVS rule translates 10.96.44.200 → actual pod IP
      ▼
  Pod endpoint reached ✅
```

---

## 3. The "Bare Minimum" YAML

```yaml
# ── 1. A simple Deployment (the app we're exposing) ─────────────────────────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
---
# ── 2. ClusterIP Service (internal access — kube-proxy wires this up) ────────
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: web                          # DANGER: wrong label = Service routes to 0 pods (Endpoints: <none>)
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
# ── 3. Ingress (external HTTP routing — needs an Ingress Controller running) ─
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx             # DANGER: must match your controller's IngressClass name or Ingress is ignored
  rules:
  - host: app.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
---
# ── 4. NetworkPolicy (deny all ingress to web pods except from ingress controller) ─
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-allow-ingress-only
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx   # DANGER: if namespace label is missing, ALL ingress to these pods is blocked
    ports:
    - protocol: TCP
      port: 80
```

---

## 4. Top 3 Production Breaks (The "Call me at 2 AM" Scenarios)

### Break 1: Service has no endpoints — traffic goes nowhere
- **What the dashboard screams:**
  ```bash
  curl http://web-svc   # hangs forever or "connection refused"

  kubectl get endpoints web-svc
  NAME      ENDPOINTS   AGE
  web-svc   <none>      5m
  ```
- **The "Why":** The Service's `selector` labels don't match any running pod's labels. Happens when: someone renames a Deployment label, deploys to the wrong namespace, or the pods are all in `CrashLoopBackOff` (not Ready = not added to Endpoints).
- **The Fire Extinguisher:**
  ```bash
  # Check what labels the Service is selecting
  kubectl describe service web-svc | grep Selector

  # Check what labels your pods actually have
  kubectl get pods --show-labels

  # Check if pods are Ready (NotReady pods are excluded from Endpoints)
  kubectl get pods -o wide

  # Manually check endpoints
  kubectl get endpoints web-svc

  # Curl the pod IP directly (bypass Service) to isolate whether it's routing or app
  kubectl exec -it <any-pod> -- curl http://<pod-ip>:80
  ```

---

### Break 2: Ingress exists but returns 404 or traffic never reaches the app
- **What the dashboard screams:**
  ```
  curl https://app.company.com   →  404 Not Found  (nginx default page)
                                 OR connection timeout
  kubectl get ingress web-ingress   →  ADDRESS is empty
  ```
- **The "Why":** Three separate failure points —  
  ① **No Ingress Controller** installed — the Ingress YAML is stored but nothing acts on it.  
  ② **Wrong `ingressClassName`** — the Ingress specifies `nginx` but the installed controller is watching for `traefik`.  
  ③ **Hostname mismatch** — the `host:` field in the Ingress rule is `app.company.com` but you're hitting a raw IP or a different hostname. Ingress rules are hostname-based.
- **The Fire Extinguisher:**
  ```bash
  # Is an Ingress Controller actually running?
  kubectl get pods -n ingress-nginx
  kubectl get pods -n kube-system | grep ingress

  # Check available IngressClasses
  kubectl get ingressclass

  # Describe the Ingress and check events
  kubectl describe ingress web-ingress

  # Check controller logs for routing decisions
  kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=50

  # Test with explicit Host header (bypass DNS)
  curl -H "Host: app.company.com" http://<node-ip>:<nodeport>
  ```

---

### Break 3: NetworkPolicy silently cuts off inter-service traffic
- **What the dashboard screams:**
  ```
  App pods are Running ✅  Services exist ✅  Ingress routes ✅
  But: "connection timed out" between service A and service B
  kubectl exec orders-pod -- curl --max-time 5 http://postgres-svc:5432
  # just hangs, then: curl: (28) Operation timed out
  ```
- **The "Why":** Someone applied a NetworkPolicy for pod isolation and either:  
  ① Forgot to add an egress rule allowing outbound from `orders-pod` to `postgres-svc`.  
  ② The `namespaceSelector` is using a custom label that was never applied to the namespace.  
  ③ The CNI plugin (like plain Flannel) doesn't enforce NetworkPolicies — the policy is stored but silently ignored, so the real problem is elsewhere.
- **The Fire Extinguisher:**
  ```bash
  # List all NetworkPolicies in the namespace
  kubectl get netpol -n default

  # Describe the policy — check what it actually selects
  kubectl describe netpol web-allow-ingress-only

  # Check namespace labels (critical for namespaceSelector)
  kubectl get namespace --show-labels

  # Test without NetworkPolicy — temporarily delete and retest
  kubectl delete netpol web-allow-ingress-only
  kubectl exec orders-pod -- curl --max-time 5 http://postgres-svc:5432
  # If it works now → the policy was blocking it

  # Confirm your CNI supports Network Policies
  kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
  ```

---

## 5. The "Gotcha" Trapdoor

**T or F — Answer before you scroll!**

1. ❓ A `ClusterIP` Service is accessible from **outside** the cluster if you know the cluster's node IP and the Service's ClusterIP port.

2. ❓ CoreDNS resolves pod names like `my-pod` directly. You don't need to go through a Service — just use the pod name.

3. ❓ If you apply a `NetworkPolicy` with `policyTypes: [Ingress]` but define **no `ingress` rules**, it means **all ingress traffic is denied** to the selected pods.

---

<details>
<summary>🔽 Reveal Answers</summary>

1. **FALSE** — ClusterIP is a virtual IP that only exists inside the cluster's iptables/IPVS rules. It is not routable from outside. You need NodePort, LoadBalancer, or Ingress for external access.

2. **FALSE** — CoreDNS resolves **Service** names, not pod names (by default). Pods get DNS entries too (`<pod-ip-dashes>.<namespace>.pod.cluster.local`) but you need the pod IP to construct the name. In practice everyone uses Service names, not pod DNS.

3. **TRUE** — This is the "default deny" pattern. An empty `ingress: []` or simply omitting the ingress block when `policyTypes` includes `Ingress` means zero ingress rules → zero ingress allowed. Very intentional, very powerful, and very easy to accidentally apply to the wrong pods.

</details>
