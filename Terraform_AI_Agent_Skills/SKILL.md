---
name: terraform
description: Write, review, scaffold, and troubleshoot Terraform infrastructure-as-code — module design, remote state/backends, environment separation, naming/tagging conventions, and security scanning (tfsec/checkov/tflint). Covers AWS, Azure, and GCP provider patterns (VPCs, AKS, GKE, EC2, IAM). Use this whenever the user is working with .tf/.tfvars/.tfstate files, running terraform init/plan/apply/destroy, designing or reviewing Terraform modules, setting up a remote backend, debugging state drift/lock/import issues, or provisioning cloud infra via IaC — even if they don't say "Terraform" explicitly and just mention things like "provision a VPC", "set up an AKS cluster with Terraform", "GKE module", or "why is my plan showing a diff".
---

# Terraform IaC

Practical conventions and workflow for writing and reviewing Terraform, tuned for
DevOps/platform-engineering work across AWS, Azure, and GCP (the three clouds most
likely in play here: AWS for general infra/migration work, Azure for AKS-based
platforms, GCP for GKE-based platforms).

## Core workflow

Always run these in order, and don't skip steps to save time — `plan` before `apply`
is non-negotiable for anything touching real infra:

1. `terraform fmt -recursive` — normalize formatting before anything else
2. `terraform validate` — catch syntax/type errors cheaply
3. `terraform plan -out=tfplan` — always review the plan, never apply blind
4. Read the plan diff carefully: look for any `-/+` (destroy + recreate) on
   resources that hold state (databases, PVs, load balancers with static IPs) —
   these are the most common source of production incidents
5. `terraform apply tfplan` — apply the reviewed plan file, not a fresh plan
6. Commit `.tf` changes; never commit `.tfstate`, `.tfvars` with secrets, or `.terraform/`

If asked to just "write some Terraform," still mentally run through this
checklist and flag anything in the generated code that would show as a
destroy/recreate on a stateful resource.

## Project structure

Default to a directory-per-environment layout over Terraform workspaces for
anything beyond a solo learning project — workspaces make it too easy to
`apply` against the wrong environment by accident:

```
infra/
├── modules/
│   ├── network/
│   ├── cluster/          # AKS or GKE module
│   └── <other-module>/
├── environments/
│   ├── dev/
│   │   ├── main.tf        # calls modules, sets env-specific vars
│   │   ├── backend.tf     # remote state config for this env
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   ├── staging/
│   └── prod/
└── .pre-commit-config.yaml
```

Each module gets `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and a
`README.md`. See `assets/module-template/` for a ready-to-copy skeleton —
use it whenever scaffolding a new module rather than starting from a blank file.

## Remote state & backends

Never use local state beyond a throwaway sandbox. Always configure a remote
backend with locking:

| Cloud | Backend | State store | Lock mechanism |
|---|---|---|---|
| AWS | `s3` | S3 bucket (versioned, encrypted) | DynamoDB table |
| Azure | `azurerm` | Storage Account blob container | native blob lease |
| GCP | `gcs` | GCS bucket (versioned) | native |

Provider-specific backend snippets and resource conventions live in:
- `references/aws.md`
- `references/azure.md`
- `references/gcp.md`

Read the relevant one before writing provider-specific resources — don't
guess at argument names from memory, provider schemas change across versions.

## Variables, outputs, and naming

- Every variable gets a `description` and, where sensible, a `type` constraint
  and `validation` block — don't leave variables untyped.
- Mark secrets-bearing variables `sensitive = true`.
- Output only what downstream modules/consumers need; don't dump entire
  resource objects.
- Naming convention for resources: `<project>-<env>-<component>-<resource-type>`,
  e.g. `hdfc-prod-gke-cluster`, `jarvis-dev-vnet`. Keep it consistent across
  the whole codebase — inconsistent naming is the #1 thing that makes a
  multi-module estate hard to navigate later.
- Tag/label every resource with at minimum: `environment`, `owner`/`team`,
  `managed-by = terraform`. Cloud-specific tagging conventions are in the
  provider reference files.

## Environment separation

- Separate state file per environment (per the directory layout above) —
  never share one state file across dev/staging/prod.
- Use `terraform.tfvars` (gitignored if it holds anything sensitive) or a
  secrets manager (AWS Secrets Manager / Azure Key Vault / GCP Secret Manager)
  for environment-specific secrets — never hardcode credentials in `.tf` files.
- For a banking/regulated client context (private clusters, restricted
  ingress, audit logging required), default to the more locked-down option
  whenever a resource has a public/private toggle, and call it out explicitly
  in the plan review rather than silently picking the permissive default.

## Security scanning

DevSecOps-style review should be routine, not an afterthought. See
`references/security-scanning.md` for tfsec/checkov/tflint config and how to
wire them into a pre-commit hook or CI step. At minimum, run a scan before
proposing any `apply` on infra that touches networking, IAM, or public
endpoints, and surface findings alongside the plan output rather than in a
separate pass the user has to remember to ask for.

## Troubleshooting quick reference

| Symptom | Likely cause | Fix |
|---|---|---|
| `Error acquiring the state lock` | Previous apply crashed mid-run, or concurrent run | Confirm no other run is active, then `terraform force-unlock <LOCK_ID>` |
| Plan shows unexpected `-/+` | Argument change forces replacement (check provider docs for `ForceNew`-equivalent fields) | Check if an `ignore_changes` lifecycle rule or an in-place-safe alternative argument exists |
| Resource exists in cloud but not in state | Created manually or by another tool | `terraform import <resource_address> <cloud_id>` |
| Plan keeps showing a diff on every run ("perpetual diff") | Provider default value not set explicitly in config | Set the argument explicitly to match the provider's computed default |
| `Error: Provider produced inconsistent result` | Provider bug or race condition (common with GKE/AKS node pools) | Re-run plan/apply; pin provider version; check provider GitHub issues |

For anything provider-specific beyond this table, check the matching file in
`references/` before improvising — Kubernetes-adjacent resources (AKS node
pools, GKE node pools, IAM bindings) are especially prone to subtle
provider-version-specific quirks.

## When scaffolding a new module

1. Copy `assets/module-template/` as the starting point.
2. Fill in `main.tf` with the actual resources.
3. Declare every input in `variables.tf` with `description` + `type`.
4. Declare every consumer-facing value in `outputs.tf`.
5. Pin provider versions in `versions.tf` — never leave `required_providers`
   unconstrained.
6. Fill in the module `README.md` (inputs/outputs table + a usage example).