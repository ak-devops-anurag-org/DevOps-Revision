# Azure Compute Services - Interview Revision Notes

## 📊 Compute Decision Matrix
| Service | Type | Best For | OS Management | Scaling |
|---|---|---|---|---|
| **VMs** | IaaS | Lift & shift, custom OS/software, legacy apps | Customer | Manual / VMSS |
| **App Service** | PaaS | Web apps, APIs, custom domains, simple deployments | Azure | Auto (Scale Out/Up) |
| **AKS** | CaaS | Microservices, complex orchestration, Kubernetes native | Azure (Control), Cust (Nodes)| Cluster Autoscaler / HPA |
| **Functions** | Serverless | Event-driven, short-lived tasks, background jobs | Azure | Event-driven Auto |
| **ACI** | CaaS | Fast, isolated container runs, burst compute | Azure | N/A (Single Instance) |
| **Container Apps** | Serverless CaaS | Microservices without K8s complexity, KEDA scaling | Azure | Auto (Scale to zero) |

---

## 1. Azure Virtual Machines (VMs)

### Q: How do you ensure high availability for Azure VMs?
**Short answer:** By using Availability Sets (99.95% SLA) or Availability Zones (99.99% SLA) to protect against hardware and datacenter failures.
**Key Points:**
- **Fault Domains (FD):** Physical racks (power/network). Protects against rack failures.
- **Update Domains (UD):** Logical reboot groups. Protects against host patching downtime.
- **Availability Zones (AZ):** Physically separate datacenters within a region.
**Example:** Placing 2 web servers in an Availability Set ensures they are in different Fault and Update domains, so a single rack failure won't take down the app.
**Interview tip:** ⚠️ **INTERVIEW TRAP:** Don't confuse FDs and UDs. FD = physical hardware (rack/power). UD = logical patching groups.

### Q: What is a Virtual Machine Scale Set (VMSS)?
⭐ **MUST KNOW**
**Short answer:** A service to create and manage a group of load-balanced VMs that scale out/in automatically based on demand or a schedule.
**Key Points:**
- Supports manual, schedule-based, and metric-based scaling (e.g., CPU > 75%).
- All VMs in a VMSS are created from the same base OS image and configuration.
- Integrates seamlessly with Azure Load Balancer and Application Gateway.

### Q: When should you use Spot VMs vs Reserved Instances?
**Short answer:** Spot VMs are for cheap, interruptible workloads, while Reserved Instances are for predictable, long-term, continuous workloads.
**Key Points:**
- **Spot VMs:** Up to 90% discount. Azure can evict them with 30 seconds' notice. Great for batch processing, dev/test.
- **Reserved Instances (RI):** 1- or 3-year commitment. Up to 72% discount. Great for production databases and 24/7 apps.

### Q: What is Azure Dedicated Host?
**Short answer:** A physical server dedicated solely to your Azure subscription, providing hardware isolation at the host level.
**Key Points:**
- Used for strict compliance, regulatory requirements, and specific licensing (e.g., Windows Server/SQL Server hybrid benefits).

> [!TIP]
> **CLI - Create a VM:**
> ```bash
> az vm create --resource-group MyRG --name MyVM --image Ubuntu2204 --admin-username azureuser --generate-ssh-keys
> ```

---

## 2. Azure App Service

### Q: What is an App Service Plan and what does it define?
🟠 **IMPORTANT**
**Short answer:** It represents the underlying compute resources (VMs) that run your web apps. It defines the region, instance size, and pricing tier.
**Key Points:**
- Multiple App Services can run on a single App Service Plan to save costs.
- Defines features like custom domains, TLS/SSL, and auto-scaling capabilities.
- **Scale Up:** Upgrading the tier (e.g., Standard to Premium) for more CPU/RAM.
- **Scale Out:** Adding more VM instances to handle higher traffic.

### Q: What are Deployment Slots in App Service?
**Short answer:** Live web apps with their own hostnames used to stage deployments before swapping them into production.
**Key Points:**
- Enables zero-downtime deployments (Blue-Green deployment).
- Warms up instances before swapping to avoid cold starts.
- Allows traffic routing (e.g., sending 10% of users to the staging slot for canary testing).

### Q: What are WebJobs?
**Short answer:** A feature of App Service that runs background scripts or executables (.cmd, .bat, .ps1, .py) continuously or on a schedule.

---

## 3. Azure Kubernetes Service (AKS)

### Q: Explain the architecture of AKS.
⭐ **MUST KNOW**
**Short answer:** AKS splits K8s into a fully Azure-managed Control Plane (free) and customer-managed Worker Nodes (billed as VMs/VMSS).
**Key Points:**
- Azure manages: API server, etcd, Scheduler, Controller Manager.
- You manage: Node Pools (VMSS running kubelet, container runtime, kube-proxy).
- Integrates with Azure Entra ID (AD) for RBAC.

```text
[ Azure-Managed Control Plane ]
  |-- API Server, etcd, Scheduler, Controller
  |
  +-- (Secure Tunnel) --+
                        |
[ Customer VNet ] (See 04_networking.md for CNI vs Kubenet)
  |-- Node Pool (VMSS)
       |-- Node 1 (Kubelet, Kube-proxy, containerd, Pods)
       |-- Node 2 (Kubelet, Kube-proxy, containerd, Pods)
```

### Q: How does scaling work in AKS?
**Short answer:** AKS scales at two levels: Pod level (HPA) and Node level (Cluster Autoscaler).
**Key Points:**
- **Horizontal Pod Autoscaler (HPA):** Adds more pod replicas based on CPU/Memory metrics.
- **Cluster Autoscaler:** Adds more nodes (VMs) to the VMSS when pods cannot be scheduled due to resource constraints.

### Q: Kubenet vs Azure CNI in AKS?
**Short answer:** Kubenet uses overlay networking (NAT), while Azure CNI assigns native VNet IPs to every pod.
**Interview tip:** Mention that Azure CNI requires careful IP address planning to avoid VNet exhaustion. *(See `04_networking.md` for deep dive).*

> [!TIP]
> **CLI - Create an AKS Cluster:**
> ```bash
> az aks create --resource-group MyRG --name MyAKSCluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
> ```

---

## 4. Azure Functions

### Q: What are Triggers and Bindings in Azure Functions?
🟠 **IMPORTANT**
**Short answer:** Triggers cause a function to run, while bindings are declarative ways to connect data inputs and outputs without writing boilerplate code.
**Key Points:**
- **Triggers:** HTTP, Timer, Blob storage, Service Bus queue, Event Grid. (A function must have exactly ONE trigger).
- **Bindings:** Input (read from CosmosDB) and Output (write to Queue).

### Q: How do you choose between Consumption, Premium, and Dedicated plans?
**Short answer:** Consumption is true serverless (pay-per-execution), Premium prevents cold starts, and Dedicated reuses existing App Service Plans.
**Key Points:**
- **Consumption:** Scales to zero. Has Cold Start issues. Max execution time is 10 mins (default 5).
- **Premium:** Pre-warmed instances (no cold start), VNet integration, longer execution time.
- **Dedicated (App Service):** Best if you already have underutilized App Service Plans.

### Q: What is a "Cold Start" and how do you mitigate it?
**Short answer:** The delay experienced when a serverless function is invoked after being idle, as Azure spins up a new instance.
**Example:** An HTTP function taking 5 seconds to return the first request, but 50ms for subsequent ones.
**Mitigation:** Use the Premium Plan (pre-warmed instances) or keep it warm with a timer trigger (hacky/not recommended).

> [!TIP]
> **CLI - Deploy Azure Function (Core Tools):**
> ```bash
> func azure functionapp publish MyFunctionAppName
> ```

---

## 5. Container Services (ACI & Container Apps)

### Q: Azure Container Instances (ACI) vs AKS?
**Short answer:** ACI is for running isolated containers instantly without managing VMs or K8s. AKS is for complex microservices requiring orchestration, discovery, and scaling.
**Interview tip:** ACI is often used as a "Virtual Node" in AKS for sudden bursting without waiting for new VMs to spin up.

### Q: What are Azure Container Apps (ACA)?
**Short answer:** A fully managed serverless container service built on top of AKS and KEDA, designed for microservices without K8s management overhead.
**Key Points:**
- Supports scale-to-zero.
- Natively supports KEDA (Kubernetes Event-driven Autoscaling) and Dapr (Distributed Application Runtime).
- Best when you want microservices and K8s features but don't want to manage a cluster.

---

## 6. Azure Batch
### Q: When should you use Azure Batch?
**Short answer:** For large-scale parallel and high-performance computing (HPC) batch jobs.
**Key Points:**
- Azure automatically provisions, manages, and schedules a pool of compute nodes (VMs).
- Ideal for 3D rendering, video encoding, financial risk modeling, or processing millions of images.

---

## 🎯 Scenario Questions

### Scenario 1: Choosing the Right Compute
**Question:** A client wants to migrate a monolithic Java API to Azure. They want minimal management overhead, built-in TLS, custom domains, and auto-scaling based on HTTP traffic. They do not want to manage OS patching. What do you recommend?
**Answer:** Azure App Service.
**Why:** It is a PaaS offering perfect for web APIs, handles OS patching automatically, supports custom domains/TLS natively, and scales out based on HTTP metrics. VMs require OS management. AKS is overkill for a simple monolith. Functions would require refactoring the monolith into serverless components.

### Scenario 2: AKS Troubleshooting (Pending Pods)
**Question:** You deployed a new microservice to AKS, but the pods are stuck in the `Pending` state. How do you troubleshoot this?
**Answer:** I would first run `kubectl describe pod <pod-name>` and look at the "Events" section.
**Key Points:**
- Common cause 1: Insufficient cluster resources (CPU/Memory) - the Scheduler cannot find a node to place the pod. (Fix: Enable Cluster Autoscaler or add nodes).
- Common cause 2: Misconfigured Node Selectors, Taints, or Tolerations preventing scheduling.
- Common cause 3: (If using Azure CNI) VNet IP exhaustion. The pod cannot get an IP address. *(Cross-ref: 04_networking.md)*.
