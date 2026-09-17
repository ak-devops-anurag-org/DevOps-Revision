# AWS Final Revision — Index

> Quick-reference revision notes organized by topic category.
> All notes are bullet-point only — no paragraphs.
> Source material: AWS 1st week, 2nd week, 3rd week study notes.

---

## Files in This Directory

| File | Topics Covered |
|---|---|
| [compute.md](./compute.md) | EC2, AMI, ASG, ECS, Fargate, EKS, ECR, Lambda |
| [storage.md](./storage.md) | EBS, EBS Snapshots, S3, S3 Security/Encryption, S3 Versioning/Replication, S3 Storage Classes, EFS |
| [database.md](./database.md) | RDS, Read Replicas, Multi-AZ, Aurora, DynamoDB |
| [networking.md](./networking.md) | VPC, Subnets, IGW, NAT GW, SG, NACL, Bastion Host, VPC Peering, Transit GW, VPC Endpoints, PrivateLink, Site-to-Site VPN, Direct Connect, Elastic IPs, ALB/NLB/GWLB, CloudFront, Global Accelerator, Route 53 |
| [security.md](./security.md) | IAM (Users/Groups/Roles/Policies), Access Keys, MFA, S3 Security, KMS, SSM Session Manager |
| [serverless.md](./serverless.md) | Lambda, API Gateway, DynamoDB, Fargate, Serverless Patterns |

---

## All Topics — Quick List

### Compute
- EC2 — instance types, user data, key pairs, access methods
- AMI — golden images, region-specific, snapshot-backed
- Auto Scaling Group (ASG) — min/desired/max, scale triggers, cooldown
- ECS (EC2 vs Fargate launch types), ECS Task Role vs Instance Profile
- AWS Fargate — serverless containers, ECS/EKS compatible
- EKS — managed Kubernetes, EC2 nodes or Fargate pods
- ECR — container image registry
- AWS Lambda — FaaS, 15 min max, cold starts, provisioned concurrency, VPC Lambda, RDS Proxy

### Storage
- EBS — block storage, AZ-locked, gp3/gp2/io1/io2/st1/sc1, multi-attach (io2)
- EBS Snapshots — incremental, cross-region copy, archive tier, recycle bin
- S3 — object storage, global unique bucket names, max 5TB object
- S3 Security — bucket policies, IAM, Block Public Access
- S3 Encryption — SSE-S3, SSE-KMS, SSE-C, client-side
- S3 Versioning — delete markers, version management
- S3 Replication — CRR, SRR, versioning required, async
- S3 Storage Classes — Standard, IA, One Zone-IA, Intelligent-Tiering, Glacier tiers
- S3 Pre-Signed URLs — temporary private access, expiring
- S3 Static Website Hosting
- S3 Access Logs — separate log bucket required
- EFS — managed NFS, multi-AZ, shared access across EC2s

### Database
- RDS — managed SQL (Postgres, MySQL, Oracle, MariaDB, MSSQL)
- RDS Read Replicas — ASYNC, read scaling, manual failover, same-region replication free
- RDS Multi-AZ — SYNC, automatic failover, same endpoint
- Aurora — MySQL/PostgreSQL compatible, 6 copies/3 AZs, up to 15 replicas
- DynamoDB — serverless NoSQL, single-digit ms, 400KB item limit, provisioned vs on-demand

### Networking
- VPC — /16 to /28 CIDR, 5 reserved IPs, Regional, default VPC 172.31.0.0/16
- Subnets — single AZ, public vs private, route table association
- Route Tables — longest prefix wins, explicit vs implicit (main RT) association
- Internet Gateway — 1 per VPC, VPC level, free, performs NAT for public IPs
- NAT Gateway — private subnet outbound internet, public subnet + EIP, AZ-scoped, 1 per AZ for HA
- Security Groups — stateful, instance level, allow only, all rules evaluated
- NACL — stateless, subnet level, allow + deny, lowest number first, ephemeral ports
- Bastion Host — jump server in public subnet, port 22 from internet
- VPC Peering — non-transitive, no CIDR overlap, routes in both VPCs required
- Transit Gateway — hub-and-spoke, transitive, IP Multicast, regional
- VPC Endpoints — Gateway (S3/DynamoDB, free) vs Interface (PrivateLink, paid)
- PrivateLink — share your service to other VPCs/accounts privately, NLB-backed
- Site-to-Site VPN — IPSec over internet, CGW + VGW, route propagation, 1.25 Gbps/tunnel
- Direct Connect — dedicated private line, weeks to set up, up to 100 Gbps
- Elastic IP — 5 per region limit, billed when unattached, static public IP
- ALB — Layer 7, HTTP/HTTPS, path/host routing, sticky sessions
- NLB — Layer 4, TCP/UDP, static IP per AZ, ultra-low latency
- GWLB — Layer 3, GENEVE port 6081, inline firewall appliances
- CloudFront — CDN, 200+ edge locations, OAC for private S3, cache invalidation, geo restriction
- Global Accelerator — 2 Anycast IPs, TCP/UDP, instant failover, no caching
- Route 53 — global DNS, 100% SLA, A/AAAA/CNAME/Alias/NS records, routing policies

### Security
- IAM — global, users/groups/roles/policies, least privilege
- IAM Roles — trust policy + permission policy, used by AWS services
- Access Keys — programmatic access, rotate regularly, never hardcode
- MFA — root + admin accounts minimum
- IAM Credentials Report — CSV of all users + credential status
- IAM Access Advisor — service-level access audit
- S3 Bucket Policy — JSON, allow/deny access at bucket level
- KMS — managed key service, CloudTrail audit, CMK vs AWS Managed Keys
- SSE-S3 / SSE-KMS / SSE-C — encryption at rest options
- SSM Session Manager — no port 22, IAM Role + SSM Agent + endpoints, full audit logs

### Serverless
- Lambda — event-driven, stateless, 15 min max, 1000 concurrent, cold starts, SnapStart
- API Gateway — REST/HTTP/WebSocket API, throttling, caching, authorizers, stages
- DynamoDB — serverless NoSQL, auto-scale, RCU/WCU
- Fargate — serverless containers
- Serverless patterns — Lambda + API GW + DynamoDB, S3 Events + Lambda, EventBridge + Lambda

---

## Key Defaults & Limits Cheat Sheet

| Resource | Limit / Default |
|---|---|
| Elastic IPs per region | **5** |
| VPC CIDR range | **`/16` (max) to `/28` (min)** |
| Reserved IPs per subnet | **5** |
| IGWs per VPC | **1** |
| VPCs per region | **5** (soft) |
| Lambda max execution | **15 minutes** |
| Lambda concurrency | **1,000** (soft, increasable) |
| Lambda memory | **128 MB – 10 GB** |
| Lambda deployment (zip) | **50 MB** compressed / **250 MB** uncompressed |
| DynamoDB max item size | **400 KB** |
| S3 max single object | **5 TB** (multipart > 5 GB required, > 100 MB recommended) |
| API Gateway timeout (REST) | **29 seconds** (hard limit) |
| EBS gp3 max IOPS | **16,000** |
| EBS io2 Block Express max IOPS | **256,000** |
| RDS Read Replicas max | **5** (standard RDS) / **15** (Aurora) |
| NLB cross-zone LB | **Off** by default |
| ALB cross-zone LB | **On** by default |
| NAT GW bandwidth | **5 Gbps** (auto-scales to 100+ Gbps) |
| VPN tunnel bandwidth | **1.25 Gbps** per tunnel |
| SSH port | **22** |
| RDP port | **3389** |
| GWLB port | **6081 (GENEVE)** |
| Ephemeral port range | **1024–65535** |
| PostgreSQL port | **5432** |
| MySQL/Aurora port | **3306** |
| MSSQL port | **1433** |
