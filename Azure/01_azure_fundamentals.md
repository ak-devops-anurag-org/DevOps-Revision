# Azure Fundamentals - Interview Revision Notes

## Cloud Computing Models

### What are the main cloud service models? Provide Azure examples.
**Short answer:** Cloud computing models determine the level of shared responsibility between you and the cloud provider. 
- **IaaS (Infrastructure as a Service):** You manage OS, runtime, and apps. (e.g., Azure Virtual Machines)
- **PaaS (Platform as a Service):** You manage apps and data. (e.g., Azure App Service, Azure SQL Database)
- **SaaS (Software as a Service):** You manage only data and access. (e.g., Microsoft 365, Azure Active Directory / Entra ID)

> [!NOTE] 
> Shared Responsibility Model is often tested here: "Who patches the OS in PaaS?" (Answer: Microsoft).

**Comparison Table: IaaS vs PaaS vs SaaS**

| Feature | IaaS (Azure VM) | PaaS (Azure App Service) | SaaS (Microsoft 365) |
| :--- | :--- | :--- | :--- |
| **Control** | Highest | Medium | Lowest |
| **Management Effort** | High (OS patching, updates) | Low (Focus on code/data) | Minimal (Focus on users) |
| **Use Case** | Lift-and-shift, legacy apps | Custom app development | Ready-to-use software |
| **You Manage** | OS, App, Data, Runtime | App, Data | Data, Access |

## Global Infrastructure

### ⭐ What is the difference between an Azure Region, an Availability Zone (AZ), and a Region Pair?
**Short answer:** 
- **Region:** A geographical area containing one or more datacenters.
- **Availability Zone (AZ):** Physically separate datacenters within a single region with independent power, cooling, and networking. Protects against datacenter-level failures.
- **Region Pair:** Two regions within the same geography, separated by at least 300 miles. Used for disaster recovery (DR) and sequential updates.

**Key Points:**
- Not all regions support AZs.
- Azure always updates region pairs one at a time to prevent simultaneous outages.

**Interview tip:** Always mention "fault tolerance" for AZs and "disaster recovery" for Region Pairs.

## Azure Resource Hierarchy

### ⭐ How does Azure organize resources logically?
**Short answer:** Azure uses a 4-level hierarchy to organize resources and manage access/billing.

**ASCII Diagram: Azure Hierarchy**
```text
[Management Group] (e.g., "Contoso Corp" - Policy/Access at scale)
       |
       +--> [Management Group] (e.g., "IT Department")
       |           |
       |           +--> [Subscription] (e.g., "Production Sub" - Billing/Quotas)
       |                      |
       |                      +--> [Resource Group] (e.g., "Web-App-RG" - Lifecycle grouping)
       |                                 |
       |                                 +--> [Resource] (e.g., App Service)
       |                                 +--> [Resource] (e.g., SQL DB)
       |
       +--> [Subscription] (e.g., "Dev/Test Sub")
```

**Key Points:**
- **Management Groups:** Manage access, policies, and compliance across multiple subscriptions.
- **Subscriptions:** Logical boundary for billing and resource limits (quotas).
- **Resource Groups (RGs):** Logical container for resources that share the same lifecycle. Deleting an RG deletes all resources inside it.

## Azure Resource Manager (ARM)

### 🟠 What is Azure Resource Manager (ARM) and how does it work?
**Short answer:** ARM is the deployment and management service for Azure. It provides a consistent management layer whether you use the Portal, CLI, PowerShell, or REST APIs.

**Key Points:**
- Authenticates and authorizes all requests.
- Enables declarative deployments (IaC) and Role-Based Access Control (RBAC).

## Pricing and SLAs

### What are the main Azure pricing models?
**Short answer:** 
- **Pay-as-you-go:** Pay only for what you consume (OpEx). Best for unpredictable workloads.
- **Reserved Instances (RIs):** Commit to 1 or 3 years for significant discounts (up to 72%). Best for predictable, long-running workloads.
- **Spot Instances:** Purchase unused compute capacity at deep discounts. Can be evicted at any time. Best for batch processing or non-critical dev/test.

### ⚠️ How do Composite SLAs work in Azure?
**Short answer:** When combining multiple services, the overall Service Level Agreement (SLA) is calculated by multiplying the individual SLAs. The result is always lower than the individual SLAs.

**Example:**
- Web App (99.95%) + SQL DB (99.99%)
- Composite SLA = 0.9995 * 0.9999 = 99.94%

**Interview Trap:** Don't say "it takes the lowest SLA" or "it takes the average". It's the product of the probabilities.

## Management Tools and IaC

### When should you use Azure CLI, PowerShell, or Cloud Shell?
**Short answer:** 
- **Azure CLI:** Bash-style, cross-platform command-line tool. Best for Linux users and Bash scripts.
- **Azure PowerShell:** Object-oriented cmdlets. Best for Windows admins familiar with PowerShell.
- **Azure Cloud Shell:** Browser-based, authenticated, and pre-configured shell (Bash or PS) with tools already installed. Best for quick tasks from any machine.

**Relevant Azure CLI commands:**
```bash
az login                            # Authenticate
az group create -l eastus -n myRG   # Create Resource Group
az group delete -n myRG             # Delete RG and all contents
```

### 🟠 Compare ARM Templates, Bicep, and Terraform.
**Short answer:** 
- **ARM Templates:** Native Azure IaC using verbose JSON. Hard to read/author manually.
- **Bicep:** Native Azure domain-specific language (DSL). Compiles to ARM JSON. Clean syntax, state is managed by Azure.
- **Terraform:** Cloud-agnostic (multi-cloud) IaC using HCL. Requires managing a local or remote state file.

## Organization & Architecture

### What are Resource Tags and why are they important?
**Short answer:** Tags are key-value pairs assigned to resources. 
**Key Points:**
- Used for billing categorization (e.g., CostCenter: 12345).
- Used for environmental grouping (e.g., Env: Prod).
- Can be enforced using Azure Policy.

### 🟠 What is an Azure Landing Zone?
**Short answer:** An architectural blueprint for setting up a scalable, secure, and well-governed Azure environment. It pre-configures networking, identity, security, and governance (Management Groups, Policies) before deploying application workloads.

### Azure Control v/s Data Plane Permission 

#### Control Plane Permissions
- Purpose: Used to **create, update, delete**, and configure Azure resources (e.g., creating a storage account or setting up firewall rules).
- Governed by: Azure Resource Manager (ARM) via management.azure.com.
- Typical Roles: Subscription Owner, Contributor.
- Example: An administrator with the Owner role can delete a storage account or change its network settings, but cannot automatically view the files stored inside it.

#### Data Plane Permissions
- Purpose: Used to **interact with the actual data or data stream inside the resource** (e.g., reading/writing blobs, querying a database, or using a cryptographic key).
- Governed by: The individual resource provider or service-specific mechanisms (like Azure RBAC data actions or access keys).
- Typical Roles: Storage Blob Data Reader, Key Vault Secrets User.
- Example: An application reading files from a container uses Storage Blob Data Reader permissions without needing any management rights over the storage account itself.

## Scenarios

### 🎯 SCENARIO: Your company needs to deploy a batch processing job that runs for 4 hours every night. It can be interrupted and resumed without data loss. Which compute pricing model should you choose?
**Answer:** Azure Spot VMs. Since the job can tolerate interruptions and doesn't have strict uptime requirements, Spot instances will provide the most significant cost savings compared to Pay-as-you-go.

### 🎯 SCENARIO: A developer accidentally deleted a Resource Group containing a production database and web app. How could this have been prevented?
**Answer:** By applying a Resource Lock at the Resource Group or Resource level. 
**Key Points:**
- `CanNotDelete` lock prevents accidental deletion.
- `ReadOnly` lock prevents both deletion and modification.
- RBAC is not enough if the developer had Owner/Contributor rights; a lock supersedes RBAC for deletion.
