# Database — AWS Revision Notes

## Topics Covered
- RDS (Relational Database Service)
- RDS Read Replicas
- RDS Multi-AZ
- Aurora
- DynamoDB

# RDS (Relational Database Service)

## Key Points
- AWS-managed relational DB — you don't manage OS, DB engine installation, or patching
- Supported engines: **PostgreSQL, MySQL, MariaDB, Oracle, Microsoft SQL Server**
- **AWS handles**: hardware, patching, backups, monitoring, storage management
- **You handle**: schema, queries, parameter groups, connection strings
- **Storage Auto Scaling** — RDS automatically increases storage when running low (set max threshold)
- Default port:
  - PostgreSQL → **5432**
  - MySQL/MariaDB → **3306**
  - MSSQL → **1433**
  - Oracle → **1521**

## RDS vs Self-Managed DB

| Feature | RDS | Self-Managed (EC2) |
|---|---|---|
| OS access | ❌ No | ✅ Yes |
| Patching | AWS handles | You handle |
| Backups | Automated | Manual |
| HA setup | Click-based Multi-AZ | Complex manual setup |
| Cost | Higher | Lower (but ops overhead) |

## Read Replicas vs Multi-AZ

| | Read Replica | Multi-AZ |
|---|---|---|
| **Purpose** | Read scaling | High Availability |
| **Replication** | **ASYNC** | **SYNC** |
| **Failover** | Manual (you promote) | **Automatic** |
| **Endpoint** | Different endpoint | **Same endpoint** (DNS updates) |
| **Use for** | Reporting, analytics | Production HA |
| **Cross-region** | ✅ Yes | ❌ No (within region only) |

- Multi-AZ standby **cannot serve read traffic** — it's only a hot standby
- Read Replica **can be promoted** to become a standalone DB (but connection strings must change)
- Read Replica **can be set up as Multi-AZ** (for DR of the replica itself)
- **Network cost**: cross-AZ data transfer has cost. Exception: **same-region Read Replica replication is free**

## Single AZ → Multi-AZ Migration
- **Zero downtime** — no need to stop the DB
- Just modify the DB → AWS takes a snapshot → sets up SYNC replication behind the scenes

## Automated Backups
- Enabled by default — daily snapshots + transaction logs (point-in-time restore)
- Retention: 1–35 days (default 7 days)
- Restore → creates a **new RDS instance** (not in-place)

## Common Mistakes
- Thinking Multi-AZ standby serves reads — it doesn't
- Forgetting Read Replica failover is manual — you must promote it
- Not setting proper **DB parameter groups** — defaults aren't production-ready
- Forgetting cross-AZ Read Replica replication has a network cost (only same-region is free)

# Aurora

## Key Points
- AWS-managed MySQL/PostgreSQL-compatible DB engine — **not a standard MySQL**
- **5x faster** than standard MySQL; **3x faster** than PostgreSQL
- **6 copies of data** across **3 AZs** automatically — high durability
- Storage auto-scales from **10 GB to 128 TB**
- Up to **15 Read Replicas** (vs 5 for standard RDS)
- Failover is **instant** (< 30 seconds) — uses shared storage architecture
- **Aurora Serverless** → auto-scales capacity based on demand; good for unpredictable workloads
- **Aurora Global Database** → primary region + up to 5 secondary regions; RPO < 1 sec, RTO < 1 min
- More expensive than standard RDS (~20% more) — but more capable

# DynamoDB

## Key Points
- AWS-managed **NoSQL** database — not relational (no SQL joins)
- **Fully serverless** — no servers to manage, scales automatically
- **Multi-AZ replication** built-in — highly available by default
- Performance: **single-digit millisecond** latency at any scale
- Scale: millions of requests/sec, trillions of rows, hundreds of TB
- **Max item size: 400 KB**
- Integrated with **IAM** for security and access control

## DynamoDB Basics
- Made of **Tables** (not databases)
- Each table has a **Primary Key** — must be defined at creation (cannot change)
  - **Partition Key** only (Hash key) — or
  - **Partition Key + Sort Key** (composite key)
- Each item = row (flexible schema — attributes can vary per item)
- **Supports**: String, Number, Binary, Boolean, Null, List, Map, Sets

## Read/Write Capacity Modes

| Mode | How | Cost | Use Case |
|---|---|---|---|
| **Provisioned** (default) | Set RCU/WCU in advance | Pay for provisioned capacity | Predictable, steady workloads |
| **On-Demand** | Auto scales instantly | Pay per request ($$$ more) | Unpredictable, spiky workloads |

- **RCU** = Read Capacity Unit (1 strongly consistent read of ≤ 4 KB/sec)
- **WCU** = Write Capacity Unit (1 write of ≤ 1 KB/sec)
- Can switch between modes (with some cooldown constraints)

## DynamoDB vs RDS

| | DynamoDB | RDS |
|---|---|---|
| Type | NoSQL (key-value / document) | Relational (SQL) |
| Schema | Flexible (schema-less) | Fixed schema |
| Joins | ❌ No | ✅ Yes |
| Scaling | Automatic, horizontal | Vertical (+ Read Replicas) |
| Latency | Single-digit ms | Higher |
| Serverless | ✅ Yes | ❌ No (unless Aurora Serverless) |
| Use when | High scale, simple access patterns | Complex queries, relationships |

## Common Mistakes
- Designing DynamoDB like a relational DB — access patterns must be designed upfront
- Choosing wrong capacity mode — On-Demand for predictable traffic is expensive
- Item > 400 KB → DynamoDB rejects it; use S3 for large objects, store S3 reference in DynamoDB
- Using Scan instead of Query — full table scan, expensive and slow
