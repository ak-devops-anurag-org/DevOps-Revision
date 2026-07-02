# Terraform Workspaces: Best Practices Guide

## Table of Contents

- [What are Terraform Workspaces?](#what-are-terraform-workspaces)
- [Why Use Workspaces?](#why-use-workspaces)
- [Workspace Example Usage](#workspace-example-usage)
- [Best Practices for Workspaces](#best-practices-for-workspaces)
- [Common Workspace Commands](#common-workspace-commands)


## What are Terraform Workspaces?

Terraform workspaces allow you to manage multiple instances of a given set of infrastructure resources within a single configuration. Each workspace maintains its own state file, enabling you to deploy the same code to different environments (e.g., dev, staging, prod) without duplicating configuration files.

- **Default Workspace:** Every Terraform project starts with a `default` workspace.
- **Custom Workspaces:** You can create and switch to custom-named workspaces as needed.



## Why Use Workspaces?

- **Environment Separation:** Cleanly separate infrastructure for dev, staging, and production using the same codebase.
- **State Isolation:** Each workspace has its own state file, preventing accidental cross-environment changes.
- **Simplified Codebase:** Avoids code duplication for similar infrastructure across environments.
- **Safe Experimentation:** Test changes in a separate workspace before applying to production.



## Workspace Example Usage

### Creating and Switching Workspaces

```bash
# List all workspaces
terraform workspace list

# Create a new workspace
terraform workspace new dev

# Switch to an existing workspace
terraform workspace select dev
```

### Using Workspace Name in Configuration

You can reference the current workspace in your Terraform code using the `terraform.workspace` variable:

```bash
resource "azurerm_resource_group" "example" {
  name     = "rg-${terraform.workspace}"
  location = "East US"
}
```

This will create resource groups like `rg-dev`, `rg-staging`, `rg-prod` depending on the active workspace.

---



## Terraform Best Practices

- **Use remote backend for state:** Avoid local `terraform.tfstate`, use S3 + DynamoDB, Azure Blob, or Terraform Cloud for collaboration.
- **Enable state locking:** Prevents two users from running apply simultaneously.
- **Never commit terraform.tfstate to Git:** Sensitive data may be inside (passwords, keys).
- **Use terraform.tfvars or environment variables for sensitive inputs:** Do not hard-code secrets in code.
- **Keep code modular:** Use modules for VPC, VM, DB, etc. instead of dumping all in `main.tf`.
- **Use workspaces or separate state files for environments:** (dev, stage, prod).
- **Pin provider versions in versions.tf and .terraform.lock.hcl:** Ensures consistency across teams and CI/CD.
- **Validate and plan before apply:** Always run `terraform plan` (and preferably `terraform plan -out=planfile`) before `apply`.
- **Document variable definitions:** Use `description` in `variables.tf` for clarity.
- **Use locals for computed values:** Avoid repeating complex expressions.
- **Organize folder structure:** Separate `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `provider.tf` for maintainability.
- **Tag resources:** Helps with cost allocation and resource tracking.
- **Use linting and formatting:** Run `terraform fmt` and `terraform validate` regularly.
- **Encrypt state files:** (S3 bucket with SSE, KMS, Azure Blob encryption).
- **Limit blast radius:** Use smaller state files (per app/module) instead of one giant state file.
- **Always review execution plans before applying changes:** Especially in CI/CD.
- **Handle secrets properly:** Use Vault, AWS Secrets Manager, or Azure Key Vault, not plaintext.
- **Automate with CI/CD:** Don’t run `terraform apply` manually in production; integrate into pipelines.
- **Use data sources:** To fetch existing infra details instead of hardcoding.
- **Destroy with caution:** Use `-target` or separate states to avoid accidental full deletions.

---

## Common Workspace Commands

| Command                        | Description                                 |
|--------------------------------|---------------------------------------------|
| `terraform workspace list`     | List all available workspaces               |
| `terraform workspace new <name>` | Create a new workspace                    |
| `terraform workspace select <name>` | Switch to a workspace                  |
| `terraform workspace show`     | Show the current workspace                  |
| `terraform workspace delete <name>` | Delete a workspace (not `default`)     |

---

## Example Workflow

```bash
# Initialize Terraform
terraform init

# Create and switch to a new workspace
terraform workspace new staging
terraform workspace select staging

# Apply configuration to the 'staging' workspace
terraform apply

# Switch to production workspace and apply
terraform workspace new prod
terraform workspace select prod
terraform apply
```

---

## References

- [Terraform Official Docs: Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)