# Azure Storage & Database Services - Interview Revision Notes

## Azure Storage Account Fundamentals

### Q: What are the primary types of Azure Storage Accounts and when do you use them?
**Short answer:** General-purpose V2 (StorageV2) is the standard and recommended for most scenarios, supporting blobs, files, queues, and tables. Other types include Premium Block Blobs (high performance), Premium File Shares, and Premium Page Blobs.

**Key Points:**
- **StorageV2:** Default choice, supports all storage types and features like lifecycle management.
- **BlobStorage:** Legacy, use StorageV2 instead.
- **Premium types:** Backed by SSDs for low latency/high throughput.

**Example:** Use StorageV2 for a standard web app backend. Use Premium Block Blobs for high-frequency transactional data.

**Interview tip:** ⭐ **MUST KNOW** Always recommend StorageV2 unless there's a specific need for premium performance.

### Q: Explain the different storage redundancy options.
**Short answer:** Azure offers redundancy to protect against hardware failures or regional disasters. Options range from local data center replication (LRS) to cross-region with read access (RA-GRS/RA-GZRS).

**Comparison Table: Storage Redundancy**

| Option | Replicas | Scope | Read Access in Sec. Region? | Best For |
|---|---|---|---|---|
| **LRS** (Locally Redundant) | 3 | Single data center | No | Low cost, non-critical data |
| **ZRS** (Zone Redundant) | 3 | Across 3 AZs in primary region | No | High availability in one region |
| **GRS** (Geo-Redundant) | 6 | 3 in primary, 3 in secondary region | No | Disaster recovery |
| **RA-GRS** (Read-Access GRS) | 6 | 3 in primary, 3 in secondary region | Yes | DR + read scaling/reporting |
| **GZRS / RA-GZRS** | 6 | 3 across AZs in primary, 3 in secondary | No / Yes | Maximum availability and DR |

> [!WARNING] ⚠️ **INTERVIEW TRAP**
> GRS only allows reading from the secondary region *after* a failover is initiated by Microsoft or the customer. To read continuously, you need RA-GRS.

## Azure Blob Storage & Data Lake

### Q: What are the differences between Block, Append, and Page blobs?
**Short answer:** Block blobs are for general text/binary data, Append blobs are for logging, and Page blobs are optimized for random read/write operations.

**Key Points:**
- **Block Blobs:** Uploaded in blocks. Used for images, documents, backups.
- **Append Blobs:** Optimized for append operations. Ideal for logging from VMs.
- **Page Blobs:** 512-byte pages. Used as the underlying storage for Azure Virtual Machine disks (IaaS).

### Q: Compare the Blob Storage Access Tiers.
**Short answer:** Access tiers optimize storage costs based on data access patterns. Moving data from Hot to Archive decreases storage cost but increases access cost and latency.

**Comparison Table: Blob Access Tiers**

| Tier | Storage Cost | Access Cost | Retrieval Latency | Best For |
|---|---|---|---|---|
| **Hot** | Highest | Lowest | Milliseconds | Active data, web assets |
| **Cool** | Lower | Higher | Milliseconds | Short-term backup (>= 30 days) |
| **Cold** | Low | High | Milliseconds | Infrequently accessed (>= 90 days) |
| **Archive** | Lowest | Highest | Hours (Rehydration) | Long-term compliance (>= 180 days) |

**Interview tip:** 🟠 **IMPORTANT** Mention Lifecycle Management policies to automatically transition blobs between tiers (e.g., Hot -> Cool after 30 days, Cool -> Archive after 90 days).

### Q: What is Azure Data Lake Storage (ADLS) Gen2?
**Short answer:** ADLS Gen2 is Blob Storage with a hierarchical namespace (HNS) enabled. It combines the scalability of Blob Storage with Hadoop Distributed File System (HDFS) semantics for big data analytics.

## Files, Queues, and Disks

### Q: When would you use Azure Files vs Blob Storage?
**Short answer:** Use Azure Files for standard file sharing (SMB/NFS) accessible like a mounted drive from VMs or on-prem. Use Blob Storage for object storage accessed via REST APIs.

**Key Points:**
- **Azure File Sync:** Syncs on-prem Windows Server file shares to Azure Files. Replaces on-prem file servers with cloud tiering.

### Q: Azure Queue Storage vs Service Bus Queues?
**Short answer:** Queue Storage is a simple, REST-based message queue for large message volumes up to 64KB. Service Bus is an enterprise message broker with advanced features like pub/sub, order guarantees (FIFO), and transactions.

**Comparison Table: Queues vs Service Bus**

| Feature | Queue Storage | Service Bus Queues |
|---|---|---|
| Message Size | Up to 64 KB | Up to 256 KB (100MB for Premium) |
| Ordering Guarantee | No (Best effort) | Yes (FIFO with Sessions) |
| Delivery Guarantee | At-Least-Once | At-Least-Once, At-Most-Once |
| Pub/Sub | No | Yes (Topics/Subscriptions) |

### Q: What are the differences between Managed and Unmanaged Disks?
**Short answer:** Always use Managed Disks. Azure handles the underlying storage account creation and management. Unmanaged disks require you to manually manage storage accounts and IOPS limits per account.

**Disk Types:** Ultra Disk (sub-millisecond latency), Premium SSD v2/v1 (production workloads), Standard SSD (dev/test), Standard HDD (backups/non-critical).

## Azure Cosmos DB

### Q: What is Azure Cosmos DB and what makes it unique?
**Short answer:** Cosmos DB is Azure's fully managed, globally distributed, multi-model NoSQL database. It offers guaranteed single-digit millisecond latency and SLAs on throughput, latency, availability, and consistency.

**Key Points:**
- **Multi-model APIs:** SQL (Core), MongoDB, Cassandra, Gremlin (Graph), Table.
- **RU/s (Request Units):** The currency for throughput. 1 RU = read of a 1KB document.
- **Global Distribution:** Active-active multi-region writes.

### Q: Explain Cosmos DB Consistency Levels.
**Short answer:** Cosmos DB offers five well-defined consistency levels, allowing developers to trade off between read latency, availability, and data consistency.

**Comparison Table: Cosmos DB Consistency**

| Level | Description | Use Case |
|---|---|---|
| **Strong** | Reads guaranteed to return the most recent write. Highest latency. | Financial transactions. |
| **Bounded Staleness** | Reads lag writes by a configured time or version count. | Stock tickers, scoreboards. |
| **Session** | (Default) Guarantees read-your-own-writes within a specific session. | E-commerce shopping carts, user profiles. |
| **Consistent Prefix** | Reads never see out-of-order writes. | Social media feeds. |
| **Eventual** | Lowest latency, highest availability. No ordering guarantee. | Product reviews, likes/retweets. |

**Interview tip:** ⭐ **MUST KNOW** Session consistency is the default and the most common answer in interviews.

### 🎯 SCENARIO: Cosmos DB Partitioning
**Question:** You are designing a Cosmos DB for an IoT application storing millions of sensor readings daily. How do you choose a partition key?
**Answer:** I need a partition key with a high cardinality that distributes requests and storage evenly (to avoid "hot partitions").
*Bad choice:* `SensorType` (low cardinality) or `Date` (all writes go to one partition on that day).
*Good choice:* `SensorId` or a synthetic key like `SensorId_Date` if querying patterns require it. Cosmos DB physical partitions have a 50GB limit and a 10K RU/s limit.

## Relational & Cache Services

### Q: Azure SQL Database: DTU vs vCore models?
**Short answer:** DTU (Data Transaction Unit) is a bundled measure of compute, storage, and I/O (simple, legacy). vCore allows independent scaling of compute and storage (flexible, modern, supports Azure Hybrid Benefit).

**Key Points:**
- **Elastic Pools:** Share a pool of resources (eDTUs or vCores) among multiple databases with unpredictable usage patterns.
- **Serverless:** Auto-scales compute based on workload and pauses during inactivity (billed per second).
- **Geo-Replication / Auto-Failover Groups:** For DR and read-scale.

### Q: What is Azure Database Flexible Server (MySQL/PostgreSQL)?
**Short answer:** Flexible server is the modern, recommended deployment model for open-source databases on Azure. It provides better control over server parameters, high availability (zone-redundant), and cost optimization (burstable compute) compared to the legacy Single Server.

### Q: When should you use Azure Cache for Redis?
**Short answer:** Use it as an in-memory data store to improve application performance by caching frequently accessed data (e.g., database query results, session state, web page output).

## Storage Security Fundamentals

*(Note: See `07_security_reliability.md` for broader networking and identity security)*

### Q: How do you secure data in an Azure Storage Account?
**Short answer:** Secure access using Entra ID (RBAC) where possible, SAS tokens for temporary delegated access, and Private Endpoints for network isolation.

**Key Points:**
- **Access Keys (Account Keys):** Root passwords. Avoid sharing. Rotate regularly.
- **SAS Tokens (Shared Access Signatures):** URI that grants restricted access rights to Azure Storage resources (time-bound, specific permissions).
- **RBAC (Role-Based Access Control):** Entra ID integration. Recommended over access keys.
- **Encryption:** Storage Service Encryption (SSE) is on by default for data at rest.
- **Network:** Disable public access. Use Virtual Network Service Endpoints or Private Endpoints (Azure Private Link).

### 🎯 SCENARIO: Delegated Access
**Question:** A third-party vendor needs to upload logs to your Blob Storage container daily for 30 days, but they should not be able to read or delete existing files. How do you implement this?
**Answer:** I would generate a Service SAS (Shared Access Signature) token at the container level. I will set the permissions to 'Write' only (no Read/Delete) and set the expiry time to 30 days from now. Better yet, I would create a Stored Access Policy on the container and associate the SAS with it, allowing me to revoke the access before the 30 days if needed.

## Essential CLI Commands

```bash
# Create a standard general-purpose v2 storage account
az storage account create \
  --name mystorageacct \
  --resource-group myRG \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Get the storage account connection string
az storage account show-connection-string \
  --name mystorageacct \
  --resource-group myRG

# Create a Cosmos DB account with Session consistency
az cosmosdb create \
  --name mycosmosdb \
  --resource-group myRG \
  --default-consistency-level Session
```
