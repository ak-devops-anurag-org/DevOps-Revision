# Azure Cloud — Interview Questions

## Table of Contents

1. [Core Concepts & Fundamentals](#1-core-concepts--fundamentals)
2. [Identity & Access Management](#2-identity--access-management)
3. [Compute Services](#3-compute-services)
4. [Networking](#4-networking)
5. [Storage & Databases](#5-storage--databases)
6. [Monitoring & Governance](#6-monitoring--governance)
7. [Security & Reliability](#7-security--reliability)
8. [Advanced Services & Architecture](#8-advanced-services--architecture)
9. [Scenario-Based Questions](#9-scenario-based-questions)
10. [Rapid-Fire Questions](#10-rapid-fire-questions)

## 1. Core Concepts & Fundamentals

### 1.1. Explain the differences between IaaS, PaaS, and SaaS with Azure examples.
**Short answer:** 
- **IaaS (Infrastructure as a Service):** You manage OS, runtime, and apps. Microsoft manages physical hardware. Example: Azure Virtual Machines.
- **PaaS (Platform as a Service):** You manage apps and data. Microsoft manages OS, runtime, and infra. Example: Azure App Service, Azure SQL Database.
- **SaaS (Software as a Service):** You manage access and config. Microsoft manages everything else. Example: Microsoft 365.

**Key Points:** Focus on the "shared responsibility model" shift.
**Interview tip:** Be ready to map a traditional on-prem app to an Azure PaaS alternative.

### 1.2. What are Regions, Availability Zones, and Region Pairs in Azure?
**Short answer:** 
- **Region:** A geographical area containing one or more datacenters.
- **Availability Zone (AZ):** Physically separate datacenters within a region with independent power, cooling, and networking. Protects against datacenter failure.
- **Region Pair:** Two regions within the same geography, separated by at least 300 miles (e.g., East US and West US). Used for disaster recovery and sequential updates.

**Key Points:** Updates are rolled out to one region in a pair before the other.

### 1.3. Explain the Azure Resource Hierarchy.
**Short answer:** It's a top-down structure for managing access, policies, and billing.
- **Management Groups:** Group subscriptions to apply policies/RBAC at scale.
- **Subscriptions:** Billing and administrative boundary.
- **Resource Groups:** Logical containers grouping resources sharing a lifecycle.
- **Resources:** The actual services (VMs, VNets).

**Key Points:** RBAC and Azure Policies flow down the hierarchy (inheritance).

### 1.4. What is Azure Resource Manager (ARM) and what are ARM templates?
**Short answer:** ARM is the deployment and management service for Azure. It provides a unified management layer (API) to create, update, and delete resources. ARM templates are JSON files defining the infrastructure and configuration for your project (Infrastructure as Code - IaC).

**Key Points:** Idempotency is key — deploying the same template multiple times produces the same state.

### 1.5. How do you calculate a composite SLA?
**Short answer:** You multiply the individual Service Level Agreements of the dependent services together. For example, if App Service is 99.95% and SQL Database is 99.99%, the composite SLA is 0.9995 × 0.9999 = 99.94%.

**Key Points:** Adding components in a serial architecture always lowers the overall SLA.
**Interview tip:** Mention that adding redundancy (parallel architecture) *increases* composite SLA.

### 1.6. Describe the main Azure pricing models.
**Short answer:** 
- **Pay-As-You-Go (Consumption):** Billed per second/minute/hour of usage. Most flexible, most expensive.
- **Reserved Instances (RIs):** Commit to 1 or 3 years for up to 72% discount.
- **Spot Instances:** Purchase unused capacity at deep discounts (up to 90%), but they can be evicted at any time.
- **Azure Hybrid Benefit:** Bring existing on-prem Windows Server/SQL Server licenses to Azure to save costs.

## 2. Identity & Access Management

### 2.1. What is Microsoft Entra ID (formerly Azure AD), and what is a Tenant vs. Directory?
**Short answer:** Entra ID is Microsoft's cloud-based Identity and Access Management (IAM) service. 
- A **Tenant** represents an organization (e.g., `contoso.onmicrosoft.com`).
- A **Directory** is the actual database of users, groups, and apps within that tenant.

**Key Points:** Entra ID is flat (unlike traditional AD DS). You trust a directory with subscriptions to manage access.

### 2.2. How does Azure RBAC work?
**Short answer:** Role-Based Access Control authorizes *who* can do *what* at *which scope*. It has three elements:
1. **Security Principal:** Who (User, Group, Service Principal, Managed Identity).
2. **Role Definition:** What (Owner, Contributor, Reader).
3. **Scope:** Where (Management Group, Subscription, Resource Group, Resource).

**Key Points:** Permissions are additive and inherited downward. An Owner at the Subscription level is an Owner on all Resource Groups inside it.

### 2.3. Explain Managed Identities (System-Assigned vs. User-Assigned).
**Short answer:** Managed Identities provide an automatically managed identity in Entra ID for Azure services to use when authenticating to other Azure services, eliminating the need to manage credentials.
- **System-Assigned:** Tied to the lifecycle of a specific resource. If the resource is deleted, the identity is deleted.
- **User-Assigned:** Created as a standalone resource. Can be assigned to multiple resources and persists independent of them.

**Interview tip:** Always recommend Managed Identities over connection strings/passwords.

### 2.4. What is the difference between a Service Principal and a Managed Identity?
**Short answer:** A Service Principal is an identity created for use with applications, hosted services, and automated tools to access Azure resources (an "application user"). You have to manage its secret/certificate lifecycle. A Managed Identity is a wrapper around a Service Principal where Azure fully manages the credential lifecycle and rotation for you.

### 2.5. What is Entra ID Conditional Access?
**Short answer:** It's the policy engine that brings signals together to make decisions and enforce organizational policies. It works on the "If-Then" logic (e.g., *If* user is outside corp network, *Then* require MFA).

**Key Points:** Common signals include user risk, location, device compliance, and application. It is the core of Zero Trust in Azure.

### 2.6. What is Privileged Identity Management (PIM) and Just-In-Time (JIT) access?
**Short answer:** PIM manages, controls, and monitors access to important resources. It provides time-based and approval-based role activation to mitigate risks of excessive, unnecessary, or misused access rights. JIT (often via PIM for Entra roles, or Defender for Cloud for VM ports) opens access only when needed, for a limited time, and requires justification.

## 3. Compute Services

### 3.1. What is the difference between an Availability Set and a Virtual Machine Scale Set (VMSS)?
**Short answer:** 
- **Availability Set:** Groups VMs to ensure they run on different physical server racks (Fault Domains) and update cycles (Update Domains) within a *single* datacenter.
- **VMSS:** Lets you create and manage a group of identical, load-balanced VMs. It supports auto-scaling (in/out) based on demand or a schedule. VMSS can span across Availability Zones.

### 3.2. Explain App Service Deployment Slots and how they help in scaling.
**Short answer:** Deployment slots are live apps with their own hostnames. You can deploy to a staging slot, test it, and then swap it with the production slot with zero downtime. 
Scaling isn't directly done *by* slots, but slots share the compute resources of the App Service Plan, so you must scale the Plan (Scale Up/Out) to support multiple heavy slots.

### 3.3. What are the key components of an AKS architecture?
**Short answer:** 
- **Control Plane (Managed by Azure):** API server, etcd, scheduler, controller manager. You don't pay for this directly (unless using Uptime SLA).
- **Node Pools (Managed by You):** The Azure VMs (VMSS) running your container workloads (kubelet, container runtime, kube-proxy).

**Key Points:** In AKS, you only manage the worker nodes and deploy your pods to them.

### 3.4. Describe Azure Functions, triggers, bindings, and the "cold start" problem.
**Short answer:** Functions is a serverless compute service.
- **Triggers:** What causes the function to run (e.g., HTTP request, blob upload, timer). A function has exactly one trigger.
- **Bindings:** Declarative ways to connect to data/services (input or output) without writing connection code.
- **Cold Start:** The delay when a function runs after a period of inactivity because the infrastructure needs to spin up the container.

**Interview tip:** Fix cold starts using Premium plan or Dedicated (App Service) plan, or by keeping it warm with a timer.

### 3.5. When should you choose VM vs. App Service vs. AKS vs. Functions?
**Short answer:** 
- **VM:** Need full OS control, legacy apps (Lift & Shift).
- **App Service:** Web apps, REST APIs, managed PaaS with easy scaling and custom domains.
- **AKS:** Complex microservices, need full Kubernetes orchestration, portable containers.
- **Functions:** Event-driven, short-lived tasks, serverless cost model (pay-per-execution).

### 3.6. Container Instances (ACI) vs. Container Apps (ACA) vs. AKS?
**Short answer:** 
- **ACI:** Simplest, fastest way to run a single container. No orchestration.
- **ACA:** Serverless containers optimized for microservices. Built on AKS but abstracts it away. Includes KEDA for event-driven scaling (even to zero) and Dapr.
- **AKS:** Full Kubernetes cluster. Maximum control, maximum complexity.

## 4. Networking

### 4.1. What are VNets, Subnets, and Network Security Groups (NSGs)?
**Short answer:** 
- **VNet:** A private network in Azure.
- **Subnet:** A segmented range of IP addresses within a VNet.
- **NSG:** A firewall containing a list of security rules that allow or deny inbound/outbound network traffic based on source, destination, port, and protocol.

**Key Points:** NSG rules are evaluated by priority (lowest number first, range 100-4096). Once a match is found, evaluation stops.

### 4.2. Compare Azure Load Balancer, App Gateway, Front Door, and Traffic Manager.
**Short answer:** 
- **Load Balancer:** Regional, Layer 4 (TCP/UDP), distributes traffic across VMs.
- **App Gateway:** Regional, Layer 7 (HTTP/HTTPS), provides URL routing, SSL termination, and WAF.
- **Front Door:** Global, Layer 7, global load balancing, CDN, WAF, routing to closest region.
- **Traffic Manager:** Global, DNS-based traffic routing, directs clients to endpoints based on routing methods (latency, priority).

### 4.3. What is VNet Peering and is it transitive?
**Short answer:** VNet Peering connects two VNets seamlessly so traffic routes through the Microsoft backbone (not the internet). 
It is **NOT** transitive. If VNet A peers with B, and B peers with C, VNet A cannot talk to C. You need to explicitly peer A to C, or use a Hub-and-Spoke topology with Azure Firewall/NVA routing.

### 4.4. What is the difference between VPN Gateway and ExpressRoute?
**Short answer:** Both connect on-prem to Azure.
- **VPN Gateway:** Uses the public internet, traffic is encrypted (IPsec/IKE), up to 10 Gbps. Slower, unpredictable latency.
- **ExpressRoute:** Uses a private, dedicated connection via a connectivity provider. Does not go over public internet. Higher security, reliability, speeds (up to 100 Gbps), and lower latency.

### 4.5. Private Endpoint vs. Service Endpoint?
**Short answer:** Both secure access to Azure PaaS services (like Storage/SQL) from a VNet.
- **Service Endpoint:** Routes traffic over the Azure backbone network. The PaaS resource still uses its public IP address, but firewalls can restrict access to just your VNet.
- **Private Endpoint (Private Link):** Brings the PaaS service entirely into your VNet by assigning it a private IP address from your subnet. Much more secure.

### 4.6. Azure Firewall vs. NSG?
**Short answer:** 
- **NSG:** Basic Layer 3/4 filtering attached to subnets or NICs. Free, stateless within flows, basic IP/Port filtering.
- **Azure Firewall:** Managed, stateful firewall service. Inspects Layer 3-7, provides Threat Intelligence, FQDN filtering, SNAT/DNAT, and central policy management across VNets.

## 5. Storage & Databases

### 5.1. Explain Azure Storage redundancy options.
**Short answer:** 
- **LRS (Locally Redundant):** 3 copies within a single datacenter. Cheapest.
- **ZRS (Zone-Redundant):** 3 copies spread across 3 AZs in the same region.
- **GRS (Geo-Redundant):** 3 copies in primary region (LRS), replicated asynchronously to a secondary region (LRS). 
- **RA-GRS (Read-Access GRS):** Same as GRS, but you can read from the secondary region at all times.

### 5.2. What are Azure Blob Access Tiers?
**Short answer:** 
- **Hot:** Optimized for frequently accessed data (high storage cost, low access cost).
- **Cool:** Optimized for data stored ≥30 days, infrequently accessed (lower storage, higher access cost).
- **Cold:** Optimized for data stored ≥90 days.
- **Archive:** Offline tier for data stored ≥180 days. Lowest storage cost, highest retrieval cost, takes hours to retrieve.
**Lifecycle Management:** Automatically moves blobs between tiers based on rules.

### 5.3. Explain Cosmos DB Consistency Levels.
**Short answer:** A spectrum between strict consistency and high performance.
- **Strong:** Always read the latest write. Highest latency, lower availability.
- **Bounded Staleness:** Reads lag writes by a configured time or number of versions.
- **Session:** (Default) Read-your-own-writes guarantee within a session. Best balance.
- **Consistent Prefix:** Updates returned in order, without gaps.
- **Eventual:** Reads will eventually see writes. Lowest latency, highest availability.

### 5.4. Azure SQL Database: DTU vs. vCore pricing models?
**Short answer:** 
- **DTU (Database Transaction Unit):** A bundled measure of Compute, Storage, and I/O. Simple, predefined sizes.
- **vCore:** Allows you to independently scale compute and storage. Recommended because you can use Azure Hybrid Benefit to save on licensing.

### 5.5. When to use Cosmos DB vs. Azure SQL Database?
**Short answer:** 
- **Cosmos DB:** NoSQL, schema-less, highly distributed, massive horizontal scale, microsecond latency required, unstructured/semi-structured data (JSON).
- **Azure SQL Database:** Relational (RDBMS), structured data, complex ACID transactions, existing SQL Server migrations, strong relational integrity needed.

### 5.6. What is a Shared Access Signature (SAS) token?
**Short answer:** A URI that grants restricted access rights to Azure Storage resources (blobs, queues, tables). You can specify permissions (read/write), IP ranges, and validity timeframes without exposing the storage account keys.

## 6. Monitoring & Governance

### 6.1. Describe the Azure Monitor architecture.
**Short answer:** It collects data from multiple sources into a common data platform. 
- **Data Types:** Metrics (numerical time-series data, near real-time) and Logs (events/telemetry organized into records, queried later).
- **Features:** Dashboards, Alerts, Log Analytics, Application Insights.

### 6.2. What is Log Analytics and KQL?
**Short answer:** Log Analytics is a workspace in Azure Monitor where log data is stored. KQL (Kusto Query Language) is the read-only query language used to analyze, filter, aggregate, and visualize data stored in Log Analytics.

### 6.3. What is Application Insights?
**Short answer:** An Application Performance Management (APM) feature of Azure Monitor. It instruments web apps to monitor live performance, track request rates, response times, failure rates, and dependencies. It generates application maps to visualize app topology.

### 6.4. What is Azure Policy?
**Short answer:** Azure Policy enforces rules over resources to ensure compliance with corporate standards and SLAs. E.g., requiring specific tags, restricting allowed regions, or denying the creation of public IP addresses. 
**Initiative:** A collection of policy definitions grouped together towards a specific goal (e.g., ISO 27001 compliance).

### 6.5. How do Resource Locks work?
**Short answer:** They prevent accidental deletion or modification of resources.
- **CanNotDelete:** Authorized users can read/modify, but cannot delete.
- **ReadOnly:** Authorized users can read, but cannot modify or delete.
Locks override any RBAC permissions (even Owner cannot delete a locked resource without removing the lock first).

## 7. Security & Reliability

### 7.1. What does Azure Key Vault store and manage?
**Short answer:** 
- **Secrets:** Passwords, connection strings, API keys.
- **Keys:** Cryptographic keys for data encryption (e.g., TDE for SQL, Storage Account encryption).
- **Certificates:** Provision, manage, and deploy SSL/TLS certificates.

### 7.2. What is Defender for Cloud Secure Score?
**Short answer:** A metric that assesses the security posture of your Azure resources. It gives a percentage score and provides a prioritized list of security recommendations (e.g., "Enable MFA", "Close management ports") to improve the score and reduce risk.

### 7.3. How do you implement High Availability vs Disaster Recovery in Azure?
**Short answer:** 
- **HA:** Ensures the app remains available during localized hardware failures. Uses Availability Sets, Availability Zones, and Load Balancers.
- **DR:** Recovers the app after a catastrophic failure (e.g., region outage). Uses Azure Site Recovery (replicating VMs to another region), geo-redundant storage, and Azure Backup.

### 7.4. Explain RPO and RTO.
**Short answer:** 
- **RPO (Recovery Point Objective):** Maximum acceptable data loss (e.g., 1 hour of data). Dictates backup frequency.
- **RTO (Recovery Time Objective):** Maximum acceptable downtime to restore the service (e.g., 4 hours to be back online). Dictates DR architecture.

### 7.5. Explain the Zero Trust model.
**Short answer:** "Never trust, always verify." Security model assuming breach. Principles: Verify explicitly (auth/MFA every time), Use least privileged access (JIT, LAPS, RBAC), and Assume breach (segment networks, encrypt end-to-end).

## 8. Advanced Services & Architecture

### 8.1. Difference between Service Bus, Event Grid, and Event Hubs?
**Short answer:** 
- **Service Bus:** High-value enterprise message brokering (queues/topics). Handles order, transactions, and state. Pull model. "Transfer money."
- **Event Grid:** Event routing service. Reacts to status changes. Push model. "A file was uploaded."
- **Event Hubs:** Big Data streaming pipeline. Ingests millions of events per second (telemetry, logs). "IoT sensor readings."

### 8.2. Logic Apps vs. Azure Functions?
**Short answer:** Both are serverless compute.
- **Logic Apps:** Visual designer, declarative. Better for orchestrating workflows, integrating SaaS (hundreds of built-in connectors). No coding required.
- **Functions:** Code-first, imperative. Better for custom logic, complex algorithms, and developers.

### 8.3. What is API Management (APIM)?
**Short answer:** A gateway sitting between clients and backend APIs. It provides routing, security (OAuth, IP filtering), throttling/rate limiting, caching, and analytics. It transforms policies (e.g., XML to JSON) and abstracts the backend architecture.

### 8.4. What are the 5 pillars of the Azure Well-Architected Framework?
**Short answer:** 
1. **Reliability:** Ability to recover from failures (HA/DR).
2. **Security:** Protecting data and systems (Zero Trust).
3. **Cost Optimization:** Managing spend (RIs, right-sizing).
4. **Operational Excellence:** Processes to keep systems running (Monitoring, IaC, CI/CD).
5. **Performance Efficiency:** Adapting to load changes (Auto-scaling).

### 8.5. What is Azure Arc?
**Short answer:** A bridge extending Azure management and services to anywhere. It lets you manage on-prem servers, multi-cloud VMs (AWS/GCP), and Kubernetes clusters directly from the Azure portal using ARM, applying Azure Policies and Defender to them.

## 9. Scenario-Based Questions

### 9.1. 🎯 Design a multi-region HA web application on Azure.
**Short answer:** 
- Route traffic using **Azure Front Door**.
- Deploy backend to **App Service** (or AKS) in Primary (East US) and Secondary (West US) regions.
- Database: **Azure SQL with Active Geo-Replication** or Cosmos DB (multi-region writes).
- Storage: **RA-GRS Blob Storage**.
- Front Door routes to primary; if primary fails, health probes detect it and Front Door auto-fails over to secondary.

### 9.2. 🎯 An Azure web app is responding slowly. How do you troubleshoot?
**Short answer:** 
1. Check **Application Insights** application map for dependencies (is the DB slow?).
2. Look at App Service metrics (CPU/Memory).
3. Review App Insights failures and performance tabs for slow requests.
4. Run the **Diagnose and Solve Problems** blade in the portal to check for platform issues.
5. Check if the App Service Plan is hitting limits; scale up/out if necessary.

### 9.3. 🎯 Secure access to Azure SQL from an App Service without using passwords.
**Short answer:** 
1. Enable a **System-Assigned Managed Identity** on the App Service.
2. In Azure SQL, create a contained user representing that Managed Identity.
3. Grant the required SQL permissions (e.g., `db_datareader`, `db_datawriter`) to that identity.
4. The App Service authenticates via Entra ID tokens instead of connection strings.

### 9.4. 🎯 Storage costs are continuously rising. How do you optimize?
**Short answer:** 
1. Enable **Lifecycle Management policies** to move older blobs to Cool/Archive tiers.
2. Use **Azure Advisor** to find unattached/orphaned managed disks and delete them.
3. Change redundancy if over-provisioned (e.g., downgrade GRS to LRS for non-critical data).
4. Review access patterns; if data in Cool is read constantly, move it to Hot (to save on access transaction costs).

### 9.5. 🎯 Implement DR for a critical legacy VM workload.
**Short answer:** Use **Azure Site Recovery (ASR)**. Install the ASR mobility service on the VM. It will replicate disk writes continuously to a secondary Azure region. Define a recovery plan. During a disaster, trigger a failover, which spins up the VM in the secondary region from the replicated disks (low RTO, low RPO).

### 9.6. 🎯 Network connectivity issue between two VNets, how to troubleshoot?
**Short answer:** 
1. Ensure **VNet Peering** is successfully established and shows "Connected" on both sides.
2. Check **NSGs** on the source and destination subnets to ensure traffic isn't blocked.
3. Use **Network Watcher > IP Flow Verify** to test packet flow between the source and destination VMs.
4. Check UDRs (User Defined Routes) to ensure traffic isn't being blackholed by an NVA or Azure Firewall misconfiguration.

## 10. Rapid-Fire Questions

- **Q: Port for RDP?** A: 3389.
- **Q: Port for SSH?** A: 22.
- **Q: Default NSG rule priority range?** A: 100 to 4096.
- **Q: Can you move resources between resource groups?** A: Yes, most resources support it.
- **Q: Can a VNet span multiple regions?** A: No, VNets are bound to a single region.
- **Q: Can an App Service use a custom domain?** A: Yes (requires Basic tier or above).
- **Q: What stores container images in Azure?** A: Azure Container Registry (ACR).
- **Q: Tool to map on-prem VMs for cloud migration?** A: Azure Migrate.
- **Q: What SLA does a single VM with premium SSD have?** A: 99.9%.
- **Q: What is the maximum number of tags per resource?** A: 50.
- **Q: Protocol used by Azure File Shares?** A: SMB (and NFS).
- **Q: Maximum capacity of a single Blob container?** A: Limited only by the storage account limit.
- **Q: Default Cosmos DB API?** A: NoSQL (Core).
- **Q: What service provides secrets management?** A: Azure Key Vault.
- **Q: How to connect on-prem AD to Entra ID?** A: Entra Connect (Azure AD Connect).
- **Q: Difference between standard and premium storage?** A: Standard uses HDDs/Standard SSDs; Premium uses high-performance SSDs.
- **Q: What is Azure Bastion used for?** A: Secure RDP/SSH access from the portal without assigning public IPs to VMs.
- **Q: Service to protect against high-volume network attacks?** A: Azure DDoS Protection.
- **Q: What defines IaC in Azure?** A: ARM Templates or Bicep.
- **Q: Can you encrypt an existing unencrypted Azure VM disk?** A: Yes, using Azure Disk Encryption.
- **Q: How to restrict which IPs can hit an Azure SQL DB?** A: Azure SQL Server Firewall rules.
- **Q: Difference between Azure AD Free and Premium P1/P2?** A: Premium unlocks Conditional Access, PIM, Identity Protection.
- **Q: What is Azure Front Door?** A: Global Layer 7 load balancer and CDN.
- **Q: Best tier for data rarely accessed but needed immediately?** A: Cool tier.
- **Q: Best tier for regulatory compliance data kept for years?** A: Archive tier.
- **Q: How do you track who deleted a resource?** A: Azure Monitor Activity Log (kept for 90 days).
- **Q: What is KQL?** A: Kusto Query Language, used to query Log Analytics.
- **Q: Service for event-driven serverless code?** A: Azure Functions.
- **Q: Service for orchestrating logic without code?** A: Azure Logic Apps.
- **Q: How to force all traffic through a firewall appliance?** A: Use a Route Table with a User Defined Route (UDR).
- **Q: Can you peer VNets across different Azure AD Tenants?** A: Yes.
- **Q: What is the purpose of Azure Advisor?** A: Provides recommendations for Cost, Security, Reliability, Op Excellence, Performance.
- **Q: Tool to calculate costs before migrating?** A: Azure Pricing Calculator.
- **Q: Tool to monitor current spending?** A: Azure Cost Management.
- **Q: What is an Ephemeral OS disk?** A: Disk created on local VM storage, reset on reboot. Cheaper, faster, stateless.
- **Q: Does stopping a VM stop compute billing?** A: Yes, if the state is "Stopped (Deallocated)".
- **Q: Do you pay for data transfer out of Azure?** A: Yes (Egress). Data Ingress is free.
- **Q: What is Azure Service Fabric?** A: Microsoft's legacy orchestrator for microservices (what powers Cosmos DB/SQL DB under the hood).
- **Q: Can multiple VMs share the same managed disk?** A: Yes, using Azure Shared Disks.
