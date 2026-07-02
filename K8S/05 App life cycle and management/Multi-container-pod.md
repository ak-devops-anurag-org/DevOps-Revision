Here is a highly condensed summary of multi-container pods and their core patterns.

### **The Core Concept**

A multi-container pod groups tightly coupled containers onto the same node. Instead of running isolated, they share:

* **Network:** Instant communication via `localhost`.
* **Storage:** Simultaneous read/write access to the exact same volumes.
* **Lifecycle:** They start, run, and terminate together.

---

### **The 3 Main Patterns**

| Pattern | Primary Role | Real-World K8s Use Case |
| --- | --- | --- |
| **Sidecar** | Background Helper | Enhancing the main app without changing its code (e.g., a Fluent-bit container reading app logs and forwarding them to Pub/Sub). |
| **Ambassador** | Network Proxy | Handling complex external routing locally (e.g., a Cloud SQL Auth Proxy container managing a secure database tunnel). |
| **Adapter** | Output Translator | Standardizing data formats (e.g., converting legacy application metrics into standard Prometheus metrics for scraping). |

---

### **Implementation Key (YAML)**

Here is the quick, simplified revision guide for multi-container pod patterns.

### The Core Concept

A multi-container pod runs multiple containers on the same node. They share the same **Network** (`localhost`) and the same **Storage Volumes**. You use this when a main application needs a tightly coupled "helper."

---

### 1. The Sidecar Pattern (The Background Helper)

* **What it does:** A secondary container that enhances the main container without changing its code. Usually handles background tasks like logging, syncing files, or security scanning.
* **Real-World Scenario:** Your main Corporate Employee Portal (CEP) container writes access logs to a temporary folder. The Sidecar container (e.g., Fluent-bit) sits in the same pod, reads that exact folder, and continuously streams those logs out to a central Pub/Sub topic for auditing.

### 2. The Ambassador Pattern (The Network Proxy)

* **What it does:** A secondary container that acts as a local network proxy. The main app thinks it is talking to a simple local service, but the ambassador handles the complex external routing and security.
* **Real-World Scenario:** Connecting to a Cloud SQL PostgreSQL database. Instead of writing complex TLS/SSL authentication code into your app, you add the Cloud SQL Auth Proxy as an Ambassador container. Your app simply connects to `localhost:5432`, and the proxy handles the secure, encrypted tunnel to GCP.

### 3. The Adapter Pattern (The Translator)

* **What it does:** A secondary container that standardizes the main container's output before sending it to a central monitoring system.
* **Real-World Scenario:** A legacy banking application outputs performance metrics in a weird, proprietary format. The Adapter container reads that output, converts it into standard Prometheus metrics, and exposes it so the cluster's monitoring tools can scrape it easily.

---

### YAML Example: The Sidecar Pattern

Here is a simplified example of a Sidecar setting up shared log storage.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cep-app-with-logging-sidecar
spec:
  # 1. The shared folder both containers will use
  volumes:
  - name: shared-logs
    emptyDir: {} 

  containers:
  # 2. MAIN APP: Writes logs to the shared folder
  - name: cep-main-app
    image: my-company/cep-app:v1
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app 

  # 3. SIDECAR: Reads logs from the exact same shared folder
  - name: log-forwarder
    image: fluent/fluent-bit:latest
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/app 

```

To make these patterns work (especially the Sidecar), the YAML configuration relies on **Shared Volumes**:

1. Define a shared volume (e.g., `emptyDir: {}`) at the Pod level under `spec.volumes`.
2. Map that identical volume into both containers using `volumeMounts` and the same `mountPath`.

This ensures both the primary application and the helper container are looking at the exact same directory on the underlying node.