# Kubernetes Core Concepts: Complete Revision Notes

## 1. Docker vs. Kubernetes
* **Docker:** A container engine. It is the tool you use to build container images and run them on a single machine. 
* **Kubernetes (K8s):** A container orchestration platform. It spans across multiple machines to manage, scale, and heal thousands of containers. 
* **The Difference:** Docker creates the containers; Kubernetes manages them. (Note: K8s can orchestrate containers made by tools other than Docker).

---

## 2. Cluster Architecture
A Kubernetes cluster is divided into two main sections:
* **Control Plane (Master Nodes):** The brain. It manages the cluster, makes scheduling decisions, and monitors state.
* **Worker Nodes:** The muscle. These are the virtual or physical machines that actually run your application payloads (Pods).

---

## 3. Docker vs. ContainerD
* **Docker:** A full suite of tools for building and sharing containers, which includes a runtime.
* **ContainerD:** The industry-standard core container runtime that was originally extracted from Docker. 
* **The K8s Shift:** Kubernetes used to rely on Docker (via "Dockershim"). Now, K8s communicates directly with **ContainerD** using the Container Runtime Interface (CRI). This makes K8s faster and less bloated. (You still use Docker to *build* your images, and K8s/ContainerD will happily run them).

---

## 4. Control Plane Components (The Brains)

### ETCD
* **What it is:** A highly available, distributed key-value store.
* **Role:** The absolute source of truth for the cluster. It stores all cluster data, configurations, and the current state of all resources.
* **Key Point:** If ETCD dies and you have no backup, your cluster is gone. It usually runs on port `2379`.

### Kube-API Server
* **What it is:** The front-end and gatekeeper of the control plane.
* **Role:** Every single command you run (via `kubectl`) or internal component communication goes through the API server. It authenticates users, validates requests, and updates ETCD.

### Kube Controller Manager
* **What it is:** A continuous control loop that watches the cluster's state.
* **Role:** It compares the **Desired State** (what you asked for) with the **Current State** (what is actually running) and works to fix any differences.
* **Types:**
  * **Node Controller:** Watches for nodes crashing or going offline.
  * **Replication Controller:** Ensures the correct number of Pods are running.
  * **Endpoints Controller:** Links Services to Pods.

### Kube Scheduler
* **What it is:** The decision-maker for placing Pods.
* **Role:** When you create a new Pod, the Scheduler looks for the best Worker Node to run it on based on CPU/RAM requirements, Taints/Tolerations, and Node Affinity rules. It does *not* start the Pod; it just tells the node to do it.

---

## 5. Worker Node Components (The Muscle)

### Kubelet
* **What it is:** The primary agent ("captain") running on every worker node.
* **Role:** It registers the node with the cluster, listens for instructions from the Kube-API Server, and tells the container runtime (like ContainerD) to pull images and start/stop containers.

### Kube Proxy
* **What it is:** A network routing agent on each node.
* **Role:** It maintains network rules (usually using `iptables` or `IPVS`) to allow network communication to your Pods from inside or outside the cluster.

---

## 6. Pods
* **What it is:** The smallest, most basic deployable unit in Kubernetes. K8s does not run containers directly; it wraps them in Pods.
* **Key Point:** A Pod usually contains one container. However, it can contain multiple containers (like a main app and a logging "sidecar") that share the same storage volumes and local network IP.

**Example `pod.yaml`**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod
  labels: # Labels used to identify the pod
    app: frontend
    env: prod
spec:
  containers:
  - name: nginx-container
    image: nginx:1.24
    ports:
    - containerPort: 80
```

---

## 7. Labels and Selectors
* **Labels:** Sticky notes (key-value pairs) you attach to resources. Example: `tier: backend`.
* **Selectors:** The search query used by other K8s components to find labeled resources. 
* **Why it matters:** A Service uses a Selector to find which Pods to send traffic to. A Deployment uses a Selector to know which Pods it manages.

---

## 8. ReplicaSets vs. Deployments

### ReplicaSet (The Set)
* **Role:** Guarantees that a specific number of identical Pods (replicas) are running at all times. If you want 3 Pods and one node dies, the ReplicaSet spins up a new Pod on another node.
* **Note:** You almost never create a ReplicaSet manually.

### Deployment (The Controller)
* **Role:** A higher-level object that wraps a ReplicaSet. It adds the ability to update your application smoothly without downtime, or roll back to older versions.

### Deployment Strategies
* **RollingUpdate (Default):** Slowly replaces old Pods with new ones one by one. **Pro:** Zero downtime. **Con:** Takes time, and two versions of your app run simultaneously for a brief period.
* **Recreate:** Kills all old Pods first, then creates all new Pods. **Pro:** Clean state, no version overlap. **Con:** Causes application downtime.

**Example `deployment.yaml` (with strategy)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  strategy:
    type: RollingUpdate # Or 'Recreate'
    rollingUpdate:
      maxSurge: 1       # How many extra pods can be created during update
      maxUnavailable: 1 # How many pods can be taken down during update
  template: # This is the Pod definition!
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: my-app
        image: nginx:1.25
        ports:
        - containerPort: 80
```

---

## 9. Services
Pods are mortal—they die and get new IP addresses constantly. A **Service** provides a stable, permanent IP address and DNS name that routes traffic to your Pods (found via Selectors).

### Service Types
1. **ClusterIP (Default):** Exposes the app only *inside* the K8s cluster.
2. **NodePort:** Opens a specific static port (between `30000-32767`) on every single Worker Node's IP. Used for external access.
3. **LoadBalancer:** Requests a public Cloud Load Balancer (from AWS/GCP/Azure) to route internet traffic down to your NodePorts.
4. **ExternalName:** Acts as a DNS alias. Routes internal cluster traffic to an external URL (e.g., an external database).

**Example `service-nodeport.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend # Routes traffic to Pods with this label
  ports:
    - port: 80        # The port the Service exposes internally
      targetPort: 80  # The port the Container is listening on
      nodePort: 30005 # The port opened on the host Worker Nodes
```

---

## 10. CNI vs. Kube Proxy
Both deal with networking, but at different layers:

* **CNI (Container Network Interface):** The "Plumber." (e.g., Calico, Flannel). It is responsible for giving Pods their IP addresses and physically routing traffic so a Pod on Node A can talk to a Pod on Node B.
* **Kube Proxy:** The "Traffic Cop." It doesn't give out IPs. It manages the rules for **Services**. When traffic hits a stable Service IP, Kube Proxy's rules (iptables) translate that Service IP into the actual IP of the backend Pods that the CNI set up.
```
