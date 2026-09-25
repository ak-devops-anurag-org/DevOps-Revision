# AWS Revision Notes

> **Style:** Short bullets only. No paragraphs. Skim before interviews / work.

---

## Topics Covered

- AWS Global Infrastructure (Regions & AZs)
- IAM (Identity & Access Management)
- EC2 Fundamentals
- Security Groups & NACL
- EBS (Elastic Block Store) & Snapshots
- AMI (Amazon Machine Image)
- RDS, Read Replicas & Multi-AZ
- Route 53 (DNS)
- Elastic IP & Public/Private IPs
- Load Balancers (ALB, NLB, GWLB)
- High Availability & Scalability
- VPC (Virtual Private Cloud)
- Subnets, CIDR, Route Tables
- Internet Gateway (IGW)
- NAT Gateway
- Bastion Host
- VPC Peering
- Transit Gateway
- VPC Endpoints (Gateway & Interface)
- Site-to-Site VPN & AWS CloudHub
- Direct Connect
- AWS Systems Manager (SSM) — Private EC2 Access

---

# AWS Global Infrastructure

## What to Remember

- **Region** = geographic area with 2+ AZs (e.g., `ap-south-1` = Mumbai).
- **AZ (Availability Zone)** = one or more isolated data centers within a region.
- Not all AWS services are available in every region — always verify before designing.
- Services are either **Global** (IAM, Route 53, CloudFront) or **Regional** (EC2, RDS, VPC).
- AZs in a region are connected via **low-latency, high-bandwidth private links**.

## Real World Example

- An app deployed across 3 AZs in `ap-south-1` survives a full AZ outage.
- Use `eu-west-1` for EU customers — GDPR data residency compliance.

## Production Use Case

- Multi-AZ deployment for HA; multi-region for DR (disaster recovery).
- Always choose the region **closest to your users** to minimize latency.

## Exam / Interview Facts

- **IAM is Global** — users, roles, and policies are not region-specific.
- CloudFront, Route 53, WAF, and IAM → **Global**.
- EC2, S3 (buckets), RDS → **Regional**.
- Edge Locations are separate from AZs — used by CloudFront/Route 53.

## Common Mistakes

- Forgetting to switch the console region and then wondering why resources are missing.
- Assuming all services exist in all regions (especially newer services).

---

# IAM (Identity & Access Management)

## What to Remember

- **IAM is a Global service** — not region-specific.
- Components: **Users**, **Groups**, **Roles**, **Policies**.
- **Policy** = JSON document defining permissions (Allow / Deny on actions + resources).
- **Inline policy** = attached directly to a single user/role. **Group policy** = attached to a group, inherited by all members.
- **Role** has two parts: **Permission Policy** (what can it do?) + **Trust Policy** (who can assume it?).
- **Access Keys** = programmatic access (CLI/SDK). Treated like passwords — never share.
- **MFA** strongly recommended on root and all admin accounts.
- **IAM Credentials Report** = account-level CSV of all users + credential status.
- **Access Advisor** = shows services a user/role has accessed and when (least-privilege audit).
- Default: new user has **zero permissions** — must be explicitly granted.

## Real World Example

- Dev team grouped in `Dev-Group` with `AmazonEC2ReadOnlyAccess` policy.
- EC2 instance needs S3 access → attach an **IAM Role** to the instance, not hardcoded keys.
- CI/CD pipeline uses an IAM Role (OIDC trust) — no long-lived credentials.

## Production Use Case

- **Never use root account** for day-to-day operations — create an admin IAM user.
- Rotate access keys regularly; use **AWS Secrets Manager** or environment IAM Roles.
- Apply **least privilege** — only grant what's needed.

## Exam / Interview Facts

- Root account has **full access** and cannot be restricted by policies.
- `aws configure` stores Access Key ID + Secret + region + output format.
- **AWS CLI** and **SDK** are both protected by access keys.
- **CloudShell** = browser-based terminal in AWS Console — inherits the logged-in user's permissions (not available in all regions).
- Access keys created under an IAM user inherit **that user's permissions**.

## Common Mistakes

- Creating access keys for root account.
- Attaching permissions directly to users instead of using groups.
- Hardcoding access keys in code or Dockerfiles — **critical security risk**.
- Not enabling MFA on privileged accounts.

| IAM Entity | What it is | Used for |
|---|---|---|
| **User** | A person / service identity | Human logins, programmatic access |
| **Group** | Collection of users | Applying policies at scale |
| **Role** | Assumable identity with permissions | AWS services (EC2, Lambda), cross-account |
| **Policy** | JSON permissions document | Attached to users, groups, or roles |

---

# EC2 Fundamentals

## What to Remember

- **EC2** = virtual machine (IaaS) — you choose OS, CPU, RAM, storage, networking.
- **User Data** script runs **once at first launch**, as `root` (no `sudo` needed). Used for bootstrapping (install packages, configure app).
- **Instance types** follow naming: `m5.large` → family (`m`) + generation (`5`) + size (`large`).
- Key instance families:
  - **Compute-optimized (C)** → CPU-heavy workloads (batch, ML inference).
  - **Memory-optimized (R, X)** → in-memory databases, caches.
  - **Storage-optimized (I, D)** → high IOPS, data warehousing.
  - **General purpose (T, M)** → web servers, dev environments.
- **Key pair** = RSA/ED25519 key pair for SSH access. AWS stores public key; you keep private (`.pem`).
- **Public IP changes** on every stop/start — use **Elastic IP** if you need a static one.
- `chmod 0400 <key.pem>` required before `ssh -i <key.pem> ec2-user@<public-ip>`.
- **EC2 Instance Connect** = browser-based SSH via AWS Console (still requires port 22 open).

## Real World Example

- Web servers use `t3.medium` (general purpose); ML training uses `p3.2xlarge` (GPU).
- User Data used to install Nginx and pull app code on boot — no manual SSH needed.

## Production Use Case

- **Auto Scaling Groups (ASG)** launch/terminate EC2 instances based on load.
- Spot instances used for batch jobs (up to 90% cheaper — can be interrupted).
- Reserved Instances for predictable, steady-state workloads (1–3 year commitment).

## Exam / Interview Facts

- EC2 is **Regional** — instances live in a specific AZ within a region.
- **Stopping** an EC2 instance: EBS data retained, public IP lost, no charge for compute.
- **Terminating**: EBS root volume deleted by default (unless `Delete on termination = false`).
- SSH default port: **22**. RDP (Windows) default port: **3389**.
- "**Connection timed out**" = Security Group issue. "**Connection refused**" = app not running.

## Common Mistakes

- Forgetting to open port 22 / 3389 in Security Group for remote access.
- Using root account to SSH — use `ec2-user`, `ubuntu`, or `centos` as default usernames.
- Not setting a `.pem` key to `0400` → SSH refuses with "Permissions too open" error.
- Giving EC2 instances hardcoded IAM credentials — always use an **IAM Role** attached to the instance.

---

# Security Groups & NACL

## What to Remember

- **Security Group (SG)** = virtual firewall at the **instance (ENI) level**.
- **NACL** = firewall at the **subnet level**.
- SG is **stateful** — inbound allow automatically allows return outbound traffic.
- NACL is **stateless** — inbound and outbound rules evaluated independently.
- SG only has **Allow rules** (default implicit deny). NACL has both **Allow and Deny** rules.
- NACL rules evaluated in **numerical order** — lowest number wins.
- SG can be attached to multiple instances. One instance can have multiple SGs.
- SG is **locked to a region/VPC** — cannot use SG from one VPC in another.
- SG lives **outside the EC2 instance** — if it blocks traffic, the instance never sees the packet.
- Default SG: **all inbound blocked**, **all outbound allowed**.

## Real World Example

- SG for web server: inbound 80/443 from `0.0.0.0/0`, outbound all.
- NACL on DB subnet: deny inbound from known malicious CIDR ranges.

## Production Use Case

- Use SGs as the **primary firewall** for most use cases.
- Use NACLs for **subnet-level broad deny rules** (e.g., IP blocklist, compliance).
- Reference another SG as a source in an SG rule — allows all instances in that SG (dynamic, no IP management).

## Exam / Interview Facts

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance (ENI) | Subnet |
| Stateful/Stateless | **Stateful** | **Stateless** |
| Allow + Deny | Allow only | Allow + Deny |
| Rule evaluation | All rules evaluated | Lowest number first |

- **Ephemeral ports** (1024–65535): client picks a random high port for response traffic. NACLs must explicitly allow this range for return traffic.
- **VPC Flow Logs** → tool to debug whether SG or NACL is blocking (look for `REJECT` in the log).

## Common Mistakes

- Forgetting to add outbound ephemeral port rules in NACL (stateless — return traffic won't auto-pass).
- Trying to add a **Deny rule** in a Security Group — not possible.
- Assuming SG rules apply to all instances in a VPC — they only apply to instances they're attached to.

---

# EBS (Elastic Block Store) & Snapshots

## What to Remember

- **EBS** = persistent block storage attached to EC2 — behaves like a physical hard disk.
- **Network-attached** (not physically in the host) → slight latency vs instance store.
- **Locked to an AZ** — you cannot directly attach an EBS volume from `ap-south-1a` to an instance in `ap-south-1b`.
- To move across AZs: **take a snapshot → restore in target AZ**.
- Can be **detached from one EC2 and attached to another** in the same AZ (like unplugging a USB drive).
- New EBS volumes must be **formatted and mounted** before use on a new EC2 instance.
- **Root EBS volume** is deleted on instance termination by default (`DeleteOnTermination = true`).
- EBS supports **encryption** (AES-256) — can be enabled at creation. Encrypted snapshots stay encrypted.

## EBS Volume Types

| Type | IOPS | Use Case |
|---|---|---|
| **gp3** | Up to 16,000 | General purpose — default choice; IOPS independent of size |
| **gp2** | 3 IOPS/GB, up to 16,000 | Older general purpose — being replaced by gp3 |
| **io1/io2** | Up to 64,000 (io2 Block Express: 256,000) | Databases needing high consistent IOPS |
| **st1** | Throughput-optimized HDD | Big data, data warehouses |
| **sc1** | Cold HDD | Infrequently accessed data, lowest cost |

## EBS Snapshots

- **Snapshot** = point-in-time backup of EBS volume stored in **S3** (managed by AWS).
- Incremental — only changed blocks since last snapshot are stored.
- **Can be copied across AZs and Regions** — use this to migrate volumes cross-region.
- **Archive tier**: move snapshot to archive for 75% cheaper storage — restore takes **24–72 hours**.
- **Recycle Bin**: protects snapshots from accidental deletion — configurable retention period.
- Snapshot restores create a new EBS volume (not instant — data loads lazily unless using Fast Snapshot Restore).

## Real World Example

- Nightly automated snapshots of production DB volume via AWS Backup or Lambda.
- Copy snapshot to DR region for cross-region disaster recovery.

## Production Use Case

- **gp3** is the default for most workloads (better price/performance than gp2).
- **io2** for Oracle, MySQL with high IOPS requirements.
- Snapshot-based AMI creation for golden server images.

## Exam / Interview Facts

- EBS is **AZ-scoped** — snapshot is the migration path across AZs.
- **Multi-attach** (io1/io2 only) — attach one volume to multiple EC2 instances (same AZ).
- **Instance Store** ≠ EBS — instance store is physically attached, ephemeral (lost on stop/terminate). Highest IOPS possible but no persistence.

## Common Mistakes

- Forgetting that a new EBS volume attached to a running EC2 still needs to be partitioned and mounted.
- Assuming EBS snapshots are instant restores — they're not (lazy loading by default).
- Using gp2 when gp3 is cheaper and more flexible.

---

# AMI (Amazon Machine Image)

## What to Remember

- **AMI** = template for launching EC2 instances (OS + pre-installed software + configuration).
- **Region-specific** — must copy AMI to another region before using it there.
- AMI types: **Public AMI** (AWS/community), **Custom AMI** (yours), **AWS Marketplace AMI** (third-party, may have cost).
- Creating a custom AMI: **Launch EC2 → Customize → Stop → Create AMI** (this also creates EBS snapshots automatically).
- AMI includes: root volume snapshot(s), permissions, block device mappings.

## Real World Example

- Bake Nginx + app code into an AMI → ASG launches pre-configured instances in seconds (no bootstrapping delay).
- Golden AMI pattern: one hardened, patched base image used across all teams.

## Production Use Case

- **Immutable infrastructure**: bake everything into the AMI, never SSH into production to patch.
- AMIs speed up scale-out — no waiting for User Data scripts to finish.

## Exam / Interview Facts

- AMI = EBS snapshot(s) + metadata. Deleting an AMI does **not** automatically delete underlying snapshots.
- Copying an AMI across regions → also copies snapshots to the target region.
- You can share AMIs across AWS accounts.

## Common Mistakes

- Deleting an AMI thinking it also cleans up the snapshots — must delete snapshots separately.
- Forgetting to copy AMI to the target region before launching in that region.
- Not deregistering old AMIs — causes snapshot cost accumulation.

---

# RDS, Read Replicas & Multi-AZ

## What to Remember

- **RDS** = AWS-managed relational database (you don't manage the OS or DB engine installation).
- Supported engines: **PostgreSQL, MySQL, MariaDB, Oracle, Microsoft SQL Server, Aurora**.
- **AWS handles**: hardware provisioning, patching, backups, monitoring.
- **You handle**: DB schema, queries, parameter groups, connection strings.
- **Storage auto-scaling** — RDS can automatically increase storage to avoid running out.

## Read Replicas vs Multi-AZ

| Feature | Read Replica | Multi-AZ |
|---|---|---|
| Purpose | **Read scaling** (offload SELECT queries) | **High Availability** (automatic failover) |
| Replication | **ASYNC** | **SYNC** |
| Failover | Manual (you promote the replica) | **Automatic** — AWS handles it |
| Endpoint | **Different endpoint** per replica | **Same endpoint** — DNS updates automatically |
| Use for | Analytics, reporting, heavy reads | Production HA, zero-downtime failover |
| Cross-region | **Yes** | Only within region |

- Read Replica **can itself become Multi-AZ** for Disaster Recovery.
- **Network cost**: cross-AZ data transfer has a cost. Exception → **Read Replicas within the same region are free** for the replication data transfer.
- **Single AZ → Multi-AZ migration**: zero downtime, just modify the DB. AWS takes a snapshot + sets up SYNC replication behind the scenes.

## Real World Example

- Prod e-commerce DB: Multi-AZ primary in `ap-south-1a`, standby in `ap-south-1b`.
- Read Replica in same region used by the analytics/reporting team — no load on primary.

## Production Use Case

- Multi-AZ: mandatory for any production workload needing HA.
- Read Replicas: scale read-heavy workloads (dashboards, reports) without touching primary.

## Exam / Interview Facts

- Multi-AZ standby **cannot be used for reads** — it's purely a hot standby.
- Failover in Multi-AZ takes ~1–2 minutes (DNS TTL-dependent).
- **Aurora** = AWS-managed MySQL/PostgreSQL-compatible engine — 5x faster than MySQL, 3x than PostgreSQL, 6 copies of data across 3 AZs automatically.

## Common Mistakes

- Thinking Multi-AZ standby can serve read traffic — it cannot.
- Forgetting that Read Replica promotion is manual — you must do it yourself when primary fails.
- Not setting proper DB parameter groups — default settings are often not production-ready.
- Forgetting that cross-AZ Read Replica replication has a network cost (only same-region replication to Read Replicas is free).

---

# Route 53

## What to Remember

- **Route 53** = AWS's managed DNS service + domain registrar.
- **Global service** — not region-specific.
- **DNS record types**:
  - **A** → hostname → IPv4
  - **AAAA** → hostname → IPv6
  - **CNAME** → hostname → hostname (cannot use CNAME for zone apex / root domain)
  - **NS** → Name Servers for the hosted zone
  - **Alias** → AWS-specific — hostname → AWS resource (ELB, CloudFront, S3). Works at zone apex. **Free** queries. Preferred over CNAME for AWS resources.
- **TTL** = how long clients cache the DNS record. High TTL = fewer queries but slower updates.
- **Hosted Zone** = container for DNS records for a domain (public or private).

## DNS Hierarchy (Quick Reference)

- **FQDN**: `api.www.example.com`
- **TLD**: `.com`
- **Second Level Domain**: `example.com`
- **Sub-domain**: `api.example.com` or `www.example.com`

## Routing Policies

| Policy | Use Case |
|---|---|
| **Simple** | Single resource, no health checks |
| **Weighted** | A/B testing, gradual traffic shift |
| **Latency** | Route to lowest latency region |
| **Failover** | Active-passive HA |
| **Geolocation** | Route by user's country/continent |
| **Geoproximity** | Route by geographic proximity (with Traffic Flow) |
| **Multi-value** | Return multiple IPs, each with health check |

## Real World Example

- Weighted routing: send 10% traffic to new version, 90% to old (canary deployment).
- Failover routing: primary in `us-east-1`, failover to `eu-west-1` if health check fails.

## Production Use Case

- Use **Alias records** for all AWS resources (ELB, CloudFront, API Gateway) — not CNAME.
- Health checks on Route 53 → trigger failover routing automatically.

## Exam / Interview Facts

- **CNAME cannot point to a zone apex** (e.g., `example.com` — no subdomain). Use **Alias** instead.
- Route 53 = 100% SLA (only AWS service with this guarantee).
- Health checks can monitor endpoints, other health checks (calculated), or CloudWatch alarms.

## Common Mistakes

- Using CNAME at the root domain (`example.com`) — will fail. Use Alias records.
- Setting a very low TTL during normal operation — causes high query cost.
- Forgetting to attach health checks to failover routing records.

---

# Elastic IP & Public/Private IPs

## What to Remember

- **Public IP**: assigned to EC2 at launch if subnet `Auto-assign public IP = true`. **Changes on every stop/start.**
- **Private IP**: stays with the instance for its lifetime (doesn't change on restart).
- **Elastic IP (EIP)**: static, persistent public IPv4 address you own.
  - **Limit: 5 Elastic IPs per AWS account per region** (soft limit, can request increase).
  - EIP billed when **not associated** with a running instance — always attach or release unused EIPs.
- **Best practice**: avoid EIPs — use DNS names with Route 53 Alias records instead for flexible, scalable architecture.

## Production Use Case

- EIP used for a NAT Gateway (which requires an EIP by design).
- Bastion host with EIP so its IP never changes (whitelisted in on-prem firewalls).

## Exam / Interview Facts

- Stopping and starting an EC2 instance releases the public IP but keeps the private IP.
- EIPs are region-specific — you cannot move an EIP to another region directly.
- If you have more than 5 EIPs needed → submit a service limit increase request.

## Common Mistakes

- Forgetting that unused EIPs are billed — always release EIPs you don't need.
- Designing architecture around EIPs instead of using DNS — adds unnecessary operational overhead.

---

# Load Balancers (ALB, NLB, GWLB)

## What to Remember

- **ELB (Elastic Load Balancer)** = AWS-managed load balancer — AWS handles HA, upgrades, and maintenance.
- **Health checks** are critical — LB routes traffic only to healthy targets (checks port + route).
- Three types of modern AWS LBs:

| LB Type | OSI Layer | Protocols | Use Case |
|---|---|---|---|
| **ALB** (Application) | Layer 7 | HTTP, HTTPS, WebSocket | Web apps, microservices, routing rules |
| **NLB** (Network) | Layer 4 | TCP, UDP, TLS | Ultra-low latency, static IPs, gaming, IoT |
| **GWLB** (Gateway) | Layer 3 (Network) | GENEVE (port 6081) | Inline 3rd party appliances (firewalls, IDS/IPS) |

- Classic LB (CLB) → **deprecated**, don't use.
- **ALB** can route based on: path (`/api/*`), hostname (`api.example.com`), headers, query strings, source IP.
- **Target Groups**: ALB/NLB routes to target groups (EC2 instances, Lambda, ECS containers, IPs).
- **Listener**: defines the port/protocol the LB listens on (e.g., port 443 HTTPS).
- **SSL termination** at ALB — backend EC2 can communicate over HTTP 80.
- **NLB** gets a **static IP per AZ** (useful for IP whitelisting requirements).

## Real World Example

- ALB with two target groups: `/api/*` → API servers, `/app/*` → frontend servers — path-based routing.
- NLB used for a financial app requiring static IPs for client whitelisting.

## Production Use Case

- ALB = default choice for HTTP/HTTPS web applications.
- NLB = when you need extreme performance (millions of req/sec) or TCP/UDP protocols.
- GWLB = security inspection pipeline (all traffic routed through a firewall appliance before reaching app).

## Exam / Interview Facts

- Traffic from clients → LB: **HTTP 80** or **HTTPS 443**.
- Traffic from LB → EC2: typically **HTTP 80** (after SSL termination at LB).
- **Sticky sessions** (session affinity): ALB can route same client to same backend using cookies.
- ALB supports **Lambda functions** as targets (not just EC2).
- Cross-zone load balancing: ALB has it **on by default**; NLB/GWLB have it **off by default** (incurs cost if enabled on NLB).

## Common Mistakes

- Opening EC2 Security Group directly to the internet — should only allow traffic from the LB's SG.
- Forgetting health check configuration — LB will mark targets unhealthy if the health check path returns non-2xx.
- Not enabling **access logs** on ALB/NLB — critical for debugging and compliance.

---

# High Availability & Scalability

## What to Remember

- **Vertical scaling** = bigger instance (Scale up / down). Has limits (largest instance size).
- **Horizontal scaling** = more instances (Scale out / in). Preferred for modern cloud architectures.
- **High Availability (HA)** = running across **multiple AZs** to survive an AZ failure.
- **ASG (Auto Scaling Group)** = automatically launch/terminate EC2 instances based on demand.
  - **Min, Desired, Max** capacity defined.
  - Scales based on: CPU, network, custom CloudWatch metrics, or schedules.
  - Automatically replaces unhealthy instances.
  - Works with ALB/NLB to register/deregister instances from target groups.

## Production Use Case

- Web tier: ALB + ASG across 3 AZs — handles traffic spikes automatically.
- Database tier: RDS Multi-AZ — survives AZ failure with automatic failover.

## Exam / Interview Facts

- HA ≠ Scalability. You can be HA (multi-AZ, same size) without horizontal scalability.
- ASG does **not charge extra** — you pay only for the EC2 instances it launches.
- **Scale-in protection** can be set on specific instances to prevent ASG from terminating them.

## Common Mistakes

- Deploying everything in a single AZ — no HA.
- Not setting the right cooldown period in ASG → leads to rapid scale-out/in oscillations.

---

# VPC (Virtual Private Cloud)

## What to Remember

- **VPC** = logically isolated network in AWS — your private section of the AWS cloud.
- **One Default VPC** per region per account. CIDR: `172.31.0.0/16`.
- Default VPC comes with: public subnet in each AZ, IGW attached, main route table with internet route, default SG.
- VPC CIDR allowed range: **`/16` (max, 65,536 IPs) to `/28` (min, 16 IPs)**.
- **AWS reserves 5 IPs in every subnet** (first 4 + last 1 — cannot be assigned to instances).
- A VPC can have **up to 5 CIDRs** (primary + secondary CIDRs).
- **VPC is Regional** — spans all AZs in the region.

## Private IP Ranges (RFC 1918)

| Range | CIDR | Typical Use |
|---|---|---|
| `10.0.0.0 – 10.255.255.255` | `/8` | Large corporate networks |
| `172.16.0.0 – 172.31.255.255` | `/12` | AWS Default VPC |
| `192.168.0.0 – 192.168.255.255` | `/16` | Home networks |

## Real World Example

- Production VPC: `10.0.0.0/16`. Public subnets `/24`, private app subnets `/24`, private DB subnets `/24`.
- Separate VPCs for dev, staging, prod — isolated blast radius.

## Production Use Case

- Never use the Default VPC for production — create a custom VPC with proper CIDR planning.
- Plan CIDRs carefully upfront — cannot shrink a VPC CIDR once created (only add secondary).

## Exam / Interview Facts

- VPC is free to create — charges come from resources inside it (EC2, NAT GW, etc.).
- `0.0.0.0/0` = all IPv4 traffic (used in route tables to mean "internet").
- Default VPC has `Auto-assign public IP = true` for its subnets.

## Common Mistakes

- Using too small a CIDR (`/28`) — runs out of IPs quickly.
- Forgetting the 5 reserved IPs when planning subnets — calculator shows 16 IPs in `/28` but only 11 usable.
- CIDR overlap with on-prem network → blocks VPN/Direct Connect connectivity.

---

# Subnets, CIDR & Route Tables

## What to Remember

- **Subnet** = a range of IPs within a VPC, confined to **one AZ**.
- **Public subnet** = has a route to IGW in its route table.
- **Private subnet** = no route to IGW (no direct internet access).
- **Route Table** = set of rules (routes) that determine where traffic is directed.
  - `Destination` (CIDR) → `Target` (IGW, NAT GW, VPC endpoint, etc.)
  - **Most specific route wins** (longest prefix match).
- **Main Route Table**: default for all subnets not explicitly associated with another route table.
- **Explicit association**: manually assign a subnet to a specific route table.

## Subnet CIDR — Reserved IPs Example

For `10.0.0.0/24` (256 IPs), AWS reserves:
- `10.0.0.0` — Network address
- `10.0.0.1` — VPC Router
- `10.0.0.2` — DNS server
- `10.0.0.3` — Future use
- `10.0.0.255` — Broadcast (not used but reserved)

→ **251 usable IPs** in a `/24` subnet.

## Production Use Case

- **3-tier architecture**: public subnets (LB), private app subnets (EC2/ECS), private DB subnets (RDS) — all separate subnets.
- Each tier in a separate subnet per AZ for HA.

## Common Mistakes

- Putting RDS in a public subnet — major security risk.
- Using the same subnet for public-facing LB and backend EC2.
- Forgetting that a subnet exists in exactly one AZ — to span AZs you need multiple subnets.

---

# Internet Gateway (IGW)

## What to Remember

- **IGW** = allows resources in a VPC to communicate with the internet.
- **One IGW per VPC** — cannot attach multiple IGWs.
- Attached at the **VPC level** (not subnet level).
- **Horizontally scaled, redundant, HA** — AWS manages it.
- **No cost** for the IGW itself — only egress data transfer is charged.
- For a resource to reach the internet: it needs a **public/EIP** + a route in its subnet's route table **pointing to IGW**.
- IGW performs **NAT** for instances with public IPs (maps public IP ↔ private IP).

## Common Mistakes

- Creating IGW but forgetting to **attach it to the VPC**.
- Forgetting to add the `0.0.0.0/0 → IGW` route in the public subnet's route table.
- Thinking IGW alone gives internet access — you also need a public IP on the resource.

---

# NAT Gateway

## What to Remember

- **NAT GW** = gives **private subnet instances outbound-only internet access** (cannot initiate connections inbound).
- Must be deployed in a **public subnet** (needs IGW access).
- Requires an **Elastic IP**.
- Private subnet route table needs: `0.0.0.0/0 → NAT GW`.
- **AWS-managed**: highly available within one AZ, auto-scales bandwidth (5–100+ Gbps).
- **For HA**: deploy one NAT GW **per AZ** and update each AZ's private subnet route table to use its local NAT GW.
- **Not free** — charged per hour + per GB of data processed.
- **NAT Instance** (old) = EC2-based NAT, self-managed, cheaper but requires manual HA, no auto-scaling. Mostly obsolete.

## Traffic Flow

```
Private EC2 → NAT GW (Elastic IP) → IGW → Internet
```

## Production Use Case

- Private EC2 instances pulling OS updates, Docker images, or calling third-party APIs.
- Lambda in a private VPC needs internet → route through NAT GW.

## Exam / Interview Facts

- NAT GW is an **AZ-scoped** resource — one NAT GW cannot serve multiple AZs for HA.
- NAT GW **supports TCP, UDP, ICMP** — not full protocol support like an EC2-based NAT.
- **Cannot** use NAT GW to allow inbound internet-initiated connections to private instances.

## Common Mistakes

- Deploying one NAT GW and thinking it's HA — one NAT GW dies if its AZ fails.
- Forgetting to update private subnet's route table to point to NAT GW.
- Using NAT GW to reach S3/DynamoDB — use **Gateway Endpoint** instead (free + no internet).

---

# Bastion Host

## What to Remember

- **Bastion Host (Jump Host)** = a public EC2 instance used as a secure entry point to reach private EC2 instances.
- Sits in the **public subnet** — the only instance that accepts SSH/RDP from the internet.
- From Bastion → SSH into private instances using the private IP.
- Private instances only allow SSH from the **Bastion's Security Group** — not from the internet directly.
- **Elastic IP recommended** on Bastion — so the IP doesn't change on restarts.

## Production Use Case

- Legacy pattern for admin access to private EC2 instances.
- Being replaced by **AWS Systems Manager Session Manager (SSM)** — no need to open port 22 at all.

## Security Pattern

```
Internet → Bastion SG (port 22 open) → Private SG (port 22 only from Bastion SG)
```

## Common Mistakes

- Opening port 22 on private EC2 to `0.0.0.0/0` — defeats the purpose of a Bastion.
- Not restricting Bastion SG to known IPs (corporate IP range) — leaves it open to the world.
- Not using SSM when available — Bastion adds operational overhead and a security surface.

---

# VPC Peering

## What to Remember

- **VPC Peering** = private, direct network connection between two VPCs.
- Works across **different accounts** and **different regions** (inter-region peering).
- **Non-transitive** — if A↔B and B↔C are peered, A cannot reach C. You must create A↔C peering separately.
- **No CIDR overlap allowed** — both VPCs must have non-overlapping CIDR ranges.
- Creating a peering connection alone is **not enough** — must **add routes in both VPC route tables**.
- Scales poorly with many VPCs (N-to-N peering = N*(N-1)/2 connections) — use **Transit Gateway** instead.

## Real World Example

- Company with two AWS accounts (dev and prod) — VPC peering allows dev to query a shared service in prod.

## Exam / Interview Facts

- VPC Peering connection has **no bandwidth limit** (limited by instance bandwidth).
- Data transfer across VPC peering **within the same AZ is free** (as of recent AWS pricing). Cross-AZ or cross-region peering has data transfer charges.
- Cannot edit CIDR of a VPC once peered if it would cause overlap.

## Common Mistakes

- Forgetting to add routes to route tables after creating the peering connection — traffic will not flow.
- Expecting transitive routing — it doesn't exist in VPC Peering.
- CIDR overlap between VPCs — prevents peering from being accepted.

---

# Transit Gateway

## What to Remember

- **Transit Gateway (TGW)** = **hub-and-spoke** network transit hub — connects multiple VPCs, on-prem networks via a single managed resource.
- Eliminates the need for a full mesh of VPC peering connections.
- **Regional resource** — can work **cross-region** (inter-region TGW peering).
- Uses **Route Tables** to control which VPCs can communicate with which (isolate environments).
- Supports: VPC attachments, VPN attachments, Direct Connect Gateway attachments.
- **Only AWS service supporting IP Multicast**.
- **Transitive routing** is supported (A → TGW → B → TGW → C — A can reach C).

## VPC Peering vs Transit Gateway

| | VPC Peering | Transit Gateway |
|---|---|---|
| Transitive routing | ❌ No | ✅ Yes |
| Scale | Mesh (complex at scale) | Hub-and-spoke (scales easily) |
| Cost | Data transfer only | Per attachment + data transfer |
| Cross-account | Yes | Yes |
| IP Multicast | No | **Yes (only service)** |

## Production Use Case

- Large enterprise with 50+ VPCs in one region — TGW simplifies connectivity.
- Centralized egress: all VPCs route through a single NAT GW VPC via TGW — saves cost vs NAT GW in each VPC.
- Connecting on-prem → multiple VPCs via one VPN attachment to TGW (not individual VPN per VPC).

## Common Mistakes

- Using VPC Peering when you have 10+ VPCs — becomes unmanageable quickly.
- Not designing TGW route tables to isolate prod from non-prod VPCs.
- Forgetting that TGW is **not free** — charged per attachment per hour + data processed.

---

# VPC Endpoints (Gateway & Interface)

## What to Remember

- **VPC Endpoint** = private connection from your VPC to AWS services — traffic stays on **AWS private network** (no IGW, NAT GW, or public internet).
- Deployed within the VPC.

| Type | Mechanism | Cost | Services |
|---|---|---|---|
| **Gateway Endpoint** | Adds entry to route table | **Free** | **S3** and **DynamoDB** only |
| **Interface Endpoint** | Creates an ENI with a private IP (PrivateLink) | Paid (hourly + data) | Most AWS services (SSM, Secrets Manager, ECR, SQS, SNS, etc.) |

- **Gateway Endpoint**: purely a route table change — no ENI, no IP, no PrivateLink.
- **Interface Endpoint**: creates an ENI in your subnet with a private IP — can be accessed from on-prem (via VPN/Direct Connect) or other VPCs (via peering/TGW).
- Interface Endpoint is the **only way** to access AWS services privately from on-prem networks.

## Real World Example

- Private EC2 reads from S3 via **Gateway Endpoint** — zero cost, no NAT GW needed.
- Private EC2 calls `ssm.amazonaws.com` via **Interface Endpoint** — no port 443 to internet needed.

## Production Use Case

- **Always use Gateway Endpoint for S3/DynamoDB** — it's free and more secure.
- **Interface Endpoints for SSM** — enables SSM Session Manager on private instances (no Bastion, no port 22).
- Required for compliance where all traffic must stay within AWS network.

## Exam / Interview Facts

- For on-prem access to AWS services privately → **Interface Endpoint** (via Direct Connect or VPN).
- Gateway Endpoint is not accessible from on-prem — only within the VPC.
- SSM requires **3 Interface Endpoints**: `ssm`, `ssmmessages`, `ec2messages`.

## Common Mistakes

- Using NAT GW to reach S3/DynamoDB — wastes money. Use free Gateway Endpoint.
- Thinking Gateway Endpoint works for all services — it's only S3 and DynamoDB.
- Forgetting that Interface Endpoint costs money per hour per AZ — plan for this.

---

# Site-to-Site VPN & AWS CloudHub

## What to Remember

- **Site-to-Site VPN** = encrypted IPSec tunnel over the **public internet** connecting on-prem to AWS VPC.
- Components:
  - **Customer Gateway (CGW)** = on-prem device (software or hardware). Needs a **public IP** (or NAT-T public IP).
  - **Virtual Private Gateway (VGW)** = AWS side of the VPN — attached to the VPC.
- Must enable **Route Propagation** for VGW in the route table → auto-populates on-prem routes.
- For `ping` to work through VPN: ICMP protocol must be allowed in the **Security Group**.
- **Two tunnels** per VPN connection (HA) — both can be active.
- **Bandwidth**: up to 1.25 Gbps per tunnel.
- **AWS VPN CloudHub** = hub-and-spoke VPN — multiple on-prem sites connect via a single VGW, and sites can communicate with each other through AWS.

## Direct Connect (DX)

- **Physical, dedicated private connection** from on-prem to AWS (via a Direct Connect Location).
- Bypasses the public internet → **consistent low latency, high bandwidth, no jitter**.
- Speeds: 1 Gbps, 10 Gbps, 100 Gbps (or sub-1Gbps via hosted connections through partners).
- **Takes weeks to months to set up** — long lead time for physical provisioning.
- Best paired with **VPN as a failover** for resilience.
- Use for: large data transfers, hybrid workloads, compliance (no public internet), gaming, financial trading.

## VPN vs Direct Connect

| | Site-to-Site VPN | Direct Connect |
|---|---|---|
| Network | Public internet (encrypted) | Private dedicated line |
| Setup time | Minutes/hours | Weeks/months |
| Bandwidth | Up to 1.25 Gbps/tunnel | Up to 100 Gbps |
| Latency | Variable | Consistent, low |
| Cost | Cheaper | More expensive |
| Use case | Quick setup, backup link | Production, high-bandwidth |

## Common Mistakes

- Forgetting to enable Route Propagation on the VGW → routes don't appear in route table.
- Using only VPN for production without a Direct Connect backup — single point of failure.
- Not allowing ICMP in Security Group → `ping` fails even though VPN tunnel is up.

---

# AWS Systems Manager (SSM) — Private EC2 Access

## What to Remember

- **AWS SSM Session Manager** = browser/CLI-based shell access to EC2 instances **without SSH, without port 22, without Bastion Host**.
- Requires:
  1. **SSM Agent** installed on EC2 (pre-installed on Amazon Linux 2, Windows Server AMIs).
  2. **IAM Role** attached to EC2 with `AmazonSSMManagedInstanceCore` policy.
  3. **Network path** to SSM endpoints (either via internet + NAT GW, or via **3 Interface Endpoints** for fully private).
- **3 Interface Endpoints** needed for fully private SSM (no internet access required):
  - `com.amazonaws.<region>.ssm`
  - `com.amazonaws.<region>.ssmmessages`
  - `com.amazonaws.<region>.ec2messages`
- All session activity is **logged in CloudWatch / S3** — full auditability.
- Works with Windows (RDP) and Linux (shell).

## Production Use Case

- Private Windows/Linux EC2 access without opening any inbound ports — zero attack surface.
- Audit trail for all admin commands — compliance (SOC 2, PCI-DSS, HIPAA).
- Replacing Bastion hosts — simpler, more secure, no key management.

## Exam / Interview Facts

- SSM Port: **No inbound ports required** — SSM Agent makes **outbound** connections to SSM endpoints.
- Session Manager ≠ Remote Desktop ≠ SSH. It's a separate protocol via SSM service.
- Can be used to run commands on instances at scale (**Run Command** feature of SSM).

## Common Mistakes

- Forgetting to attach the IAM Role to the EC2 instance — SSM won't register the instance.
- Not creating VPC Interface Endpoints when the instance is private with no internet — SSM agent can't reach SSM service endpoints.
- Assuming SSM Session Manager requires port 22 — it does not.

---

## Quick Reference — Ports & Defaults

| Service / Protocol | Default Port |
|---|---|
| SSH | **22** |
| RDP (Windows) | **3389** |
| HTTP | **80** |
| HTTPS | **443** |
| PostgreSQL (RDS) | **5432** |
| MySQL / Aurora | **3306** |
| MSSQL | **1433** |
| Ephemeral Ports (clients) | **1024–65535** |
| GWLB (GENEVE) | **6081** |

---

## Quick Reference — Key Limits & Defaults

| Resource | Default Limit |
|---|---|
| Elastic IPs per region per account | **5** |
| VPC CIDR range | **`/16` (max) to `/28` (min)** |
| IGWs per VPC | **1** |
| Reserved IPs per subnet | **5** |
| VPCs per region per account | **5** (soft limit) |
| Subnets per VPC | **200** |
| Security Groups per ENI | **5** |
| Rules per Security Group | **60 inbound + 60 outbound** |
| NACLs per VPC | **200** |
| Rules per NACL | **20 (inbound + outbound each)** |

---

## Connectivity Decision Cheat Sheet

| Requirement | Solution |
|---|---|
| Private EC2 → internet (outbound only) | **NAT Gateway** |
| Private EC2 → S3 or DynamoDB | **Gateway Endpoint** (free) |
| Private EC2 → SSM, Secrets Manager, ECR, etc. | **Interface Endpoint** |
| On-prem → AWS services privately | **Interface Endpoint** (via DX or VPN) |
| On-prem → AWS (quick, encrypted) | **Site-to-Site VPN** |
| On-prem → AWS (dedicated, high-bandwidth) | **Direct Connect** |
| VPC ↔ VPC (few VPCs) | **VPC Peering** |
| VPC ↔ VPC (many VPCs / transitive routing) | **Transit Gateway** |
| Private EC2 admin access (no Bastion) | **SSM Session Manager** |
| Admin access to private EC2 (legacy) | **Bastion Host + SSH** |
| Egress traffic inspection / filtering | **Proxy Server or GWLB + Firewall Appliance** |

---

*Revision notes generated from 1st week AWS study material — Anurag Lohar.*
