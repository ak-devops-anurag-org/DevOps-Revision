# Kubernetes Networking & Services — Interview Revision

> The most critical topic for Kubernetes interviews.
> Covers: Pod networking, CNI, kube-proxy, Services, DNS, Ingress, NetworkPolicy, and troubleshooting.

## A. Kubernetes Networking Model

### Q1. What are the fundamental principles of the Kubernetes networking model? ⭐ MUST KNOW
**Answer:** The Kubernetes network model defines a flat, un-NATed network where every Pod gets its own IP address and can communicate with all other Pods directly.
**How it works:** Nodes have their own IPs, and Pods have separate IPs. The cluster routes traffic between them without NAT. Services act as stable endpoints to route traffic to the ephemeral Pods.
**Interview point:** Interviewers want to hear "flat network," "one IP per Pod," and "no NAT between Pods." This model simplifies application port allocation since you don't map container ports to host ports.

### Q2. How does Kubernetes handle container-to-container communication within a single Pod? 🟠 IMPORTANT
**Answer:** Containers within the same Pod share the exact same network namespace, including the IP address and port space.
**How it works:** They communicate via `localhost` (127.0.0.1). If Container A listens on port 80, Container B can reach it at `localhost:80`.
**Interview point:** Emphasize that because they share a network namespace, you cannot have two containers in the same Pod listening on the same port (port conflict).

## B. Pod-to-Pod Communication

### Q3. How do two Pods communicate when they are scheduled on the same worker node? ⭐ MUST KNOW
**Answer:** Traffic routes locally through the node's network bridge (e.g., `cni0` or `docker0`), never leaving the physical node.
**How it works:**
```text
Node-1
│
├── Pod-A (10.244.1.10)
│     │
│     veth pair
│     │
│     bridge/network
│     │
├── Pod-B (10.244.1.11)
```
Each Pod has a virtual ethernet (veth) interface connected to its isolated namespace and the host's bridge. The bridge simply forwards the traffic from Pod A's veth to Pod B's veth.
**Interview point:** Know that local traffic is fast and isolated from physical network hardware.

### Q4. How do Pods communicate when they are on different nodes? ⭐ MUST KNOW
**Answer:** The CNI (Container Network Interface) intercepts the traffic at the host level and routes it across the physical network to the destination node, which then passes it to the target Pod.
**How it works:**
```text
Node-1                    Node-2
Pod-A (10.244.1.10)       Pod-B (10.244.2.10)
   │                         │
   veth                      veth
   │                         │
   Node network ─────────── Node network
```
Traffic goes: Pod → veth → node bridge → physical node NIC → physical network → dest node NIC → dest node bridge → dest Pod veth. The CNI manages this via overlay networks (VXLAN) or direct routing (BGP).
**Interview point:** Explain that the underlying implementation depends entirely on which CNI is installed (e.g., Flannel uses VXLAN overlays; Calico often uses BGP without overlays).

### Q5. What is a "veth pair" and why is it needed? 🟠 IMPORTANT
**Answer:** A virtual ethernet (veth) pair is a virtual networking cable connecting two network namespaces.
**How it works:** One end sits in the Pod's isolated network namespace (`eth0`), and the other end sits in the host node's root network namespace (often named `cali...` or `veth...`).
**Interview point:** This is Linux networking 101. Kubernetes relies on Linux namespaces for isolation, and veth pairs are the bridge out of that isolation.

## C. CNI (Container Network Interface)

### Q6. What is the CNI and what are its responsibilities? ⭐ MUST KNOW
**Answer:** CNI is a standard/framework that allows Kubernetes to integrate with various third-party networking solutions.
**How it works:** Kubernetes calls the CNI plugin during Pod lifecycle events. The CNI is responsible for assigning the Pod an IP, setting up the veth pairs, and configuring host routes so the Pod can reach the network.
**Interview point:** Kubernetes itself does *not* do networking. It dictates the model, and the chosen CNI implements it.

### Q7. How do popular CNIs like Flannel, Calico, and Cilium differ? 🟠 IMPORTANT
**Answer:** They use fundamentally different underlying technologies to implement the K8s network model.
**How it works:**
- **Flannel:** Simple, usually uses VXLAN overlay (encapsulates Pod traffic inside Node traffic). No built-in NetworkPolicy support.
- **Calico:** High-performance, typically uses BGP (underlay) for unencapsulated routing. Excellent NetworkPolicy support.
- **Cilium:** Uses eBPF (kernel-level) for highly efficient networking, security, and observability without iptables overhead.
**Interview point:** If asked which CNI you'd choose for a new cluster, Calico or Cilium are the modern industry standards due to security (policies) and performance.

### Q8. What happens if a cluster has no CNI installed?
**Answer:** The cluster master components will run, but worker nodes will report a `NotReady` status with a `NetworkPluginNotReady` error, and Pods will remain in a `ContainerCreating` or `Pending` state.
**How it works:** The kubelet waits for the CNI to provide a network namespace and IP before it actually starts the application containers.
**Interview point:** This often happens in bare-metal setups right after `kubeadm init`. Installing a CNI is mandatory.

## D. kube-proxy

### Q9. What is kube-proxy and what is its main function? ⭐ MUST KNOW
**Answer:** `kube-proxy` is a network daemon that runs on *every* worker node, responsible for implementing Kubernetes Services.
**How it works:** It watches the API server for changes to Services and Endpoints. When a Service is created, `kube-proxy` writes local networking rules (usually iptables) on its node to route traffic from the Service's ClusterIP to the actual backend Pod IPs.
**Interview point:** `kube-proxy` manages Service-to-Pod routing, while CNI manages Pod-to-Pod routing.

### Q10. Does kube-proxy actually "proxy" network traffic? 🟠 IMPORTANT
**Answer:** In modern clusters, no. The name is historical.
**How it works:** Originally (in `userspace` mode), it acted as an actual proxy server. Now, in `iptables` or `ipvs` mode, it purely writes kernel routing rules. The Linux kernel itself handles the actual packet forwarding/proxying based on those rules.
**Interview point:** Mentioning that "kube-proxy just configures iptables, the Linux kernel does the routing" shows deep architectural understanding.

### Q11. What is the difference between kube-proxy iptables mode and IPVS mode?
**Answer:** `iptables` evaluates rules sequentially, while `IPVS` uses hash tables for routing.
**How it works:** If you have a Service with 1,000 backend Pods, `iptables` creates a massive, slow sequential list of rules. `IPVS` handles massive scale efficiently with O(1) lookup times and offers better load-balancing algorithms (like least connections).
**Interview point:** IPVS is preferred for massive clusters, though iptables is the default. Note that Cilium can replace `kube-proxy` entirely using eBPF.

## E. Kubernetes Services

### Q12. Why do we need Services if every Pod gets an IP? ⭐ MUST KNOW
**Answer:** Pod IPs are ephemeral. If a Pod crashes and is recreated, it gets a completely new IP address.
**How it works:** A Service provides a stable, persistent virtual IP (ClusterIP) and a stable DNS name. Clients connect to the Service, which dynamically balances traffic across the current healthy Pods.
**Interview point:** Services decouple the frontend clients from the highly dynamic backend Pod lifecycles.

### Q13. How does a Service know which Pods to route traffic to? ⭐ MUST KNOW
**Answer:** It uses a Label Selector.
**How it works:** When you define a Service, you specify a `selector` (e.g., `app: frontend`). The Service constantly scans the cluster for any healthy Pods possessing that exact label and adds their IPs to its rotation.
**Interview point:** Labels are the glue of Kubernetes. If your Service isn't routing, the first check is always verifying the Service selector perfectly matches the Pod labels.

### Q14. What are Endpoints (or EndpointSlices)? 🟠 IMPORTANT
**Answer:** An Endpoint resource is automatically created alongside a Service and stores the actual, current IP addresses of the matching backend Pods.
**How it works:**
```text
Client Pod
    ↓
Service (ClusterIP: 10.96.0.10)
    ↓ (kube-proxy uses Endpoints list to write iptables)
Endpoint [10.244.1.5, 10.244.2.8] -> Actual Pod IPs
```
**Interview point:** When troubleshooting "Service connection refused", check `kubectl get endpoints <svc>`. If it's empty, the label selector is wrong or the backend Pods are crashing/failing readiness probes.

### Q15. Can you create a Service without a selector?
**Answer:** Yes. This is called a "Headless" or selector-less Service.
**How it works:** Without a selector, Kubernetes does not automatically create an Endpoint object. You can manually create an Endpoint object with the same name to map the Service to external resources (like an external database IP).
**Interview point:** Useful for abstracting external legacy systems behind a native Kubernetes DNS name.

## F. Service Types

### Q16. Explain the ClusterIP Service type. ⭐ MUST KNOW
**Answer:** ClusterIP is the default service type. It provides a virtual IP that is strictly accessible *only from within the cluster*.
**How it works:**
```text
Internal Pod → ClusterIP Service (10.96.x.x) → Backend Pods
```
**Interview point:** Use this for internal microservices (like a backend API or a database) that should never be exposed directly to the internet.

### Q17. How does a NodePort service work? ⭐ MUST KNOW
**Answer:** NodePort exposes the Service on a static port (between 30000-32767) across the IP addresses of *every* worker node in the cluster.
**How it works:** It builds on top of ClusterIP. Traffic flow:
```text
External Client → Any NodeIP:NodePort → ClusterIP Service → Target Pod
```
**Interview point:** If a Pod is on Node A, hitting Node B's IP at the NodePort will still work, because kube-proxy routes it internally from Node B to Node A. It's primitive for production internet traffic but crucial for LoadBalancers.

### Q18. How does a LoadBalancer Service work? ⭐ MUST KNOW
**Answer:** It automatically provisions a cloud provider's external load balancer (like AWS ALB or Azure Standard LB) to route internet traffic into the cluster.
**How it works:** It builds on top of NodePort.
```text
Internet → Cloud LB (Public IP) → NodeIP:NodePort → ClusterIP → Pod
```
**Interview point:** This only works if your cluster is running in an environment with a Cloud Controller Manager. On bare metal, a LoadBalancer service stays strictly in `<pending>` state unless you install tools like MetalLB.

### Q19. Compare ClusterIP, NodePort, and LoadBalancer. 🟠 IMPORTANT
**Answer:**
| Feature | ClusterIP | NodePort | LoadBalancer |
| :--- | :--- | :--- | :--- |
| **Reachability** | Internal Only | External (via Node IPs) | External (via Public IP) |
| **Port Mapping** | Any port | 30000-32767 | Cloud LB native ports (80/443) |
| **Dependency** | None | Builds on ClusterIP | Builds on NodePort |
| **Use Case** | Internal databases, APIs | Bare metal ingress, Dev testing | Prod external web traffic |
**Interview point:** Knowing they "stack" (LB creates a NodePort, which creates a ClusterIP) is a senior-level observation.

## G. DNS & Service Discovery

### Q20. How does Service Discovery via DNS work in Kubernetes? ⭐ MUST KNOW
**Answer:** Kubernetes runs a built-in DNS server (usually CoreDNS) that automatically creates DNS records for every Service created in the cluster.
**How it works:** When a Pod tries to resolve a hostname (e.g., `http://my-database`), its DNS query is intercepted and routed to CoreDNS, which returns the Service's ClusterIP.
**Interview point:** Every Pod gets configured automatically with a `/etc/resolv.conf` pointing to the CoreDNS service IP (usually `10.96.0.10`).

### Q21. What is the Fully Qualified Domain Name (FQDN) for a Service? 🟠 IMPORTANT
**Answer:** `<service-name>.<namespace>.svc.cluster.local`
**How it works:**
- If Frontend is in the `web` namespace and Backend is in the `api` namespace, Frontend must call `http://backend.api.svc.cluster.local`.
- If they are in the *same* namespace, Frontend can just call `http://backend`.
**Interview point:** Memorize this format. Cross-namespace communication failures are a very common interview troubleshooting scenario.

### Q22. Do individual Pods get DNS records?
**Answer:** Yes, but they are rarely used.
**How it works:** The format is `<pod-ip-with-dashes>.<namespace>.pod.cluster.local` (e.g., `10-244-1-5.default.pod.cluster.local`).
**Interview point:** Because Pods die and IPs change constantly, relying on Pod DNS is an anti-pattern. Always use Services for discovery.

## H. Complete Request Flow

### Q23. Describe the complete internal request flow: Frontend Pod calls Backend Service. ⭐ MUST KNOW
**Answer:**
```text
Frontend Pod (executes `curl http://backend:8080`)
    │ 1. DNS Query for "backend"
    ↓
CoreDNS (resolves to ClusterIP e.g., 10.96.0.50)
    │ 2. Request sent to 10.96.0.50:8080
    ↓
Node's kernel (iptables rules written by kube-proxy)
    │ 3. DNAT translates ClusterIP to an actual Pod IP
    ↓
Backend Pod (10.244.2.15:8080)
```
**Interview point:** Mentioning the translation from ClusterIP to actual Pod IP via iptables/kube-proxy is exactly what the interviewer is looking for.

### Q24. Describe the complete external flow: Internet user accesses a web app. ⭐ MUST KNOW
**Answer:**
```text
Internet User
    │ 1. Hits DNS / Public IP
    ↓
Cloud Load Balancer
    │ 2. Forwards to a Worker Node's IP on a NodePort (e.g., 31445)
    ↓
Node IP:31445
    │ 3. iptables (kube-proxy) translates to backend Pod IP
    ↓
Backend Pod Network (via CNI)
    │ 4. Arrives at isolated container
    ↓
Application Container
```
**Interview point:** This shows you understand how cloud infrastructure and Kubernetes infrastructure stitch together.

## I. Ingress

### Q25. What is the difference between an Ingress and a LoadBalancer Service? ⭐ MUST KNOW
**Answer:** A LoadBalancer Service operates at Layer 4 (TCP/UDP) and requires a separate cloud LB for *every* service. Ingress operates at Layer 7 (HTTP/HTTPS) and routes multiple services through a single entry point.
**How it works:** With Ingress, you can route `domain.com/api` to the backend-service and `domain.com/web` to the frontend-service, all using a single IP/LoadBalancer.
**Interview point:** Ingress saves cloud costs (1 LB instead of 10) and adds features like TLS termination and host/path routing.

### Q26. What is an Ingress Controller? 🟠 IMPORTANT
**Answer:** An Ingress resource is just a set of rules. An Ingress Controller is the actual application (like NGINX, Traefik, or AWS ALB Controller) that reads those rules and executes the routing.
**How it works:**
```text
Internet
    ↓
Ingress Controller (Exposed via a single LoadBalancer Service)
    ↓ (Reads Ingress Rules)
Routes to specific ClusterIP Services based on HTTP path/host
```
**Interview point:** A common trap: "I created an Ingress but it's not working." Answer: "Did you install an Ingress Controller? Ingress objects do nothing on their own."

### Q27. How does Ingress handle TLS/HTTPS?
**Answer:** Ingress handles TLS termination at the edge (the controller).
**How it works:** You store your SSL certificate in a Kubernetes `Secret`. The Ingress resource references this Secret. The Controller decrypts the HTTPS traffic and passes unencrypted HTTP traffic internally to your Services.
**Interview point:** Mention `cert-manager` as the standard tool to automate Let's Encrypt certificates for Ingress.

## J. NetworkPolicy

### Q28. What is a Kubernetes NetworkPolicy? ⭐ MUST KNOW
**Answer:** It acts as an internal firewall for your Pods, controlling which Pods can communicate with each other.
**How it works:** By default, Kubernetes is completely open: any Pod can talk to any Pod. A NetworkPolicy uses label selectors to restrict Ingress (incoming) and Egress (outgoing) traffic.
**Interview point:** Vital for DevSecOps. If a frontend Pod is compromised, a NetworkPolicy prevents it from reaching the database directly.

### Q29. If you create a NetworkPolicy, why might it not actually enforce rules? 🟠 IMPORTANT
**Answer:** NetworkPolicies are implemented by the CNI, not Kubernetes itself. If your CNI does not support them (e.g., Flannel), the API server will accept the object, but it will be ignored.
**How it works:** You must use a CNI like Calico, Cilium, or Weave to enforce policies.
**Interview point:** This is a classic "gotcha" question that proves real-world experience.

### Q30. How do you implement a "default deny" posture for a namespace? ⭐ MUST KNOW
**Answer:** You create a NetworkPolicy that selects all Pods (`podSelector: {}`) in a namespace and provides empty ingress/egress rules.
**How it works:**
```text
Frontend → (DENIED by default) → Database
Frontend → (explicitly ALLOWED by 2nd policy) → Backend → (ALLOWED) → Database
```
**Interview point:** Best practice in production is default deny all, then explicitly allow only necessary communication pathways.

## K. Networking Troubleshooting Scenarios

### 🎯 Scenario 1: Pod A cannot communicate with Pod B
**Causes:** NetworkPolicy blocking traffic, target Pod crashed, or CNI issues.
**Checks:** Check if target Pod is Running. Check if any NetworkPolicy restricts the namespace.
**Commands:**
```bash
kubectl get pods -o wide
kubectl exec -it <pod-a> -- ping <pod-b-ip>
kubectl get networkpolicy -n <namespace>
```

### 🎯 Scenario 2: Pods on the same node work, different nodes don't
**Causes:** CNI misconfiguration, host firewall blocking CNI ports (like VXLAN 8472 or BGP 179), or overlay network failure.
**Checks:** Verify CNI pods (e.g., calico-node or flannel) are running on all worker nodes. Check node firewalls/security groups.
**Commands:**
```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl logs <cni-pod-on-failing-node>
```

### 🎯 Scenario 3: Pod reaches Pod IP directly, but not via Service
**Causes:** The Service selector doesn't match the Pod labels, or kube-proxy is failing on the node.
**Checks:** Compare the Service selector with the Pod labels exactly. Check if Endpoints exist.
**Commands:**
```bash
kubectl get svc <service-name> -o yaml
kubectl get pods --show-labels
kubectl get endpoints <service-name>
```

### 🎯 Scenario 4: Service has no endpoints
**Causes:** Misspelled label selector, or backend Pods are failing their `ReadinessProbe`.
**Checks:** If Pods fail readiness, they are removed from the Endpoints list even if they are 'Running'.
**Commands:**
```bash
kubectl describe pod <backend-pod> # Look for Readiness probe failed events
kubectl get endpoints <service-name>
```

### 🎯 Scenario 5: Service DNS not resolving (nslookup fails)
**Causes:** CoreDNS pods are down, CoreDNS service is deleted, or the Pod's `/etc/resolv.conf` is broken.
**Checks:** Verify CoreDNS is running in `kube-system`. Test a fully qualified domain name.
**Commands:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl exec -it <pod> -- nslookup kubernetes.default.svc.cluster.local
```

### 🎯 Scenario 6: DNS resolves correctly, but connection fails/times out
**Causes:** NetworkPolicy blocking the port, application listening on `127.0.0.1` instead of `0.0.0.0`, or target container crashed.
**Checks:** Ensure the app inside the container is bound to `0.0.0.0`. If bound to localhost, traffic from other Pods will be rejected.
**Commands:**
```bash
kubectl exec -it <backend-pod> -- netstat -plnt # verify listening on 0.0.0.0
```

### 🎯 Scenario 7: ClusterIP works internally, but LoadBalancer is unreachable
**Causes:** Cloud provider quota hit, LoadBalancer stuck in pending, or Security Group/Firewall blocking external traffic.
**Checks:** Look for the External-IP. If it says `<pending>`, the cloud-controller-manager is failing to provision it.
**Commands:**
```bash
kubectl get svc
kubectl describe svc <loadbalancer-service> # Look for SyncLoadBalancerFailed events
```

### 🎯 Scenario 8: Ingress returns 502 Bad Gateway or 503 Service Unavailable
**Causes:** 502 = Ingress Controller cannot connect to the internal Service (wrong port, backend crashed). 503 = Ingress Controller found the Service but it has zero Endpoints.
**Checks:** Verify the Ingress rule port matches the Service port exactly. Check Service endpoints.
**Commands:**
```bash
kubectl describe ingress <ingress-name>
kubectl get endpoints <target-service>
kubectl logs -n <ingress-namespace> <ingress-controller-pod>
```

---

### Quick Reference: The Full Stack
1. **Network Namespace:** Isolates container network.
2. **veth Pair:** Connects container namespace to host node.
3. **CNI:** Routes traffic between different host nodes.
4. **kube-proxy:** Translates virtual Service IPs to physical Pod IPs.
5. **CoreDNS:** Translates Service Names to virtual Service IPs.
6. **Ingress:** Translates external HTTP routes to virtual Service IPs.
