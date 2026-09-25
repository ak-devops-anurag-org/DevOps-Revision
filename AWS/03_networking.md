# Networking — AWS Revision Notes

---

## Topics Covered
- VPC & CIDR
- Subnets & Route Tables
- Internet Gateway (IGW)
- NAT Gateway
- Security Groups & NACL
- Bastion Host
- VPC Peering
- Transit Gateway
- VPC Endpoints (Gateway & Interface)
- PrivateLink & Endpoint Services
- Site-to-Site VPN & AWS CloudHub
- Direct Connect
- Elastic IP & Public/Private IPs
- Load Balancers (ALB, NLB, GWLB)
- CloudFront (CDN)
- AWS Global Accelerator
- Route 53 (DNS)

---

# VPC (Virtual Private Cloud)

## Key Points
- **Logically isolated network** in AWS — your private section of the cloud
- **One Default VPC per region** per account — CIDR: `172.31.0.0/16`
- Default VPC has: public subnet in each AZ, IGW attached, main route table with internet route, default SG
- VPC CIDR range: **`/16` (max — 65,536 IPs)** to **`/28` (min — 16 IPs)**
- **5 IPs reserved per subnet** — first 4 + last 1 (network addr, router, DNS, future, broadcast)
- VPC is **Regional** — spans all AZs in the region
- VPC itself is **free** — you pay for resources inside

## Private IP Ranges (RFC 1918)

| Range | CIDR | Use |
|---|---|---|
| `10.0.0.0 – 10.255.255.255` | `/8` | Large corporate |
| `172.16.0.0 – 172.31.255.255` | `/12` | AWS Default VPC |
| `192.168.0.0 – 192.168.255.255` | `/16` | Home networks |

- `0.0.0.0/0` = all IPv4 (internet catch-all in route tables)
- `8.8.8.8` = Google public DNS (example internet destination)

---

# Subnets & Route Tables

## Subnet Key Points
- **Single AZ** — cannot span AZs (one subnet = one AZ)
- **Public subnet** = has a route to IGW in its route table
- **Private subnet** = no route to IGW
- Subnet attributes: ID, CIDR, available IPs, auto-assign public IP (yes/no)

## Reserved IPs — Example for `10.0.0.0/24`
- `10.0.0.0` — Network address
- `10.0.0.1` — VPC Router
- `10.0.0.2` — DNS server
- `10.0.0.3` — Future use
- `10.0.0.255` — Broadcast (reserved, not used)
- → **251 usable IPs** in a `/24`

## Route Table Key Points
- Contains: **destination CIDR → target** (IGW, NAT GW, VPC Endpoint, etc.)
- **Longest prefix wins** (most specific route)
- **Main Route Table**: default for subnets not explicitly associated
- **Explicit association**: manually assign subnet to a specific route table
- **Route propagation**: auto-populate routes from VGW/Direct Connect/TGW attachment
- **Edge association**: for gateway-facing advanced routing

---

# Internet Gateway (IGW)

## Key Points
- Gives VPC resources access to the internet
- **1 IGW per VPC** — attached at VPC level (not subnet level)
- **Free** — only pay for egress data transfer
- Horizontally scaled, redundant, HA — AWS managed
- For internet access: resource needs **public/Elastic IP** + route to IGW in route table
- IGW performs **NAT** (maps public IP ↔ private IP)

## Common Mistakes
- Creating IGW but forgetting to **attach it to VPC**
- Forgetting `0.0.0.0/0 → IGW` route in public subnet route table
- Thinking IGW alone gives internet access — also need a public IP

---

# NAT Gateway

## Key Points
- Gives **private subnet instances outbound-only internet access** (no inbound initiated from internet)
- Must be in a **public subnet** + needs an **Elastic IP**
- Traffic flow: `Private EC2 → NAT GW → IGW → Internet`
- Private subnet route table: `0.0.0.0/0 → NAT GW`
- **AWS-managed** — auto-scales bandwidth (5–100+ Gbps), HA within one AZ
- **AZ-scoped** — deploy **one NAT GW per AZ** for HA
- **Not free** — charged per hour + per GB processed
- NAT Instance (old) = EC2-based NAT; self-managed, cheaper, no auto-scale — mostly obsolete

## Common Mistakes
- One NAT GW for entire VPC → AZ failure = internet loss for private subnets
- Forgetting to update private subnet route table to point to NAT GW
- Using NAT GW to reach S3/DynamoDB — use **Gateway Endpoint** (free)

---

# Security Groups (SG) vs NACL

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance (ENI) | Subnet |
| Stateful / Stateless | **Stateful** | **Stateless** |
| Rules | Allow only (implicit deny) | Allow **and** Deny |
| Rule evaluation | All rules evaluated | Lowest number wins |
| Scope | Attached resource only | All resources in subnet |

## Security Group Key Points
- **Stateful**: inbound allow → return outbound auto-allowed (and vice versa)
- SG lives **outside EC2** — instance never sees blocked packets
- Locked to **region/VPC** — can't use SG from one VPC in another
- Can reference another SG as source — dynamic, no IP management needed
- Default: all inbound blocked, all outbound allowed

## NACL Key Points
- **Stateless**: must define both inbound AND outbound rules
- **Ephemeral ports** (1024–65535) — NACL must explicitly allow these for return traffic
- NACL can **Deny** specific IPs — SG cannot
- Lower rule number = higher priority

## Debugging Traffic Issues
- **"Connection timed out"** → SG or NACL blocking
- **"Connection refused"** → app not running / wrong port
- Enable **VPC Flow Logs** → look for `REJECT` (NACL explicitly rejected) vs no log entry (SG dropped)
- Temporarily open NACL to all → if works → NACL was the issue; else → check SG

---

# Bastion Host

## Key Points
- **Jump server** in the public subnet — single entry point to private EC2 instances
- From Bastion → SSH into private instances via private IP
- Private EC2 SG: allow port 22 **from Bastion SG only** (not from internet)
- **Elastic IP** recommended on Bastion — stable IP for whitelisting
- Being replaced by **SSM Session Manager** (no port 22 needed)

```
Internet → Bastion SG (port 22 open) → Private SG (port 22 from Bastion SG only)
```

## Common Mistakes
- Opening port 22 on private EC2 to `0.0.0.0/0` — defeats the purpose
- Not restricting Bastion SG to known corporate IP ranges

---

# VPC Peering

## Key Points
- **Private connection** between two VPCs — works across accounts and regions
- **Non-transitive**: A↔B and B↔C peered ≠ A can reach C; must create A↔C peering separately
- **No CIDR overlap** allowed between peered VPCs
- Creating peering alone is **not enough** — must add routes in **both VPCs' route tables**
- N VPCs needs N*(N-1)/2 peering connections — use **Transit Gateway** for many VPCs

---

# Transit Gateway (TGW)

## Key Points
- **Hub-and-spoke** network transit hub — connects multiple VPCs, on-prem (VPN, Direct Connect)
- **Transitive routing** — A → TGW → B → TGW → C (A can reach C)
- **Regional resource** — supports cross-region TGW peering
- Route tables on TGW control which VPCs can talk to which (isolation possible)
- **Only AWS service supporting IP Multicast**
- Supports: VPC, VPN, Direct Connect Gateway attachments

| | VPC Peering | Transit Gateway |
|---|---|---|
| Transitive routing | ❌ No | ✅ Yes |
| Scale | Complex mesh | Hub-and-spoke |
| Cost | Data transfer only | Per attachment + data |
| IP Multicast | ❌ | ✅ |

## Common Mistakes
- Using VPC Peering for 10+ VPCs — becomes unmanageable
- Not designing TGW route tables for env isolation (prod vs non-prod)
- Forgetting TGW is not free — per attachment per hour

---

# VPC Endpoints

## Key Points
- **Private connection** from VPC to AWS services — no IGW, NAT GW, or public internet

| Type | How | Cost | Services |
|---|---|---|---|
| **Gateway Endpoint** | Route table entry | **Free** | **S3 and DynamoDB only** |
| **Interface Endpoint (PrivateLink)** | Creates ENI with private IP | Paid (hourly + data) | Most AWS services (SSM, ECR, SQS, etc.) |

- Gateway Endpoint: route table change only — no ENI, no IP, not accessible from on-prem
- Interface Endpoint: ENI in your subnet — accessible from on-prem (via VPN/Direct Connect)
- **Interface Endpoint is the only way** to reach AWS services privately from on-prem
- SSM requires **3 Interface Endpoints**: `ssm`, `ssmmessages`, `ec2messages`

## Common Mistakes
- Using NAT GW to reach S3/DynamoDB — use free Gateway Endpoint
- Thinking Gateway Endpoint works for all services — S3 and DynamoDB only
- Forgetting Interface Endpoints cost per AZ per hour
- Expecting Gateway Endpoint to work from on-prem — it doesn't

---

# PrivateLink & Endpoint Services

## Key Points
- **Endpoint Service (PrivateLink Provider)** = share your own service privately to other VPCs/accounts without exposing to internet
- Provider setup: host app behind **Network Load Balancer** → create Endpoint Service → whitelist consumer accounts
- Consumer setup: create Interface Endpoint pointing to provider's service name → appears as local private IP
- Neither side can see the other's full network — traffic is restricted to that specific app only
- **Eliminates need for VPN or peering** to share services across accounts/VPCs

---

# Site-to-Site VPN & AWS CloudHub

## Key Points
- **Encrypted IPSec tunnel** over the **public internet** connecting on-prem to AWS VPC
- Components:
  - **Customer Gateway (CGW)** = on-prem VPN device (needs public IP or NAT-T public IP)
  - **Virtual Private Gateway (VGW)** = AWS side, attached to VPC
- Enable **Route Propagation** for VGW in route table → auto-populates on-prem routes
- ICMP must be allowed in SG for `ping` to work across VPN
- Two tunnels per VPN connection (HA) — both can be active simultaneously
- Bandwidth: up to **1.25 Gbps per tunnel**
- **AWS VPN CloudHub** = hub-and-spoke VPN — multiple on-prem sites via one VGW; sites can communicate through AWS

## Common Mistakes
- Forgetting to enable Route Propagation → on-prem routes don't appear in route table
- Using VPN only without Direct Connect backup for production
- Not allowing ICMP in SG → `ping` fails even though VPN tunnel is up

---

# Direct Connect (DX)

## Key Points
- **Physical, dedicated private line** from on-prem to AWS (via Direct Connect location/partner)
- Bypasses public internet → **consistent low latency, high bandwidth, no jitter**
- Speeds: **1 Gbps, 10 Gbps, 100 Gbps** (sub-1Gbps via hosted connections through partners)
- Takes **weeks to months** to set up (physical provisioning)
- Best paired with **VPN as failover**

| | Site-to-Site VPN | Direct Connect |
|---|---|---|
| Network | Public internet (encrypted) | Private dedicated line |
| Setup | Minutes/hours | Weeks/months |
| Bandwidth | Up to 1.25 Gbps/tunnel | Up to 100 Gbps |
| Latency | Variable | Consistent, low |
| Use case | Quick, backup, lower cost | Production, high-bandwidth |

---

# Elastic IP & Public/Private IPs

## Key Points
- **Public IP**: assigned at launch if subnet has `Auto-assign public IP = true`; **changes on every stop/start**
- **Private IP**: stays for the lifetime of the instance
- **Elastic IP (EIP)**: static, persistent public IPv4 — you own it
- **Limit: 5 EIPs per region per account** (soft limit)
- EIP is **billed when not associated** with a running instance → release unused EIPs
- Best practice: avoid EIPs — use **DNS names (Route 53 Alias)** instead
- EIPs are region-specific — cannot move to another region directly

---

# Load Balancers

## Key Points
- AWS-managed — AWS handles HA, upgrades, maintenance
- **Health checks** are critical — LB routes only to healthy targets
- **Listener**: port + protocol the LB listens on (e.g., 443 HTTPS)
- **Target Groups**: group of resources (EC2, Lambda, ECS, IPs)
- **SSL termination at ALB** — backend can use HTTP 80
- Client → LB: **HTTP 80** or **HTTPS 443**; LB → EC2: typically **HTTP 80**

## LB Types

| Type | Layer | Protocols | Use Case |
|---|---|---|---|
| **ALB** | 7 (Application) | HTTP, HTTPS, WebSocket | Web apps, microservices, path/host routing |
| **NLB** | 4 (Network) | TCP, UDP, TLS | Low latency, static IP, gaming, IoT |
| **GWLB** | 3 (Network) | GENEVE (port 6081) | Inline 3rd party firewalls, IDS/IPS |

- **Classic LB (CLB)** → deprecated, avoid
- **ALB routing rules**: path (`/api/*`), hostname (`api.example.com`), headers, query strings
- **NLB gets static IP per AZ** — useful for IP whitelisting
- **GWLB** port: **6081 (GENEVE)**
- **Cross-zone load balancing**: ALB = **on by default**; NLB/GWLB = **off by default** (costs money on NLB if enabled)
- **Sticky sessions** (session affinity): ALB uses cookies to route same client to same backend

## Common Mistakes
- Opening EC2 SG to internet directly — should only allow from LB's SG
- Wrong health check path → LB marks all instances unhealthy
- Not enabling ALB access logs — critical for debugging
- Forgetting NLB cross-zone load balancing is off by default

---

# CloudFront (CDN)

## Key Points
- **Content Delivery Network** — caches content at **Edge Locations** globally (200+ PoPs)
- **Reduces latency** by serving content from nearest edge location
- **Static content**: always cached (configurable TTL)
- **Dynamic content**: can be cached for short TTL (e.g., `/api/products` for 60 sec)
- Even non-cacheable traffic benefits: edge TLS termination, AWS WAF, Shield DDoS protection, AWS network routing
- **DDoS Protection** built-in via AWS Shield Standard (free)

## Origins CloudFront Can Point To
- **S3 bucket** (with OAC — Origin Access Control — so only CloudFront can access private S3)
- **Application Load Balancer**
- **EC2 instance**
- **API Gateway**
- Any HTTP endpoint

## CloudFront + S3 (Private Bucket)
- User → CloudFront → **Origin Access Control (OAC)** → Private S3
- S3 bucket policy allows only CloudFront to access it (using OAC)
- Public S3 URL remains inaccessible

## CloudFront vs S3 Cross-Region Replication

| | CloudFront | S3 CRR |
|---|---|---|
| Coverage | All edge locations globally | Specific region(s) only |
| Update lag | Cached until TTL | Near real-time |
| Write | Read-only (cache) | Read + Write |
| Best for | Global static content delivery | Low latency access in few regions |

## Cache Invalidation
- Cached content at edge doesn't update until **TTL expires**
- To force refresh before TTL: **invalidate the cache** (charges apply per invalidation path)

## Geo Restriction
- **Allowlist**: only specific countries can access distribution
- **Blocklist**: specific countries are blocked
- Country detection via **3rd party Geo-IP database**

---

# AWS Global Accelerator

## Key Points
- Routes traffic through **AWS global network** (not public internet) for lower latency
- Creates **2 Anycast static IPs** for your application (stable IPs globally)
- Traffic flows: User → Nearest Edge Location → AWS network → Target region
- Works with: EC2, ALB, NLB (public or private)
- Provides **instant failover** across regions

## CloudFront vs Global Accelerator

| | CloudFront | Global Accelerator |
|---|---|---|
| Protocol | HTTP/HTTPS | TCP, UDP, HTTP |
| Caching | ✅ Yes | ❌ No |
| Use case | Static/dynamic content delivery | Non-HTTP, gaming (UDP), IoT, VoIP |
| IP | Dynamic (CDN) | **2 Static Anycast IPs** |
| Failover | DNS-based | **Instant, deterministic** |

---

# Route 53 (DNS)

## Key Points
- AWS **managed DNS service + domain registrar**
- **Global service** — not region-specific
- **Only AWS service with 100% availability SLA**
- Why "53"? — reference to traditional DNS port 53

## DNS Record Types

| Record | Points to | Notes |
|---|---|---|
| **A** | IPv4 address | Standard hostname → IP |
| **AAAA** | IPv6 address | |
| **CNAME** | Another hostname | **Cannot use at zone apex** (e.g., `example.com`) |
| **NS** | Name servers | Delegation to hosted zone |
| **Alias** | AWS resource | Works at zone apex; **free** queries; preferred over CNAME for AWS resources |

- **Alias cannot point to EC2 DNS name** — only works for: ELB, CloudFront, API GW, S3 website, etc.
- **TTL**: high TTL = fewer queries (cheap), slower updates; low TTL = more queries (costly), faster updates

## Routing Policies

| Policy | Use Case |
|---|---|
| **Simple** | Single resource, no health check |
| **Weighted** | A/B testing, gradual traffic shift (10%/90%) |
| **Latency** | Route to lowest latency region |
| **Failover** | Active-passive HA (primary + failover) |
| **Geolocation** | Route by user's country/continent |
| **Geoproximity** | Route by geographic proximity + bias |
| **Multi-value** | Return multiple IPs, each with health check |

## Health Checks
- Monitor: endpoint, other health checks (calculated), CloudWatch alarms
- Trigger failover routing if primary fails
- **Health checks must be attached** to failover records for automatic failover

## Common Mistakes
- Using CNAME at zone apex (`example.com`) — fails; use **Alias** instead
- Setting very low TTL during normal operation — high query cost
- Forgetting to attach health checks to failover records

---

# Connectivity Decision Cheat Sheet

| Requirement | Solution |
|---|---|
| Private EC2 → internet (outbound only) | **NAT Gateway** |
| Private EC2 → S3 or DynamoDB | **Gateway Endpoint** (free) |
| Private EC2 → SSM, ECR, Secrets Manager | **Interface Endpoint** |
| On-prem → AWS services privately | **Interface Endpoint** (via DX or VPN) |
| On-prem → AWS (quick/encrypted) | **Site-to-Site VPN** |
| On-prem → AWS (dedicated/high-bandwidth) | **Direct Connect** |
| Few VPCs ↔ VPCs | **VPC Peering** |
| Many VPCs / transitive routing | **Transit Gateway** |
| Admin access to private EC2 (no Bastion) | **SSM Session Manager** |
| Admin access to private EC2 (legacy) | **Bastion Host + SSH** |
| Share app across accounts privately | **PrivateLink Endpoint Service** |
| Global static content delivery + caching | **CloudFront** |
| Global low-latency non-HTTP (gaming, IoT) | **Global Accelerator** |
| Egress traffic inspection / filtering | **Proxy Server or GWLB + Firewall** |
