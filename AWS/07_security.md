# Security — AWS Revision Notes

---

## Topics Covered
- IAM (Identity & Access Management)
- IAM Roles & Policies
- MFA & Access Keys
- S3 Security & Encryption
- KMS (Key Management Service)
- SSM Session Manager (Secure Access)

---

# IAM (Identity & Access Management)

## Key Points
- **Global service** — users, groups, roles, policies are not region-specific
- Components: **Users, Groups, Roles, Policies**
- **Root account** = full access, cannot be restricted — should NEVER be used for day-to-day work
- New IAM user has **zero permissions** by default
- Permissions come from **Policies** only

## IAM Components

| Entity | What it is | Used for |
|---|---|---|
| **User** | Person or service identity | Human logins, programmatic access |
| **Group** | Collection of users | Assign policies at scale |
| **Role** | Assumable identity with permissions | AWS services, cross-account access |
| **Policy** | JSON document defining permissions | Attached to users, groups, or roles |

## IAM Policies
- **Inline policy**: attached directly to a single user/role
- **Managed policy**: standalone, can be attached to multiple users/groups/roles
- **Group policy**: attached to a group, inherited by all group members
- Policy structure: **Effect** (Allow/Deny) + **Action** (API call) + **Resource** (ARN)
- **Deny always overrides Allow**

## IAM Roles — Two Parts
- **Permission Policy** → what can this role do?
- **Trust Policy** → who can assume this role? (AWS service, user, account)
- Use Roles for: EC2 accessing S3, Lambda calling DynamoDB, cross-account, CI/CD (OIDC)

## Access Keys
- Used for **programmatic access** (CLI, SDK)
- `aws configure` → stores Access Key ID, Secret Access Key, region, output format
- Access key inherits all permissions of the IAM user/role it belongs to
- **Never share access keys**; rotate regularly
- **Never hardcode in code** — use IAM Roles or environment variables

## MFA (Multi-Factor Authentication)
- Strongly recommended on **root** and all **admin IAM users**
- Options: Google Authenticator, Authy, hardware key (YubiKey), etc.

## IAM Security Tools
- **IAM Credentials Report** → account-level CSV of all users + credential status (MFA, key age)
- **IAM Access Advisor** → shows services a user/role has accessed and when → use for least-privilege audit

## Best Practices
- Never use root account for day-to-day — create an admin IAM user
- Assign permissions to **groups**, not individuals
- Use **Roles** (not access keys) for AWS services (EC2, Lambda, ECS)
- Rotate access keys regularly
- Enable **MFA** on privileged accounts
- Apply **least privilege** — only grant what's needed
- Never share access keys or secret access keys

## AWS CloudShell
- Browser-based terminal in AWS Console
- Inherits permissions of the logged-in IAM user/role
- **Not available in all regions**
- Pre-installed with AWS CLI; no need to configure separately

---

# S3 Security

## Security Layers

| Layer | Mechanism |
|---|---|
| **IAM Policy** | Which S3 API calls a user/role can make |
| **Bucket Policy** | JSON policy on the bucket (allow/deny specific accounts, public) |
| **Object ACL** | Per-object permissions (mostly deprecated) |
| **Block Public Access** | Account/bucket level setting — blocks all public access by default |

- EC2 accessing S3 → **IAM Role** on EC2 (not access keys)
- Making S3 bucket public: disable Block Public Access + add bucket policy with `s3:GetObject` Allow

---

# S3 Encryption

| Method | Key Managed By | Notes |
|---|---|---|
| **SSE-S3** | AWS (default) | AES-256; enabled by default; no user key control |
| **SSE-KMS** | AWS KMS | Audit key usage via CloudTrail; KMS API call per object access; potential KMS throttling |
| **SSE-C** | Customer | Must send key with every request; HTTPS mandatory; AWS does not store key |
| **Client-Side** | Customer (pre-upload) | Encrypt before upload; AWS only stores ciphertext |

- **SSE-KMS advantage**: user control over keys + full audit trail via CloudTrail
- **SSE-KMS limitation**: each upload/download makes a KMS API call → can hit KMS limits at high throughput
- **SSE-C**: must include key in every request header; AWS never stores it
- **HTTPS/TLS** — enforce via bucket policy requiring `aws:SecureTransport` condition

---

# KMS (Key Management Service)

## Key Points
- **Managed key service** — create, rotate, manage, and audit encryption keys
- Integrated with most AWS services (S3 SSE-KMS, EBS, RDS, etc.)
- **CloudTrail** logs every KMS API call — full audit trail of who decrypted what and when
- **CMK** (Customer Managed Key) → you control key policy and rotation
- **AWS Managed Key** → AWS creates and rotates automatically for each service
- **Key rotation**: CMKs can be auto-rotated every year (new key material, same key ID)
- KMS API calls count toward **KMS throttling limits** — important for high-throughput SSE-KMS use cases

---

# SSM Session Manager (Secure Access)

## Key Points
- Browser/CLI-based shell access to EC2 instances — **no SSH, no port 22, no Bastion Host**
- Requirements:
  1. **SSM Agent** installed on EC2 (pre-installed on Amazon Linux 2, Windows Server AMIs)
  2. **IAM Role** on EC2 with `AmazonSSMManagedInstanceCore` policy
  3. **Network path** to SSM service endpoints (internet via NAT GW, or **3 Interface Endpoints** for fully private)
- **3 Interface Endpoints** for fully private SSM:
  - `com.amazonaws.<region>.ssm`
  - `com.amazonaws.<region>.ssmmessages`
  - `com.amazonaws.<region>.ec2messages`
- All session activity logged to **CloudWatch Logs / S3** — full auditability (compliance: SOC2, PCI-DSS)
- **No inbound ports required** — SSM Agent makes outbound connections only
- Replaces Bastion Host — simpler, more secure, no key management

## Common Mistakes
- Forgetting to attach IAM Role to EC2 — SSM won't register the instance
- Not creating Interface Endpoints for private EC2 with no internet → SSM agent can't reach SSM
- Assuming SSM Session Manager requires port 22 — it does not
