# Kubernetes CNI and Networking Revision Guide

## CNI Fundamentals

### What is CNI?
**Container Network Interface (CNI)** - CNCF specification for dynamic networking resource configuration in container environments. Uses libraries and specifications written in Go for configuring network interfaces in Linux containers.[1][2]

**Key CNI Requirements:**
- Pod gets unique cluster-wide IP address[3]
- Containers in same pod share network namespace and communicate via localhost[4]
- Pod-to-pod communication without NAT across cluster[5][6]
- CNI plugin configures network interface and assigns IP via IPAM[7][8]

```bash
# Check CNI plugin configuration
ls /opt/cni/bin/
ls /etc/cni/net.d/
```

### CNI vs Kube-proxy

**CNI Plugin** - Provides network connectivity between containers/pods :[9][10]
- Assigns IP addresses to pods
- Handles network interface creation (veth pairs)
- Manages pod-to-pod communication
- Implements NetworkPolicies (if supported)

**Kube-proxy** - Network proxy and load balancer for Service-to-Pod communication :[11][9]
- Translates Service IP to Pod IPs using iptables/IPVS
- Provides service discovery and load balancing
- Runs on each node as component
- No direct role in pod networking

```bash
# Check kube-proxy configuration
kubectl get configmap kube-proxy -n kube-system -o yaml
kubectl describe daemonset kube-proxy -n kube-system
```

## CNI Plugin Types and Comparison

### Popular CNI Plugins

| Plugin | Architecture | Performance | NetworkPolicy | Use Case |
|--------|--------------|-------------|---------------|----------|
| **Calico** [12][13] | BGP/IPIP/VXLAN | High | ✅ Full support | Large clusters, security-focused |
| **Flannel** [13][14] | VXLAN overlay | Good | ❌ No support | Simple setups, small-medium clusters |
| **Cilium** [12][13] | eBPF-based | Highest | ✅ Advanced L7 | Complex microservices, observability |
| **Weave** [14] | Overlay network | Moderate | ✅ Basic support | Easy deployment |

```bash
# Check current CNI plugin
kubectl get nodes -o wide
kubectl get daemonset -n kube-system
ls /etc/cni/net.d/
```

### CNI Plugins Without NetworkPolicy Support
**Flannel** - Does not natively support NetworkPolicies. Policy enforcement requires additional solutions:[15][16][17]
- Deploy Calico for policy enforcement only
- Use third-party policy engines
- Implement cloud provider security groups

```bash
# Verify NetworkPolicy support
kubectl api-resources | grep networkpolicies
kubectl get networkpolicies --all-namespaces
```

## Pod Networking Architecture

### Pod IP Assignment Process
1. **kube-controller-manager** assigns podCIDR to each node[8]
2. **CNI plugin** assigns pod IP from node's podCIDR subnet
3. **Pause container** holds network namespace for pod[18]
4. All containers in pod share same IP and network namespace[4]

```bash
# Check node podCIDR
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
kubectl describe node <node-name> | grep PodCIDR
```

### Pod-to-Pod Communication

#### Same Node Communication[19][20]
Traffic flow: Pod1 → veth → Bridge → veth → Pod2
- Uses Linux bridge (cbr0/cni0) for local routing
- Bridge checks connected devices for target IP match
- Direct forwarding via matched veth interface

```bash
# Inspect pod networking
kubectl exec -it <pod> -- ip addr show
kubectl exec -it <pod> -- ip route
# On node
ip link show type veth
brctl show
```

#### Different Nodes Communication[19]
Traffic flow: Pod1 → Bridge → Default Gateway → Cluster Network → Target Node → Bridge → Pod2
- Bridge forwards to default gateway when no local match
- Cluster network routes based on node podCIDR ranges  
- Target node bridge forwards to correct pod veth

```bash
# Check inter-node routing
kubectl get nodes -o wide
ip route | grep <pod-cidr>
# Test connectivity
kubectl exec -it <pod> -- ping <target-pod-ip>
```

## CNI Configuration Paths

### Standard CNI Paths
- **Plugin Binaries**: `/opt/cni/bin/`[21][22][23]
- **Configuration**: `/etc/cni/net.d/`[22][23][21]
- **Custom paths**: Check kubelet args `--cni-bin-dir` and `--cni-conf-dir`[21]

```bash
# Find CNI paths
ps aux | grep kubelet | grep cni
# Check default locations
ls -la /opt/cni/bin/
ls -la /etc/cni/net.d/
```

### CNI Deployment Model
**Most CNI plugins deploy as DaemonSet** - one pod per node :[24][25][4]
- Ensures CNI binary and config on every node
- Runs with elevated privileges for network configuration
- Examples: aws-node, calico-node, cilium, flannel

```bash
# Check CNI DaemonSets
kubectl get daemonset -n kube-system
kubectl describe daemonset <cni-daemonset> -n kube-system
```

## Pod Subnets and CIDR

### Pod Subnet Management
- **Cluster-wide pod CIDR**: Defined at cluster creation (`--pod-network-cidr`)[26][8]
- **Node podCIDR**: Unique subnet per node from cluster CIDR[8]
- **Pod IPs**: Assigned from node's podCIDR by CNI plugin[8]

```bash
# Check cluster CIDR configuration  
kubectl cluster-info dump | grep -i cidr
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | tr ' ' '\n'
```

### Default CNI During Cluster Creation
- **kubeadm**: No default CNI - requires manual installation[27]
- **Managed services**: Cloud providers install default CNI
- **Cluster ready**: Nodes stay NotReady until CNI installed[27]

```bash
# Create cluster without CNI
kubeadm init --pod-network-cidr=10.244.0.0/16
# Apply CNI after cluster creation
kubectl apply -f <cni-manifest.yaml>
```

## NetworkPolicies and CNI

### NetworkPolicy Requirements
**CNI must support NetworkPolicies** - Policy enforcement depends on CNI implementation :[28][16]
- Creating NetworkPolicy without supporting CNI has no effect[15]
- Policies are namespaced and additive[28]
- Requires both ingress and egress policies for bidirectional communication[28]

```bash
# Check NetworkPolicy support
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy <policy-name>
# Test policy with network tools pod
kubectl run netshoot --rm -it --image nicolaka/netshoot
```

### CNI NetworkPolicy Support Matrix
- ✅ **Calico**: Full NetworkPolicy + Calico Network Policies[29][28]
- ✅ **Cilium**: Advanced L7 policies with eBPF[28]
- ❌ **Flannel**: No native NetworkPolicy support[16][17]
- ✅ **Weave**: Basic NetworkPolicy support[13]

## Networking Commands Reference

### Cluster and Node Information
```bash
# Cluster information
kubectl cluster-info
kubectl cluster-info dump
kubectl get nodes -o wide
kubectl describe node <node-name>

# CNI detection
ls /opt/cni/bin/
ls /etc/cni/net.d/
kubectl get daemonset -n kube-system
ps aux | grep kubelet | grep -E "(cni|network)"
```

### Pod Networking
```bash
# Pod network information
kubectl get pods -o wide --all-namespaces
kubectl describe pod <pod-name>
kubectl exec -it <pod> -- ip addr show
kubectl exec -it <pod> -- ip route
kubectl exec -it <pod> -- cat /etc/resolv.conf

# Pod connectivity testing
kubectl exec -it <pod> -- ping <target-ip>
kubectl exec -it <pod> -- nslookup <service-name>
kubectl exec -it <pod> -- curl <service-url>
```

### Service Networking
```bash
# Service information
kubectl get services --all-namespaces
kubectl describe service <service-name>
kubectl get endpoints <service-name>

# kube-proxy configuration
kubectl get configmap kube-proxy -n kube-system -o yaml
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

### NetworkPolicy Management
```bash
# NetworkPolicy operations
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy <policy-name>
kubectl apply -f <networkpolicy.yaml>
kubectl delete networkpolicy <policy-name>

# Policy testing
kubectl run test-pod --rm -it --image nicolaka/netshoot
kubectl exec -it <pod> -- nc -zv <target-ip> <port>
```

### Troubleshooting and Debugging
```bash
# Network troubleshooting pod
kubectl run netshoot --rm -it --image nicolaka/netshoot
kubectl debug node/<node-name> -it --image nicolaka/netshoot

# DNS debugging
kubectl run -it --rm debug --image=tutum/dnsutils --restart=Never
kubectl exec -it <pod> -- nslookup kubernetes.default
kubectl logs -n kube-system -l k8s-app=kube-dns

# Event and log analysis
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl logs -n kube-system <cni-pod-name>
kubectl describe pod <pod-name> | grep -A5 Events
```

### Advanced Network Inspection
```bash
# Node-level networking (run on nodes)
ip link show type veth
ip route | grep <pod-cidr>
brctl show
iptables -t nat -L KUBE-SERVICES
ipvsadm -Ln (if using IPVS mode)

# Container network namespace
docker inspect <container-id> | grep NetworkMode
nsenter -t <container-pid> -n ip addr
```

### CNI Plugin Specific Commands
```bash
# Calico
kubectl get ippools
calicoctl get nodes
calicoctl get workloadendpoints

# Cilium  
cilium status
cilium connectivity test
kubectl exec -n kube-system <cilium-pod> -- cilium endpoint list

# Flannel
kubectl get configmap kube-flannel-cfg -n kube-system -o yaml
```

***
