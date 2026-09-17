# Storage — AWS Revision Notes

## Topics Covered
- EBS (Elastic Block Store)
- EBS Snapshots
- S3 (Simple Storage Service)
- S3 Security & Encryption
- S3 Versioning & Replication
- S3 Storage Classes
- S3 Pre-Signed URLs
- S3 Access Logs
- EFS (Elastic File System)

# EBS (Elastic Block Store)

## Key Points
- **Block storage** attached to EC2 — behaves like a physical hard disk
- **Network-attached** (not physically in the host) → slight latency vs instance store
- **Locked to one AZ** — cannot directly attach to EC2 in a different AZ
- To move across AZs: **snapshot → restore in target AZ**
- Can be **detached and re-attached** to another EC2 in the same AZ
- New EBS volume attached to a running EC2 must be **formatted and mounted** before use
- **Root EBS** deleted on termination by default (`DeleteOnTermination = true`)
- Supports **encryption** (AES-256) — set at creation; encrypted snapshots stay encrypted
- **Multi-Attach** (io1/io2 only) → same volume attached to multiple EC2 instances in same AZ

## EBS Volume Types

| Type | Kind | IOPS | Best For |
|---|---|---|---|
| **gp3** | SSD | Up to 16,000 | Default choice; IOPS independent of size |
| **gp2** | SSD | 3 IOPS/GB, max 16,000 | Old general purpose — use gp3 instead |
| **io1/io2** | SSD | Up to 64,000 (io2 Block Express: 256,000) | High-IOPS DB (Oracle, MySQL) |
| **st1** | HDD | Throughput-optimized | Big data, log processing |
| **sc1** | HDD | Cold | Infrequently accessed, lowest cost |

- **gp3 > gp2** — cheaper, better performance, IOPS/throughput configurable independently

## Instance Store vs EBS

| | Instance Store | EBS |
|---|---|---|
| Attachment | Physical (in-host) | Network |
| Persistence | **Ephemeral** — lost on stop/terminate | **Persistent** |
| IOPS | Highest possible | Up to 256,000 (io2 BE) |
| Use case | Temp buffer, cache | OS, DB, persistent data |

## EBS Snapshots
- **Point-in-time backup** stored in S3 (AWS-managed, you don't see the bucket)
- **Incremental** — only changed blocks since last snapshot
- Can be **copied across AZs and Regions**
- **Archive tier** → 75% cheaper, restore takes **24–72 hours**
- **Recycle Bin** → protects snapshots from accidental deletion (configurable retention)
- Restoring = creates a new EBS volume (lazy loading by default — use **Fast Snapshot Restore** for instant)
- AMI creation also creates snapshots automatically

## Common Mistakes
- Forgetting new attached volume needs format + mount
- Assuming snapshot restore is instant — it's not (lazy loading)
- Using gp2 when gp3 is cheaper and better
- Expecting EBS to span AZs — it doesn't
- Not checking `DeleteOnTermination` flag for non-root volumes

# S3 (Simple Storage Service)

## Key Points
- **Object storage** — store files (objects) in **buckets** (directories)
- **Global service** but buckets are created in a specific **region**
- Bucket names must be **globally unique** across all AWS accounts
- Object **key** = full path of the file (e.g., `folder/subfolder/file.txt`)
- Max single object size: **5 TB** (single PUT: 5 GB — use **Multipart Upload** for > 5 GB; recommended > 100 MB)
- By default, S3 bucket is **private** — no public access
- **S3 is not mountable as a file system** — use SDK/API or tools like S3FS (with limitations)

## Use Cases
- Backup & restore, DR, archive (Glacier)
- Static website hosting
- Media hosting, data lakes, big data
- Hybrid cloud storage

## S3 Security

| Method | How |
|---|---|
| **IAM Policy** | Grant IAM user/role access to S3 API calls |
| **Bucket Policy** | JSON policy on the bucket — allow/deny access (accounts, public) |
| **Object ACL** | Fine-grained per-object control (mostly deprecated) |
| **Bucket ACL** | Bucket-level access (mostly deprecated) |

- **Block Public Access** setting → AWS blocks all public access by default at account/bucket level
- EC2 accessing S3 → use **IAM Role** attached to EC2, not access keys

## S3 Object Encryption

| Method | Key Managed By | Notes |
|---|---|---|
| **SSE-S3** | AWS (default) | Enabled by default, AES-256, no user control |
| **SSE-KMS** | AWS KMS | Audit via CloudTrail; KMS API call for every object access; can cause KMS throttling |
| **SSE-C** | Customer | Must send key with every request; HTTPS required; AWS doesn't store key |
| **Client-Side** | Customer (pre-upload) | Encrypt before upload using your own library |

- **TLS/HTTPS** — enforced for SSE-C; recommended for all S3 access

## S3 Versioning
- Enabled at **bucket level**
- Same key overwrite → creates a new **version** instead of replacing
- Deleting a versioned file adds a **Delete Marker** — object not permanently deleted
- To permanently delete: delete the specific version
- Protects against accidental overwrites/deletes

## S3 Replication

| Type | Scope | Use Case |
|---|---|---|
| **CRR** (Cross-Region Replication) | Different region | Compliance, lower latency |
| **SRR** (Same-Region Replication) | Same region | Log aggregation, dev/test copies |

- **Versioning must be enabled** on both source and destination buckets
- Buckets can be in different AWS accounts
- Replication is **async** and applies to new objects only (use S3 Batch Replication for existing objects)

## S3 Storage Classes

| Class | Retrieval | Use Case | Notes |
|---|---|---|---|
| **S3 Standard** | Instant | Frequently accessed | Default |
| **S3 Standard-IA** | Instant | Infrequently accessed | Lower storage cost, retrieval fee |
| **S3 One Zone-IA** | Instant | Infrequent, non-critical | Single AZ — risk of data loss if AZ fails |
| **S3 Intelligent-Tiering** | Instant | Unknown patterns | Auto-moves objects between tiers; small monthly fee |
| **S3 Glacier Instant** | Instant | Archive, accessed quarterly | |
| **S3 Glacier Flexible** | Minutes–hours | Archive | 90-day min storage |
| **S3 Glacier Deep Archive** | Up to 12 hours | Long-term archive | Cheapest; 180-day min |

## S3 Pre-Signed URLs
- Generate a temporary URL for **private** S3 objects
- Can be generated via AWS CLI, SDK, or Console
- URL contains **encrypted credentials/signature** → expires after set time
- Use case: share a private file temporarily without making bucket public
- Users accessing via pre-signed URL inherit the **permissions of the user who generated it**

## S3 Static Website Hosting
- Enable static hosting → set `index.html`
- Bucket must be **publicly accessible** (disable Block Public Access + add bucket policy allowing `s3:GetObject`)
- Website URL format: `<bucket-name>.s3-website.<region>.amazonaws.com`

## S3 Access Logs
- Log all requests to S3 to another S3 bucket
- **Never log to the same bucket** → infinite logging loop, exponential cost
- Enable logging on source bucket → select a separate **log bucket** (bucket policy auto-updated)

## CORS (Cross-Origin Resource Sharing)
- Origin = schema + host + port (e.g., `https://example.com:443`)
- Browser blocks cross-origin requests unless the other origin sends **CORS headers**
- Configure CORS on the S3 bucket being accessed (not the calling origin)
- Common: frontend at `domain-A.com` loading images from S3 at `domain-B.s3.amazonaws.com`

## Common Mistakes
- Storing access logs in the same bucket — causes infinite loop
- Forgetting Block Public Access must be disabled before bucket policy can make it public
- Not enabling versioning before setting up replication
- Using Glacier Deep Archive expecting instant retrieval — takes up to 12 hours
- Not using Multipart Upload for large files (>5 GB required, >100 MB recommended)

# EFS (Elastic File System)

## Key Points
- **Managed NFS (Network File System)** — can be mounted on **multiple EC2 instances simultaneously**
- Works across **multiple AZs** in the same region (unlike EBS which is AZ-locked)
- Use cases: shared content repository, web serving, home directories, CMS
- **ECS/Fargate** tasks can mount EFS for shared persistent storage
- Scales automatically — no capacity planning
- More expensive than EBS (pay per GB used)
- **EFS Infrequent Access (EFS-IA)** → lower cost for files not accessed frequently (lifecycle policy auto-moves files)

| | EBS | EFS |
|---|---|---|
| Access | 1 instance at a time (except io2 Multi-Attach) | **Multiple instances / multiple AZs** |
| AZ scope | Single AZ | Multi-AZ |
| Protocol | Block | NFS |
| Scaling | Manual (provision size) | Automatic |
| Cost | Lower | Higher |




![alt text](<Cloudfronte OAC - access private S3.png>)