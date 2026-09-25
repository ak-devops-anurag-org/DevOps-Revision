# Azure Security & Reliability - Interview Revision Notes

## 1. Secrets and Encryption Management

### ⭐ MUST KNOW: What is Azure Key Vault and how does it secure applications?
**Short Answer:** Azure Key Vault is a centralized cloud service for securely storing and managing secrets, encryption keys, and certificates, eliminating the need to hardcode credentials in source code.

**Key Points:**
- **Capabilities:** Stores secrets (passwords/strings), keys (cryptographic keys), and certificates.
- **Security:** Hardware Security Modules (HSMs) are available in Premium tier.
- **Resilience:** Soft delete (retains deleted vaults/objects for 7-90 days) and Purge Protection (prevents permanent deletion until retention period expires).
- **Access Control:** Vault access policy (legacy) vs Azure RBAC (recommended).

**Example:**
```bash
# Create Key Vault and set a secret
az keyvault create --name myKeyVault --resource-group myRG --location eastus
az keyvault secret set --vault-name myKeyVault --name "db-password" --value "Super$ecret!"
```

**Interview Tip:** Always recommend Azure RBAC for Key Vault authorization as it integrates natively with Azure AD (Entra ID) and provides granular, centralized access management.

### 🟠 IMPORTANT: Explain encryption at rest and in transit in Azure.
**Short Answer:** Encryption in Azure ensures data privacy when stored (at rest) and while moving (in transit).

**Key Points:**
- **At Rest (Storage):** Server-Side Encryption (SSE) is enabled by default for all Azure Storage using Platform-Managed Keys (PMK). You can optionally use Customer-Managed Keys (CMK) via Key Vault.
- **At Rest (VMs):** Azure Disk Encryption (ADE) uses BitLocker (Windows) or DM-Crypt (Linux) for OS and data disks.
- **In Transit:** Traffic between Azure datacenters is MACsec encrypted. External traffic uses TLS (Transport Layer Security) 1.2+.

**Interview Tip:** Distinguish between SSE (storage level) and ADE (OS level). ADE requires Key Vault to store disk encryption keys.

## 2. Cloud Security Posture and Threat Protection

### ⭐ MUST KNOW: What is Microsoft Defender for Cloud?
**Short Answer:** A Cloud Security Posture Management (CSPM) and Cloud Workload Protection Platform (CWPP) that provides unified security management and advanced threat protection across hybrid and multi-cloud environments.

**Key Points:**
- **Secure Score:** A KPI evaluating your security posture; higher score means lower risk.
- **Recommendations:** Actionable steps to improve the Secure Score based on Azure Security Benchmark.
- **Workload Protection:** Advanced threat detection for VMs, Kubernetes, SQL, and Storage.
- **JIT VM Access:** Opens RDP/SSH ports only when needed for a limited time to block brute-force attacks.

**Interview Tip:** Mention that Defender for Cloud isn't just for Azure—it protects AWS, GCP, and on-premises resources via Azure Arc.

### 🟠 IMPORTANT: Azure Sentinel vs Microsoft Defender for Cloud?
**Short Answer:** Defender for Cloud is for posture management and workload protection (protects resources), while Sentinel is a SIEM/SOAR solution (analyzes logs across the enterprise).

**Key Points:**
- **Microsoft Sentinel:** Security Information and Event Management (SIEM) aggregates logs. Security Orchestration, Automation, and Response (SOAR) automates incident responses via Logic Apps.
- Defender feeds alerts *into* Sentinel.

> [!NOTE]
> For identity security, refer to Entra ID features (MFA, Conditional Access, Identity Protection) in `02_identity_access_management.md`.

## 3. High Availability (HA) and Disaster Recovery (DR)

### ⭐ MUST KNOW: How do Availability Sets, Availability Zones, and Region Pairs differ?
**Short Answer:** They provide progressive levels of resilience against hardware, datacenter, and regional failures.

| Feature | Scope of Protection | SLA (VM) | Description |
|---|---|---|---|
| **Availability Set** | Rack-level (hardware failure) | 99.95% | Groups VMs across distinct Update Domains (UD) and Fault Domains (FD) within the *same* datacenter. |
| **Availability Zone** | Datacenter-level (facility failure) | 99.99% | Physically separate datacenters within the *same* region with independent power, cooling, and network. |
| **Region Pair** | Region-level (natural disaster) | Varies | Two regions hundreds of miles apart (e.g., East US & West US). Azure serializes updates across pairs. |

**Interview Tip:** If asked about SLA, know the numbers: single VM (Premium SSD) = 99.9%, Av Set = 99.95%, Av Zone = 99.99%.

### 🟠 IMPORTANT: RTO vs RPO
**Short Answer:** RTO (Recovery Time Objective) is about downtime, and RPO (Recovery Point Objective) is about data loss.

| Metric | Definition | Business Question |
|---|---|---|
| **RTO** | Max acceptable time the application can be offline. | "How long can we afford to be down?" |
| **RPO** | Max acceptable amount of data loss measured in time. | "How much data can we afford to lose?" |

**Interview Tip:** Low RTO/RPO means higher cost (active-active setups). High RTO/RPO means lower cost (backup/restore).

### HA / DR Architecture Diagram
```ascii
      Traffic Manager / Front Door
             |
      -----------------------
      |                     |
[Primary Region]      [Secondary Region (Paired)]
  - Av Zone 1           - Av Zone 1
    (Web VM)              (Web VM)
  - Av Zone 2           - Av Zone 2
    (Web VM)              (Web VM)
      |                     |
[SQL DB (Active)] <---> [SQL DB (Passive/Replica)]
```

## 4. Backup and Site Recovery

### 🟠 IMPORTANT: Azure Backup vs Azure Site Recovery (ASR)
**Short Answer:** Backup is for data retention and recovery (RPO focused), while ASR is for application replication and failover (RTO focused).

**Key Points:**
- **Azure Backup:** Uses Recovery Services vaults or Backup vaults. Defines backup policies (schedule, retention). 
- **ASR:** Continuously replicates VMs to a secondary region.
- **Failover / Failback:** ASR allows failing over to the secondary region during a disaster, and failing back to the primary once resolved.

**Example:**
```bash
# Trigger an on-demand backup
az backup protection backup-now --resource-group myRG \
  --vault-name myRecoveryVault \
  --container-name myVM \
  --item-name myVM \
  --retain-until 14-04-2026
```

## 5. Network Security & Architecture Concepts

### 🟠 IMPORTANT: Explain core Azure Network Security components.
*(Note: See `04_networking.md` for deep dive)*
**Short Answer:** Azure provides layered network security from L3 to L7.

**Key Points:**
- **NSG (Network Security Group):** L3/L4 stateful firewall rules applied to NICs or Subnets.
- **Azure Firewall:** Managed, stateful L3-L7 firewall with threat intelligence.
- **WAF (Web Application Firewall):** L7 protection against OWASP top 10 (SQLi, XSS) attached to App Gateway or Front Door.
- **Private Link:** Access PaaS (SQL, Storage) securely via a private IP within your VNet, bypassing the public internet.
- **DDoS Protection:** Basic (free, platform-level) vs Standard (paid, customized tuning, telemetry, SLA guarantees).

### ⭐ MUST KNOW: What is the Zero Trust model?
**Short Answer:** A security framework based on the principle "never trust, always verify."

**Key Points:**
- **Verify explicitly:** Always authenticate and authorize based on all available data points (identity, location, device health).
- **Use least privileged access:** Just-In-Time (JIT) and Just-Enough-Access (JEA), risk-based adaptive policies.
- **Assume breach:** Minimize blast radius, segment networks, use end-to-end encryption.

## 6. Scenarios 🎯

### 🎯 SCENARIO 1: DR Planning
**Question:** Your company is deploying a mission-critical web app. They require an RTO of 5 minutes and RPO of 1 minute. How do you design this?
**Answer:** Deploy an Active-Active or Active-Passive (Hot) architecture using Azure Front Door for global traffic routing. Place web tiers in multiple Azure Regions (Region Pairs). Use Azure SQL Database with Active Geo-Replication (supports RPO < 5s) or Cosmos DB (multi-master). ASR and Backup alone won't meet a 5-minute RTO.

### 🎯 SCENARIO 2: Secure PaaS Connectivity
**Question:** A security audit flagged that your Azure Storage Account and Azure SQL Database are accessible over the internet. How do you fix this without changing the application logic?
**Answer:** Disable public network access on both services. Deploy Azure Private Endpoints (Private Link) into the application's VNet. The application will resolve the PaaS services to private IPs via Azure Private DNS zones, ensuring traffic never traverses the public internet.

### 🎯 SCENARIO 3: Ransomware Response
**Question:** An admin accidentally deleted several critical Key Vault secrets, and a ransomware attack encrypted your VM disks. How do you recover?
**Answer:** For Key Vault, leverage the "Soft Delete" feature to immediately undelete the secrets. For the VMs, use Azure Backup (Recovery Services Vault). Because Azure Backup stores backups in an isolated vault with soft-delete enabled by default, the ransomware cannot encrypt or permanently delete the backups. Restore the VMs to a point-in-time before the attack.

⚠️ **INTERVIEW TRAP:** Don't say "just turn on ASR for ransomware". ASR replicates changes instantly; it would replicate the encrypted disks to the DR site. You *must* use Azure Backup for point-in-time recovery against ransomware.
