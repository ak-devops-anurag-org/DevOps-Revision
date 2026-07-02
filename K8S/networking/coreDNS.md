# 🔹 1. DNS in Kubernetes

Kubernetes has its own DNS system (via **CoreDNS**) that allows:

* Pods to find other Pods/Services **without knowing IPs**.
* Services to have a **stable DNS name**, even if Pod IPs change.

👉 Why? Because Pod IPs are **ephemeral** (they can change if Pods restart).
So, instead of using IP, Kubernetes provides **DNS names**.

# 🔹 2. FQDN (Fully Qualified Domain Name) in K8s

The **FQDN** is the complete DNS path of a resource.

Example:

```
web-service.app.svc.cluster.local
```

Let’s break it down:

* **web-service** → Service name (defined in YAML).
* **app** → Namespace where the service lives.
* **svc** → Denotes that this DNS entry is for a Service.
* **cluster.local** → Root domain of the cluster (default, configurable).

So `web-service.app.svc.cluster.local` uniquely identifies the service anywhere inside the cluster.

## FQDN for Service

* Service Name: `web-service`
* Namespace: `app`
* Full Path: `web-service.app.svc.cluster.local`

👉 If you are **inside the same namespace**, you can just use `web-service`.
👉 From another namespace, you must use `web-service.app`.

## FQDN for Pod

Pods also get a DNS entry:

```
<pod-ip-address>.<namespace>.pod.cluster.local
```

Example:

```
10-244-2-8.app.pod.cluster.local
```

* The dots (`.`) in IP are replaced by dashes (`-`).
* Not often used directly (because Pods are not stable), but useful for debugging or StatefulSets.

# 🔹 3. How DNS Works in Kubernetes

### Example: Pod A (frontend) wants to talk to Pod B (backend via Service).

1. Pod A runs `curl http://backend.app.svc.cluster.local`
2. The request goes to the Pod’s `/etc/resolv.conf`, which points to **CoreDNS Service IP** (ClusterIP).
3. CoreDNS looks up the name in its data (from kube-apiserver).
4. CoreDNS responds with the ClusterIP of the `backend` Service.
5. Pod A connects to Service IP → kube-proxy load-balances → one of the backend Pods.

# 🔹 4. CoreDNS

CoreDNS is the **DNS server** inside Kubernetes.

It is deployed in the `kube-system` namespace and provides DNS for:

* **Pods**
* **Services**
* **Custom DNS entries** (ConfigMap)

### Why CoreDNS needs Pods, Services, ConfigMap?

* **Pods** → CoreDNS runs as Pods (usually 2 for HA).
* **Service** → CoreDNS itself is exposed as a Service (ClusterIP, usually `10.96.0.10`) so that all Pods can query it.
* **ConfigMap** → CoreDNS behavior is controlled by a ConfigMap (`coredns`) that defines rules (e.g., `cluster.local`, `forward` to external DNS).

👉 Example CoreDNS ConfigMap (`coredns`):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
    }
```

# 🔹 5. Quick Recap


* **DNS in K8s** → Translates Service/Pod names → IP.
* **FQDN** → `service.namespace.svc.cluster.local`.
* **Pod DNS** → `<pod-ip>.<namespace>.pod.cluster.local`.
* **CoreDNS** → DNS server for the cluster, deployed as Pods + Service + ConfigMap.
* **Why needed?** → Because Pod IPs change, DNS ensures stable communication.







# 🔹 kube-proxy vs CNI (and CNI plugins)

### kube-proxy

* Runs on **every node**.
* Implements **Service IPs** (ClusterIP, NodePort, LoadBalancer).
* Handles **Service → Pod load balancing**.
* Works using **iptables** or **IPVS rules** to redirect Service IP traffic → Pod IPs.

👉 kube-proxy **does NOT provide pod-to-pod networking**. It only manages Service traffic.

### CNI (Container Network Interface)

* Standard that defines **how pods get network connectivity**.
* Ensures **every pod gets an IP** and is reachable from any other pod.
* CNI plugins handle **pod-to-pod communication** (both intra-node and inter-node).
* Examples: **Flannel, Calico, Weave, Cilium**.

👉 Without CNI, Pods would have no IP and could not talk across nodes.

# 🔹 Why do we need both?

* **CNI plugin** → Gives Pods their IP + ensures Pod-to-Pod connectivity across cluster.
* **kube-proxy + Service (ClusterIP/NodePort/LoadBalancer)** → Provides **stable virtual IPs** and **load-balancing** for Pods.

So:

* If Pod A wants to talk directly to Pod B → **CNI handles it**.
* If Pod A wants to talk to a Service (like `backend-service`) →

  * DNS resolves Service name → ClusterIP.
  * kube-proxy intercepts Service IP traffic → sends to one Pod backend.
  * CNI ensures actual packet routing to Pod IP.

# 🔹 Example Flows

### Pod-to-Pod Communication

* Same Node: Pod A → veth → bridge (cni0) → veth → Pod B.
* Different Node: Pod A → bridge → Node1 NIC → Overlay (VXLAN/BGP) → Node2 → bridge → Pod B.
  👉 This is **CNI’s job**.

### Pod-to-Service Communication

* Pod A queries DNS → gets Service ClusterIP.
* kube-proxy rule forwards ClusterIP → picks Pod B (backend).
* Packet sent → CNI ensures Pod A and Pod B connectivity.

# 🔹 Analogy

* **CNI** = builds the **roads** so that cars (packets) can move between houses (Pods).
* **kube-proxy/Services** = provides a **toll booth/traffic controller** that makes sure cars going to a **shop (Service)** get routed to one of the available branches (Pods).

✅ So, **without CNI → no Pod networking**.
✅ **Without kube-proxy → no Services / ClusterIP load-balancing**.
👉 Together they provide a complete networking model.

