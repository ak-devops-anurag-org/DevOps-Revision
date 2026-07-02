

# Kubernetes Networking Revision Notes

## Basics of Networking in K8s
- **Pod Network**: Each Pod gets its own IP (from Pod subnet), not containers individually. Containers in a Pod share the same network namespace.
- **Cluster Networking**: Flat, routable Pod IPs across nodes. No NAT within the cluster.
- **CNI (Container Network Interface)**: Standard for networking in containers. Plugins (Calico, Flannel, Cilium, Weave) implement this.

### Important Paths
- `/opt/cni/bin/` → CNI plugin binaries (executables).
- `/etc/cni/net.d/` → CNI config files (JSON, defines plugin & subnet).
- Default CNI depends on Kubernetes distribution (e.g., `kubeadm` has none by default, EKS → VPC CNI).


## CNI and CNI Plugins
- **CNI Core**: Just a spec. Actual networking done by plugins.
- **Common Plugins**:
  - **Flannel** → Simple overlay, VXLAN. *Does not support NetworkPolicies*.
  - **Calico** → L3, BGP, supports NetworkPolicies.
  - **Cilium** → eBPF-based, advanced security + policies.
  - **Weave Net** → Easy setup, supports policies.
- **Check Current CNI**:
  ```bash
  cat /etc/cni/net.d/* | grep type
  ```

### Example:

```bash
cat /etc/cni/net.d/10-calico.conflist
```

* **Install/Uninstall Plugins**: Typically via DaemonSet YAML (`kubectl apply -f calico.yaml`).


## NetworkPolicies and CNI

* **Relation**: NetworkPolicy enforcement is done by the CNI plugin.
* If plugin doesn’t support it (e.g., Flannel), policy rules are ignored.
* Use `kubectl describe networkpolicy <name>` to verify applied rules.


## Pod-to-Pod Communication

* **Same Node**:

  * Pod → veth pair → bridge (cni0) → veth pair → Pod.
  * Packets stay inside node.
* **Different Node**:

  * Pod A (Node1) → veth → bridge → CNI plugin → Node1’s root network interface → Underlay/Overlay (VXLAN, BGP, etc.) → Node2 → bridge → Pod B.
  * CNI plugin decides routing (overlay or routed).

### Pod Subnet

* Allocated by CNI, each node gets a subnet slice. Example: `10.244.1.0/24` on Node1, `10.244.2.0/24` on Node2.


## Kube-proxy vs CNI

* **CNI** → Handles Pod networking (IP allocation, routing, overlay).
* **kube-proxy** → Handles Service networking (ClusterIP, NodePort, LoadBalancer) using iptables/IPVS.
* Without CNI → Pods won’t get IPs.
* Without kube-proxy → Pods get IPs but Services won’t route.


## Who Assigns IP?

* **Pod IP** → Assigned by CNI plugin (from Pod subnet).
* **Container IP** → Not separate; all containers in Pod share Pod IP.


## CNI Deployment

* Plugins (Calico, Flannel, etc.) usually run as **DaemonSet** (one pod per node).
* They manage node-level networking components.


# Networking Commands Reference

## Check CNI and Pod Network

```bash
# Show CNI config
cat /etc/cni/net.d/*

# List CNI binaries
ls /opt/cni/bin

# Show Pod CIDR assigned to node
kubectl describe node <node-name> | grep PodCIDR
```

## Check Pod-to-Pod Networking

```bash
# Exec into Pod and test connectivity
kubectl exec -it <pod-name> -- ping <target-pod-ip>

# Curl via Pod IP
kubectl exec -it <pod-name> -- curl http://<target-pod-ip>:<port>
```

## Check kube-proxy

```bash
kubectl get pods -n kube-system | grep kube-proxy
kubectl logs -n kube-system <kube-proxy-pod>
```

## Debug Network Policies

```bash
# List policies
kubectl get networkpolicy -A

# Describe specific policy
kubectl describe networkpolicy <policy-name>
```






















# Kubernetes Networking Revision Notes 
## NetworkPolicies in Action
- **Default behavior**: All Pods can talk to each other (no restrictions).
- **With NetworkPolicy**: Only allowed traffic flows; everything else denied if policy exists.
- **Selectors**:
  - `podSelector` → Match Pods by labels.
  - `namespaceSelector` → Match Pods by namespace.
  - `ipBlock` → Allow/deny based on CIDR IP ranges.


## Common NetworkPolicy Examples

### Deny-All Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```
**Effect**: Blocks all incoming traffic to Pods in `default` namespace.


### Allow-All Ingress from Same Namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-namespace
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```
**Effect**: Pods can only talk to Pods in the same namespace.

---

### Allow Specific App Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```
**Effect**: Only `frontend` Pods can reach `backend` Pods on TCP/8080.

---

### Allow External Access by IPBlock
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-ipblock
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 203.0.113.0/24
```
**Effect**: Only external IPs in `203.0.113.0/24` can reach `api` Pods.

---

## Service Traffic Flow

### ClusterIP Service
- Pod → kube-proxy rules → destination Pod (via endpoints).
- Traffic stays inside cluster.

### NodePort Service
- Client → `<NodeIP>:<NodePort>` → kube-proxy → Pod.
- Exposed externally but uses every node.

### LoadBalancer Service
- Cloud LoadBalancer (AWS ELB, Azure LB, GCP LB) → forwards to NodePort → Pods.

---

## Ingress Controller Flow
- Client (Browser) → Ingress Controller Pod (NGINX/HAProxy/Traefik) → Backend Service → Pods.
- Ingress rules use **host/path-based routing**.

---

## Egress Traffic Control
- By default Pods can connect anywhere.
- Restrict using **Egress NetworkPolicy**.
- Example:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-egress
spec:
  podSelector:
    matchLabels:
      role: restricted
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 443
```
**Effect**: Only HTTPS traffic to `10.0.0.0/24` is allowed.

---

# Commands Reference (NetworkPolicies + Traffic Flow)

## NetworkPolicy Management
```bash
# List policies in namespace
kubectl get networkpolicy -n default

# Apply new policy
kubectl apply -f policy.yaml

# Delete policy
kubectl delete networkpolicy <name>
```

## Testing Policies
```bash
# Run temporary busybox Pod for testing
kubectl run tmp --rm -it --image=busybox -- /bin/sh

# Ping another pod
ping <pod-ip>

# Curl service
wget -qO- http://<service-ip>:<port>
```

## Ingress Controller
```bash
# Get Ingress resources
kubectl get ingress -A

# Describe specific ingress
kubectl describe ingress <name>
```

## Service Flow Debug
```bash
# Show Endpoints for service
kubectl get endpoints <svc-name> -o wide

# Check iptables rules (for kube-proxy)
iptables -t nat -L KUBE-SERVICES -n -v
```
























# Kubernetes Networking Revision Notes 

---

## CNI Internals

### Pod Network Setup (Step-by-Step)
1. Pod created → kubelet calls CNI binary.
2. CNI plugin:
   - Creates **veth pair** (one end in Pod, one in node namespace).
   - Attaches veth to **bridge (cni0)** or routing device.
   - Assigns Pod IP (via IPAM).
   - Adds route entries.
3. Pod can now send/receive traffic.

### CNI Components
- **CNI Plugin** → Main binary (Calico, Flannel, etc.).
- **IPAM Plugin** → Manages IP address allocation.
- **Config** → JSON in `/etc/cni/net.d`.

### Bridge Mode Example
- Each node has `cni0` bridge.
- Pod veth connected to bridge.
- Node routes (overlay or underlay) decide inter-node traffic.

---

## kube-proxy Internals

### Modes
- **iptables mode** → Inserts NAT rules for Services.
- **IPVS mode** → Uses Linux IPVS for load balancing (faster, scalable).

### Service Flow (ClusterIP)
- Pod → Virtual IP (Service) → kube-proxy rule → Endpoint Pod.
- Example:
  - ClusterIP: `10.96.0.10`
  - kube-proxy NATs to Pod IP: `10.244.2.15`.

---

## Debugging Networking

### Node-Level Debug
```bash
# List network interfaces
ip link

# Show routing table
ip route

# Show ARP table
arp -n
````

### Pod-Level Debug

```bash
# Run debug pod
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# Inside pod: check interfaces
ip addr

# Inside pod: trace route
traceroute <pod-ip>
```

### Capturing Traffic

```bash
# On node
tcpdump -i any port 80

# Inside debug pod
tcpdump -i eth0
```

---

## Best Practices

### Pod Networking

* Use **non-overlapping Pod CIDR** with cloud network.
* Stick to **/24 per node** subnets for scalability.
* Monitor IP usage with `kubectl get node -o wide`.

### NetworkPolicies

* Always start with **default deny-all** → then allow selectively.
* Group Pods using **labels** for policies.
* Test policies with temporary Pods (`busybox`, `netshoot`).

### Services & kube-proxy

* Prefer **ClusterIP** internally, **Ingress/LoadBalancer** externally.
* Switch kube-proxy to **IPVS mode** for large clusters.
* Monitor kube-proxy logs in `kube-system`.

### CNI Plugins

* Choose plugin based on requirements:

  * **Calico** → NetworkPolicy + BGP.
  * **Cilium** → eBPF, observability.
  * **Flannel** → Simple overlays, no policies.
* Keep plugin YAML versioned in Git.

### Debugging Strategy

1. Check **Pod IP** (`kubectl get pods -o wide`).
2. Verify **routes** (`ip route` on node).
3. Test **ping/curl** from debug Pod.
4. Inspect **iptables/IPVS** (`iptables -t nat -L` or `ipvsadm -Ln`).
5. Use **tcpdump** if packets are lost.

---

# Commands Reference (Internals + Debugging)

## CNI Inspection

```bash
# Check CNI plugin type
cat /etc/cni/net.d/* | grep type

# Inspect veth pairs
ip link | grep veth

# Show bridge details
brctl show
```

## kube-proxy Internals

```bash
# List kube-proxy pods
kubectl get pods -n kube-system | grep kube-proxy

# Check kube-proxy mode
kubectl logs -n kube-system <kube-proxy-pod> | grep mode

# List NAT rules
iptables -t nat -L KUBE-SERVICES -n -v

# If using IPVS
ipvsadm -Ln
```

## Debug Pods

```bash
# Deploy netshoot pod
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# Deploy busybox pod
kubectl run test --rm -it --image=busybox -- sh
```

## Traffic Capture

```bash
# Node-level capture
tcpdump -i eth0 host <pod-ip>

# Inside Pod
kubectl exec -it netshoot -- tcpdump -i eth0
```








