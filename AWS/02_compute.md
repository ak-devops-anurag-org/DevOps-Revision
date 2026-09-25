# Compute — AWS Revision Notes

## Topics Covered
- EC2 (Elastic Compute Cloud)
- AMI (Amazon Machine Image)
- Auto Scaling Group (ASG)
- ECS (Elastic Container Service)
- AWS Fargate
- EKS (Elastic Kubernetes Service)
- ECR (Elastic Container Registry)
- AWS Lambda

# EC2

## Key Points
- IaaS — virtual server in the cloud (you manage OS and above)
- Choose: OS, CPU, RAM, storage, networking, security group
- **User Data** script runs **once at first launch**, as `root` — used for bootstrapping (install packages, start services)
- **Instance types** naming: `m5.large` → family `m`, generation `5`, size `large`
- **Key pair** = RSA/ED25519; AWS keeps public key, you keep `.pem` private key
- `chmod 0400 key.pem` required before SSH
- **Public IP changes** on every stop/start — use **Elastic IP** for static
- SSH: `ssh -i key.pem ec2-user@<public-ip>` — port **22**
- RDP (Windows): port **3389**
- **EC2 Instance Connect** = browser-based SSH — still needs port 22 open

## Instance Families

| Family | Optimized for | Example |
|---|---|---|
| T, M | General Purpose | Web servers, dev |
| C | Compute (CPU) | Batch, ML inference |
| R, X | Memory | In-memory DB, caches |
| I, D | Storage (IOPS) | Data warehousing |
| P, G | GPU | ML training |

## Access Methods

| Method | Requires |
|---|---|
| SSH with `.pem` key | Port 22 open, key pair |
| EC2 Instance Connect | Port 22 open |
| SSM Session Manager | IAM Role + SSM endpoints, **no port 22** |

## Key Defaults & Limits
- **Elastic IP limit**: 5 per region per account
- Stopping EC2: loses public IP, retains private IP, no compute charge
- Terminating EC2: root EBS deleted by default (`DeleteOnTermination=true`)
- **"Connection timed out"** → Security Group issue
- **"Connection refused"** → app not running / wrong port

## Common Mistakes
- Hardcoding IAM credentials in code — use **IAM Role** attached to instance
- Not setting `chmod 0400` on `.pem` → SSH refuses
- Opening port 22 to `0.0.0.0/0` in production
- Using root account to SSH — use `ec2-user`, `ubuntu`, `centos`

# AMI (Amazon Machine Image)

## Key Points
- Template for launching EC2 (OS + pre-installed software + config)
- **Region-specific** — must copy AMI to another region before using there
- Building: **Launch → Customize → Stop → Create AMI** (auto creates EBS snapshots)
- Types: **Public AMI** (AWS/community), **Custom AMI** (yours), **Marketplace AMI** (third-party, may cost)
- Deleting AMI does **not** auto-delete underlying snapshots — must delete separately
- Sharing AMIs across AWS accounts is supported
- **Golden AMI pattern** — bake everything in, never patch production manually

## Common Mistakes
- Forgetting AMI is region-specific — must copy before using in another region
- Not cleaning up old AMI snapshots — accumulates cost
- Expecting AMI deletion to clean up snapshots automatically

# Auto Scaling Group (ASG)

## Key Points
- Auto launch/terminate EC2 based on demand (scale out/in)
- Define: **Min**, **Desired**, **Max** capacity
- Scale triggers: CPU %, network, ALB request count, custom CloudWatch metrics, schedule
- Automatically replaces **unhealthy instances**
- Works with ALB/NLB — registers/deregisters instances in target groups
- ASG itself has **no extra charge** — pay only for the EC2 instances launched
- **Scale-in protection** can be set on specific instances to prevent termination
- **Cooldown period** — prevents rapid scale oscillation

## Common Mistakes
- Single AZ deployment — no HA; deploy across multiple AZs
- Wrong cooldown → rapid scale in/out oscillation
- Not setting proper min capacity — ASG can scale to zero

# ECS (Elastic Container Service)

## Key Points
- AWS-managed container orchestration service (like Azure AKS, but AWS-native)
- **Two launch types**:

| Launch Type | Infrastructure | You Manage |
|---|---|---|
| **EC2** | EC2 instances in your account | EC2 provisioning, patching |
| **Fargate** | AWS-managed (serverless) | Nothing — just task definition |


- **Task Definition** JSON blueprint for a task — defines container image(s), CPU/memory, port mappings, environment variables, IAM roles, networking mode, volumes. 
- **Task vs Service** = Task → one running instance of a Task Definition. A Service → keeps a desired number of Tasks running continuously, handles replacement of unhealthy tasks. 
- **ECS Cluster** = logical grouping of EC2 instances or Fargate capacity
- EC2 launch type → EC2 must run **ECS Agent** to register in cluster
- **IAM Roles for ECS**:
  - **EC2 Instance Profile** → permissions for the ECS agent itself (pull ECR images, log to CloudWatch)
  - **ECS Task Role** → permissions for the container app (e.g., access S3, RDS)

## ECS + EFS (Data Volumes)
- Mount **EFS** file systems onto ECS tasks for shared persistent storage
- Works with both EC2 and Fargate launch types
- Tasks across any AZ share the same data in EFS
- **S3 cannot be mounted as a file system** — use SDK/API instead

## ECS Auto Scaling
- Uses **AWS Application Auto Scaling**
- Metrics: ECS service CPU %, Memory %, ALB request count per target
- Fargate auto scaling is simpler to set up (serverless — no EC2 to manage)

## Common Mistakes
- Not setting the correct **Task Role** → app can't access AWS services
- Using EC2 launch type when Fargate is simpler — adds unnecessary management overhead
- Trying to mount S3 as file system — not supported

# AWS Fargate

## Key Points
- **Serverless container platform** — no EC2 instances to provision or manage
- Works with **ECS and EKS**
- You only define: CPU, RAM, container image, networking, IAM role
- Pay per task vCPU + memory per second
- Each Fargate task gets its **own ENI** (Elastic Network Interface) with a private IP
- Fargate tasks can use **EFS** for persistent shared storage

# EKS (Elastic Kubernetes Service)

## Key Points
- AWS-managed **Kubernetes** control plane
- Node types: **EC2 worker nodes** (self-managed or managed node groups) or **Fargate** (serverless pods)
- **ECR** = AWS container registry (stores Docker images) — equivalent to Docker Hub
- Use EKS when: you already use Kubernetes, need multi-cloud portability, or have complex orchestration needs
- Use ECS when: AWS-native stack, simpler ops, no existing K8s investment

# AWS Lambda

## Key Points
- **Serverless** Function-as-a-Service (FaaS) — no servers to manage
- Pay per request + compute time; **1M requests/month free tier**
- Max execution time: **15 minutes (900 seconds)**
- Supported runtimes: Node.js, Python, Java, C#, Ruby, Go, Custom Runtime API
- Integrated with most AWS services
- **Increasing RAM → also improves CPU and network**

## Lambda Limits (per region)

| Resource | Limit |
|---|---|
| Memory | 128 MB – 10 GB |
| Max execution time | 900 sec (15 min) |
| Concurrent executions | 1,000 (soft limit, increasable) |
| Environment variables | 4 KB |
| `/tmp` disk space | 512 MB – 10 GB |
| Deployment package (compressed) | 50 MB |
| Deployment package (uncompressed) | 250 MB |

## Cold Starts
- On new invocation: AWS creates execution environment → loads runtime + code → cold start latency
- **Provisioned Concurrency** → pre-warm instances; eliminates cold starts; costs money even when idle
- **Lambda SnapStart** → snapshot pre-initialized state; up to 10x performance improvement; free; available for Java, Python, .NET

## Concurrency & Throttling
- **1,000 concurrent executions** default limit per region
- **Reserved concurrency** — cap a specific function's max concurrent executions
- Throttle behavior:
  - **Synchronous** invocation → returns `ThrottleError 429`
  - **Asynchronous** invocation → retries automatically → **DLQ (Dead Letter Queue)**

## Lambda in VPC
- By default Lambda runs in AWS-owned VPC — cannot reach your private VPC resources
- To access RDS, ElastiCache, private services → configure Lambda with **VPC ID + Subnets + Security Groups**
- Lambda creates an **ENI** in your subnet
- VPC Lambda needs **NAT Gateway** for internet access (or interface endpoints for AWS services)
- **Lambda + RDS Proxy** → connection pooling for RDS (avoids connection exhaustion from many Lambda invocations)

## Common Mistakes
- Running tasks longer than 15 min — use Step Functions, ECS, or EC2 instead
- Forgetting VPC config for Lambda needing private resource access
- Not setting reserved concurrency → one noisy function can eat all 1,000 concurrent slots
- Not using RDS Proxy with Lambda + RDS → too many direct connections
