# Top 50 Terraform Interview Questions — Infrastructure & Security Focus

> **Audience**: Infrastructure / Platform / DevOps engineers interviewing for roles in highly secure, mission-critical environments.
> **Emphasis**: Security, state management, enterprise best practices, and real-world incident handling.

---

## Table of Contents

1. [Core Concepts & Architecture](#1-core-concepts--architecture)
2. [State Management & Backends](#2-state-management--backends)
3. [Security & Secrets Management](#3-security--secrets-management)
4. [Modules & Code Organisation](#4-modules--code-organisation)
5. [Providers & Resources](#5-providers--resources)
6. [Workspaces, Environments & Pipelines](#6-workspaces-environments--pipelines)
7. [Advanced HCL & Functions](#7-advanced-hcl--functions)
8. [Drift Detection, Import & Disaster Recovery](#8-drift-detection-import--disaster-recovery)
9. [Enterprise & Governance](#9-enterprise--governance)
10. [Real-World Scenarios & Troubleshooting](#10-real-world-scenarios--troubleshooting)

---

## 1. Core Concepts & Architecture

### Q1. What is Terraform, and how does it differ from configuration management tools like Ansible?

Terraform is a **declarative Infrastructure-as-Code (IaC)** tool that provisions and manages cloud resources through provider APIs. Unlike Ansible (which is primarily imperative and focuses on configuring existing servers), Terraform:

- Maintains a **state file** to track real-world resource mappings.
- Uses a **plan → apply** workflow so changes are reviewed before execution.
- Excels at **lifecycle management** (create, update, destroy) of infrastructure rather than OS-level configuration.

---

### Q2. Explain the Terraform workflow: `init → plan → apply → destroy`.

| Phase     | Purpose                                                                       |
| --------- | ----------------------------------------------------------------------------- |
| `init`    | Downloads providers/modules, configures the backend, initialises the working directory. |
| `plan`    | Compares desired state (HCL) with current state (state file) and produces an execution plan. |
| `apply`   | Executes the plan after approval — creates, modifies, or deletes resources.  |
| `destroy` | Tears down all resources tracked in the state file (inverse of apply).       |

**Security tip**: Always run `plan` in CI and require human/policy approval before `apply` in production.

---

### Q3. What is the Terraform Dependency Graph and why is it important?

Terraform builds a **Directed Acyclic Graph (DAG)** of all resources and data sources. This graph:

- Determines the **order of creation and destruction**.
- Enables **parallelism** — independent resources are provisioned concurrently.
- Surfaces **implicit dependencies** (via attribute references) and **explicit dependencies** (`depends_on`).

Use `terraform graph | dot -Tpng > graph.png` to visualise.

---

### Q4. What is the difference between declarative and imperative IaC?

- **Declarative** (Terraform): You define the *desired end state*. The tool figures out *how* to get there.
- **Imperative** (scripts, some Ansible playbooks): You define *step-by-step instructions* to reach a state.

Declarative IaC is preferred in critical environments because it is **idempotent**, **auditable**, and produces a predictable `plan` diff.

---

### Q5. What are Terraform Providers?

Providers are **plugins** that translate HCL resource definitions into API calls for a specific platform (AWS, Azure, GCP, Kubernetes, etc.). Each provider:

- Has its own **versioning** (`required_providers` block).
- Must be **initialised** via `terraform init`.
- Can be **locked** in `.terraform.lock.hcl` to ensure reproducible builds.

**Best practice**: Pin provider versions to minor (`~> 5.0`) in enterprise to avoid breaking changes.

---

## 2. State Management & Backends

### Q6. What is the Terraform state file and why is it critical?

The state file (`terraform.tfstate`) is a **JSON mapping** between your HCL configuration and real-world resources. It stores:

- Resource IDs, attributes, and metadata.
- Dependency ordering information.
- Sensitive output values.

**If the state is lost or corrupted, Terraform loses track of all managed resources** — making it one of the most critical assets in your infrastructure pipeline.

---

### Q7. Why should you never store the state file locally in production?

- **No locking** — concurrent runs can corrupt the state.
- **No encryption at rest** — secrets embedded in state are exposed.
- **No versioning** — accidental deletion or corruption is irrecoverable.
- **No collaboration** — team members cannot share state.

Always use a **remote backend** (S3 + DynamoDB, Azure Blob + lease, GCS, Terraform Cloud).

---

### Q8. How do you configure a secure remote backend with S3?

```hcl
terraform {
  backend "s3" {
    bucket         = "myorg-tf-state-prod"
    key            = "network/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true                        # SSE-S3 or SSE-KMS
    kms_key_id     = "arn:aws:kms:..."           # CMK for encryption
    dynamodb_table = "tf-state-lock"             # State locking
    acl            = "private"
  }
}
```

**Security checklist**:
- Enable **bucket versioning** for rollback.
- Restrict bucket access via **IAM policies** and **bucket policies** (deny public access).
- Enable **access logging** and **CloudTrail** on the bucket.
- Use a **separate AWS account** for state storage in multi-account setups.

---

### Q9. What is state locking and why is it essential?

State locking **prevents concurrent writes** to the state file. Without locking, two simultaneous `terraform apply` runs can:

- Overwrite each other's changes.
- Leave resources in an inconsistent half-created state.

DynamoDB (AWS), blob leases (Azure), or Terraform Cloud handle locking automatically. If a lock is stuck, use `terraform force-unlock <LOCK_ID>` — with extreme caution.

---

### Q10. How do you handle a corrupted or diverged state file?

1. **Restore from versioned backup** (S3 versioning, Azure blob snapshots).
2. Use `terraform state pull` and `terraform state push` for manual repair.
3. **Re-import** resources with `terraform import <resource> <id>`.
4. As a last resort, remove from state with `terraform state rm` and re-import.

**Enterprise practice**: Always enable state file versioning and have runbooks for state recovery.

---

### Q11. What is `terraform state mv` and when do you use it?

`terraform state mv` **renames or relocates** a resource within the state without destroying and recreating it.

**Use cases**:
- Refactoring module structures.
- Renaming a resource.
- Moving a resource into or out of a module.

```bash
terraform state mv aws_instance.old_name aws_instance.new_name
terraform state mv module.old_module.aws_s3_bucket.this module.new_module.aws_s3_bucket.this
```

> In Terraform 1.1+, use the `moved` block in HCL for declarative, peer-reviewed refactoring.

---

### Q12. What are the risks of `terraform state rm`?

`terraform state rm` removes a resource from state **but does NOT delete it from the cloud**. Risks:

- The resource becomes **unmanaged** — configuration drift goes undetected.
- If someone later runs `terraform apply`, Terraform may try to **recreate** it, causing conflicts.

**Use only** when intentionally handing off management to another state or manual control.

---

## 3. Security & Secrets Management

### Q13. How do you manage secrets in Terraform securely?

**Never hardcode secrets in `.tf` files or `terraform.tfvars`**. Best practices:

| Method | Details |
|--------|---------|
| **Environment variables** | `TF_VAR_db_password` — keeps secrets out of code. |
| **Vault provider** | Dynamically fetch secrets from HashiCorp Vault at plan/apply time. |
| **AWS Secrets Manager / SSM Parameter Store** | Use `data` sources to read secrets. |
| **`sensitive = true`** | Mark variables/outputs as sensitive to suppress CLI output. |
| **SOPS / age** | Encrypt var files at rest, decrypt in CI pipeline only. |

**Critical**: Even with `sensitive = true`, secrets are stored **in plain text in the state file** — always encrypt state at rest.

---

### Q14. How does `sensitive = true` work, and what are its limitations?

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

- **Hides** the value from `terraform plan` and `terraform apply` CLI output.
- **Does NOT encrypt** the value in the state file.
- Propagates sensitivity — any output referencing it must also be marked `sensitive`.
- **Limitation**: Logs in CI runners or crash dumps may still expose the value.

---

### Q15. How do you prevent secrets from leaking into version control?

- Add `*.tfvars`, `.terraform/`, `terraform.tfstate*` to `.gitignore`.
- Use **pre-commit hooks** (e.g., `gitleaks`, `tfsec`, `trufflehog`) to scan for secrets.
- Store secrets in a **Vault / secrets manager** and reference them via data sources.
- Enable **branch protection** and **CODEOWNERS** on Terraform repos.

---

### Q16. How do you securely reference secrets from HashiCorp Vault?

```hcl
provider "vault" {
  address = "https://vault.internal:8200"
  # Auth via VAULT_TOKEN env var or AppRole in CI
}

data "vault_generic_secret" "db" {
  path = "secret/data/prod/database"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db.data["password"]
}
```

**Key points**: Use **short-lived tokens**, **AppRole** or **JWT auth** in pipelines, and **least-privilege Vault policies**.

---

### Q17. What security scanning tools should be integrated with Terraform?

| Tool | Purpose |
|------|---------|
| **tfsec / Trivy** | Static analysis for security misconfigurations. |
| **Checkov** | Policy-as-code scanning (CIS benchmarks). |
| **OPA / Sentinel** | Custom policy enforcement at plan time. |
| **Terrascan** | Compliance scanning (SOC2, HIPAA, PCI-DSS). |
| **infracost** | Cost anomaly detection (unexpected resource sizes). |

Integrate all of these as **CI pipeline gates** — block merges on policy violations.

---

### Q18. How do you enforce least-privilege IAM for Terraform itself?

- Create a **dedicated service account** for Terraform with only the permissions needed.
- Use **IAM boundary policies** (AWS) or **custom roles** (GCP/Azure) to cap maximum permissions.
- Use **assume-role** with session policies for narrower scope per workspace.
- Rotate credentials regularly or use **OIDC federation** (GitHub Actions → AWS) to avoid long-lived keys entirely.
- **Audit** the service account's actions via CloudTrail / Azure Activity Log.

---

## 4. Modules & Code Organisation

### Q19. What are Terraform modules and why are they important?

Modules are **reusable, self-contained packages** of Terraform configuration. Benefits:

- **DRY principle** — write once, use across environments.
- **Encapsulation** — hide complexity behind a clean interface (variables + outputs).
- **Versioning** — pin module versions to prevent unintended changes.
- **Testing** — modules can be independently tested (Terratest, `terraform test`).

---

### Q20. What is the recommended module directory structure?

```
modules/
  vpc/
    main.tf          # Resources
    variables.tf     # Input variables
    outputs.tf       # Output values
    versions.tf      # Required providers & Terraform version
    README.md        # Documentation
    examples/        # Example usage
    tests/           # terraform test files
```

**Enterprise pattern**: Publish modules to a **private registry** (Terraform Cloud, Artifactory, S3) with semantic versioning.

---

### Q21. How do you version and source modules securely?

```hcl
module "vpc" {
  source  = "app.terraform.io/myorg/vpc/aws"
  version = "~> 3.2"   # Allow patch updates only
}
```

**Security practices**:
- Always **pin versions** — never use `ref = "main"` in production.
- Use a **private registry** — avoid pulling arbitrary public modules.
- **Review module code** before adoption (supply-chain security).
- Use `.terraform.lock.hcl` to lock exact hashes.

---

### Q22. What is the difference between root modules and child modules?

| Aspect        | Root Module                                    | Child Module                             |
| ------------- | ---------------------------------------------- | ---------------------------------------- |
| Location      | The top-level directory where you run Terraform | A module called via `module` block       |
| State         | Owns the state file                            | Resources stored in the root's state     |
| Variables     | Can be set via CLI, `.tfvars`, env vars        | Must be passed explicitly by the caller  |
| Backend       | Configures the backend                         | Cannot configure its own backend         |

---

## 5. Providers & Resources

### Q23. What is the difference between `resource` and `data` source?

- **`resource`**: Creates and manages infrastructure (full lifecycle — create, read, update, delete).
- **`data`**: **Read-only** query to fetch information about existing infrastructure not managed by the current configuration.

```hcl
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

---

### Q24. How do you handle multiple provider configurations (e.g., multi-region)?

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dr"
}

resource "aws_s3_bucket" "dr_backup" {
  provider = aws.dr
  bucket   = "myorg-dr-backup"
}
```

**Use cases**: Multi-region DR, cross-account deployments, hybrid cloud.

---

### Q25. What are `lifecycle` meta-arguments and when should you use them?

```hcl
resource "aws_instance" "critical" {
  lifecycle {
    prevent_destroy       = true    # Block accidental deletion
    create_before_destroy = true    # Zero-downtime replacement
    ignore_changes        = [tags]  # Ignore external tag edits
  }
}
```

- **`prevent_destroy`** — Essential for databases, encryption keys, state buckets.
- **`create_before_destroy`** — Critical for HA; new resource is ready before old one is removed.
- **`ignore_changes`** — Prevents drift fights when external systems (e.g., auto-tagging) modify attributes.

---

### Q26. What is `terraform taint` and why is it deprecated?

`terraform taint` marked a resource for **forced recreation** on the next apply. It is deprecated in favour of:

```bash
terraform apply -replace="aws_instance.web"
```

**Why replaced**: `taint` modified the state file directly (risky); `-replace` integrates with the plan workflow and is reviewable.

---

## 6. Workspaces, Environments & Pipelines

### Q27. What are Terraform workspaces and when should you use them?

Workspaces provide **isolated state files** within the same configuration. Each workspace has its own `terraform.tfstate`.

```bash
terraform workspace new staging
terraform workspace select production
```

**Good for**: Lightweight separation of identical environments (dev/staging/prod) with variable differences.

**Not recommended for**: Significantly different environments — use **separate directories or repos** instead for full isolation.

---

### Q28. What is the preferred enterprise pattern for environment separation?

```
environments/
  dev/
    main.tf           # Calls shared modules
    terraform.tfvars
    backend.hcl       # Points to dev state bucket
  staging/
    main.tf
    terraform.tfvars
    backend.hcl
  prod/
    main.tf
    terraform.tfvars
    backend.hcl
modules/
  vpc/
  compute/
```

**Benefits**: Complete **blast-radius isolation** — a bad plan in dev cannot corrupt prod state. Each environment can be independently locked, promoted, and audited.

---

### Q29. How should a secure CI/CD pipeline for Terraform look?

```
PR Created
  → terraform fmt -check
  → terraform validate
  → tfsec / checkov scan
  → terraform plan (saved to file)
  → Plan output posted as PR comment
  → Sentinel / OPA policy check

PR Approved + Merged
  → terraform apply (from saved plan file)
  → Post-apply drift detection scheduled
```

**Security gates**: No direct `apply` from developer laptops. All changes go through **PR review + policy checks + saved plan**.

---

### Q30. How do you use a saved plan file and why is it important?

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

**Importance**: The saved plan ensures that **exactly what was reviewed gets applied** — no changes can sneak in between plan and apply. This is mandatory in secure environments to prevent:

- Time-of-check to time-of-use (TOCTOU) attacks.
- Unreviewed changes applied by automation.

---

## 7. Advanced HCL & Functions

### Q31. What is the difference between `count` and `for_each`?

| Feature     | `count`                                  | `for_each`                                 |
| ----------- | ---------------------------------------- | ------------------------------------------ |
| Index       | Numeric (`[0], [1], ...`)                | Key-based (`["a"], ["b"], ...`)            |
| Reordering  | Removing item N shifts all subsequent    | Removing a key only affects that resource  |
| Best for    | Simple on/off toggles (`count = var.enabled ? 1 : 0`) | Collections where each item has identity |

**Best practice**: Prefer `for_each` in production — it is **stable under insertions and deletions**.

---

### Q32. What are `dynamic` blocks and when should you use them?

Dynamic blocks generate **repeated nested blocks** programmatically:

```hcl
resource "aws_security_group" "web" {
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

**Use when**: Security group rules, IAM policies, or any nested block that varies by environment. **Avoid overuse** — deep nesting of dynamic blocks reduces readability.

---

### Q33. What are `locals` and how do they differ from `variables`?

- **`variable`**: Input to the configuration — set by the caller (CLI, tfvars, environment).
- **`locals`**: Computed values internal to the module — not settable by the caller.

```hcl
locals {
  env_prefix  = "${var.project}-${var.environment}"
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    CostCenter  = var.cost_center
  }
}
```

Use locals to **reduce repetition** and **centralise computed values**.

---

### Q34. Explain `terraform console` and useful built-in functions for security.

`terraform console` provides an interactive REPL to test expressions.

| Function | Use Case |
|----------|----------|
| `cidrsubnet()` | Calculate subnet ranges without manual errors. |
| `try()` | Gracefully handle optional attributes. |
| `sensitive()` | Programmatically mark values as sensitive. |
| `nonsensitive()` | Explicitly unwrap sensitive values (use with caution). |
| `regex()` | Validate input patterns (e.g., CIDR format). |
| `jsonencode()` / `yamlencode()` | Generate IAM policy documents safely. |

---

## 8. Drift Detection, Import & Disaster Recovery

### Q35. What is infrastructure drift and how do you detect it?

Drift occurs when the **real infrastructure diverges from the state file** — caused by manual console changes, other tools, or external automation.

**Detection methods**:
- `terraform plan` — shows differences between state and real infrastructure.
- **Scheduled drift detection** — run `plan` on a cron in CI and alert on non-empty diffs.
- **Terraform Cloud** — has built-in scheduled drift detection.

**Response**: Investigate the drift. Either update HCL to match reality or re-apply to enforce desired state.

---

### Q36. How does `terraform import` work, and what changed in Terraform 1.5+?

**Legacy** (pre-1.5):
```bash
terraform import aws_instance.web i-0abc123def
```
Required you to write the HCL first, then import. No plan preview.

**Terraform 1.5+** — `import` block:
```hcl
import {
  to = aws_instance.web
  id = "i-0abc123def"
}
```
- Integrates with the **plan/apply workflow**.
- Use `terraform plan -generate-config-out=generated.tf` to auto-generate HCL.
- Safer, reviewable, and auditable.

---

### Q37. How do you handle disaster recovery for Terraform itself?

| Component | DR Strategy |
|-----------|-------------|
| **State file** | Versioned remote backend (S3 versioning, Azure blob snapshots). |
| **Terraform code** | Git repository with branch protection and backups. |
| **Provider credentials** | Vault with replication; OIDC federation as primary. |
| **Module registry** | Private registry with artifact backups. |
| **CI/CD pipeline** | Pipeline-as-code stored in Git; runners in multiple regions. |

**Runbook**: Document the steps to bootstrap Terraform from scratch — backend creation, provider auth, and initial import.

---

### Q38. What is `terraform refresh` and why should you avoid using it directly?

`terraform refresh` updates the state file to match real infrastructure **without showing you what changed**. Risks:

- Could overwrite legitimate state entries with drifted values silently.
- In Terraform 0.15.4+, `terraform plan -refresh-only` replaces it — shows a **plan of state changes** for review before applying.

**Always prefer** `terraform apply -refresh-only` with approval.

---

## 9. Enterprise & Governance

### Q39. What is Sentinel and how does it enforce policy?

Sentinel is HashiCorp's **policy-as-code framework** (Terraform Cloud/Enterprise). Policies run between `plan` and `apply`:

```python
# Require all S3 buckets to have encryption
import "tfplan/v2" as tfplan

s3_buckets = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket" and rc.mode is "managed"
}

main = rule {
    all s3_buckets as _, bucket {
        bucket.change.after.server_side_encryption_configuration is not null
    }
}
```

**Enforcement levels**: `advisory`, `soft-mandatory` (override with approval), `hard-mandatory` (no override).

---

### Q40. How do you use OPA (Open Policy Agent) with Terraform?

OPA is a **vendor-neutral** alternative to Sentinel:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
opa eval -d policy/ -i plan.json "data.terraform.deny"
```

**Advantages**: Open-source, works with any CI system, uses Rego language, and can enforce policies across Terraform, Kubernetes, and APIs.

---

### Q41. What is Terraform Cloud/Enterprise and when is it justified?

| Feature | Benefit |
|---------|---------|
| **Remote execution** | Plans run in a controlled environment, not developer laptops. |
| **State management** | Built-in encrypted remote state with locking and versioning. |
| **Sentinel policies** | Gate applies on compliance rules. |
| **Private registry** | Host and version internal modules. |
| **SSO / RBAC** | Fine-grained access control per workspace. |
| **Drift detection** | Scheduled automatic detection. |
| **Audit logs** | Every plan/apply logged with user, time, and changes. |

**Justified in**: Regulated industries, multi-team organisations, and environments requiring SOC2/HIPAA compliance.

---

### Q42. How do you implement RBAC for Terraform in an enterprise?

- **Terraform Cloud**: Use **teams** with workspace-level permissions (read, plan, write, admin).
- **VCS**: Branch protection + CODEOWNERS — require security team review for `prod/` changes.
- **Cloud IAM**: Separate service accounts per environment with distinct permission sets.
- **Vault**: Namespace and policies per team/environment for secrets access.
- **Git**: Restrict who can merge to `main` — enforce PR approvals from infrastructure leads.

---

### Q43. How do you manage Terraform at scale across 50+ microservices?

- **Terragrunt** — DRY wrapper that manages backend config, dependencies, and execution across many modules.
- **Monorepo with CI matrix** — Detect changed directories and only plan/apply affected stacks.
- **Private module registry** — Standardised, versioned building blocks.
- **State file per service** — Small blast radius; failures are contained.
- **Automated documentation** — `terraform-docs` generates module docs from code.

---

## 10. Real-World Scenarios & Troubleshooting

### Q44. You run `terraform apply` and it fails midway. What do you do?

1. **Do NOT panic-rerun** — read the error message carefully.
2. Run `terraform plan` to see the current state vs desired state.
3. Terraform's state records **partially applied changes** — it knows which resources were created.
4. Fix the root cause (permissions, quota, API error).
5. Re-run `terraform apply` — Terraform will continue from where it left off due to idempotency.
6. If a resource is stuck, use `terraform state rm` + manual cleanup + `terraform import` as last resort.

---

### Q45. How do you handle a resource that Terraform wants to destroy and recreate unexpectedly?

1. Run `terraform plan` and check **why** — look for `forces replacement` in the output.
2. Common causes: immutable attributes changed (AMI ID, instance type in some cases), provider upgrade changed default behaviour.
3. **Options**:
   - Use `lifecycle { create_before_destroy = true }` for zero-downtime.
   - Use `terraform state rm` + `terraform import` to re-adopt if it's a false positive.
   - Use `moved` block if it's a rename issue.
   - Use `ignore_changes` if the attribute is managed externally.

---

### Q46. How do you manage cross-team dependencies (e.g., networking team provisions VPC, app team consumes it)?

Use **remote state data source** or **data sources**:

```hcl
# App team reads VPC info from networking team's state
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "myorg-tf-state"
    key    = "network/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
}
```

**Better approach**: Use **data sources** to query the VPC directly (less coupling) or use a **service catalog / Backstage** for contract-driven infra.

---

### Q47. How do you zero-downtime deploy infrastructure changes?

- **`create_before_destroy`** — New resource is fully provisioned before old one is destroyed.
- **Blue/Green**: Provision new environment, switch DNS/LB target, destroy old.
- **Canary**: Use `count` or `for_each` to incrementally roll out changes.
- **Feature flags**: Use variables to toggle between old and new resource configurations.
- **Database**: Use separate migration tools (Flyway, Liquibase) — Terraform manages the instance, not the schema.

---

### Q48. A colleague accidentally ran `terraform destroy` on production. How do you recover?

1. **Immediately**: Revoke the CI/CD credentials to prevent further damage.
2. **Assess scope**: Check the Terraform Cloud audit log or CI logs for what was destroyed.
3. **State recovery**: Restore state from the versioned backend (S3 versioning).
4. **Resource recovery**: Some resources have deletion protection (RDS snapshots, S3 versioning). Restore from those.
5. **Re-apply**: Run `terraform apply` against the last known-good state + config.
6. **Post-incident**:
   - Enable `prevent_destroy` on all critical resources.
   - Restrict `destroy` permissions in CI (separate pipeline, requires approval).
   - Add Sentinel/OPA policy to block `destroy` on production workspaces.

---

### Q49. How do you test Terraform code?

| Level | Tool / Method | What It Tests |
|-------|---------------|---------------|
| **Static** | `terraform validate`, `fmt`, `tfsec`, `checkov` | Syntax, formatting, security. |
| **Unit** | `terraform test` (built-in 1.6+) | Module logic with mock providers. |
| **Contract** | `precondition` / `postcondition` blocks | Input validation and output guarantees. |
| **Integration** | Terratest (Go), Kitchen-Terraform | Real infrastructure provisioning + assertions. |
| **Policy** | Sentinel, OPA | Governance and compliance. |

**In critical environments**: Run integration tests in an isolated sandbox account and gate promotions on passing results.

---

### Q50. What are `precondition` and `postcondition` blocks and why do they matter?

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
      error_message = "Only approved instance types are allowed."
    }

    postcondition {
      condition     = self.public_ip != ""
      error_message = "Instance must have a public IP assigned."
    }
  }
}
```

- **Preconditions** — Validate inputs before resource creation (fail fast).
- **Postconditions** — Assert outputs after creation (catch provider bugs or misconfigurations).
- **Critical in secure environments** — Enforce guardrails directly in code, not just in external policies.

---

## Quick Reference — Key Commands Cheat Sheet

```bash
# Initialisation
terraform init -backend-config=backend.hcl
terraform init -upgrade                      # Upgrade providers/modules

# Planning
terraform plan -out=tfplan                   # Save plan
terraform plan -target=aws_instance.web      # Plan single resource
terraform plan -refresh-only                 # Detect drift only

# Applying
terraform apply tfplan                       # Apply saved plan
terraform apply -auto-approve                # NEVER use in production

# State Operations
terraform state list                         # List all resources
terraform state show aws_instance.web        # Show resource details
terraform state mv <src> <dst>               # Move/rename resource
terraform state rm <resource>                # Remove from state
terraform state pull > backup.tfstate        # Backup state

# Import
terraform import aws_instance.web i-abc123   # Legacy import
terraform plan -generate-config-out=gen.tf   # Generate HCL for import blocks

# Debugging
TF_LOG=DEBUG terraform plan                  # Verbose logging
terraform console                            # Interactive expression testing
terraform graph | dot -Tpng > graph.png      # Visualise dependency graph
```

---

> **Pro Tip**: In a client interview for secure infrastructure, always tie your answers back to **blast-radius reduction**, **least privilege**, **auditability**, and **reproducibility**. These are the pillars interviewers in critical environments care about most.
