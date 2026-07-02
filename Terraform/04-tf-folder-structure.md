# Terraform File and Directory Structure Best Practices

## Overview
This guide outlines best practices for organizing Terraform code into files and directories, ensuring maintainability, scalability, and readability for both hobby projects and enterprise environments.

## Why Structure Matters
- **Clarity**: Well-structured code is easier to understand and review.
- **Maintainability**: Changes are isolated to relevant files, reducing risks of unintended modifications.
- **Collaboration**: Team members can work concurrently with minimal conflicts.
- **Scalability**: As projects grow, structure supports adding modules and environments seamlessly.

## Recommended Directory Layout
```
project-root/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── locals.tf
│   │   ├── resources/
│   │   └── outputs.tf
│   └── prod/
│       └── (same structure as dev)
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       └── (module files)
├── global-resources/
│   └── ...
├── provider.tf
├── backend.tf
├── variables.tf
├── locals.tf
└── outputs.tf
```

## File Separation Strategy
1. **provider.tf**
   - Terraform block with required providers
   - Provider configurations (region, credentials)
2. **backend.tf**
   - Remote backend configuration (e.g., S3, Azure Storage)
3. **variables.tf**
   - Definitions of input variables
4. **locals.tf**
   - Local values for computed or constant data
5. **resources/**
   - Directory for grouping related resources logically
6. **outputs.tf**
   - Definitions of output variables
7. **main.tf** (optional)
   - Entry point to tie resources or call modules

## Splitting a Monolithic `main.tf`
Given a `main.tf` with all configurations, split as follows:

### Original `main.tf`
```hcl
terraform {
  required_providers { ... }
}
provider "azurerm" { ... }

terraform {
  backend "azurerm" { ... }
}

variable "environment" { ... }
locals { ... }

resource "azurerm_resource_group" "example" { ... }
resource "azurerm_storage_account" "example" { ... }

output "resource_group_name" { ... }
```

### After Splitting
- **provider.tf**
  ```hcl
  terraform {
    required_providers { ... }
  }
  provider "azurerm" { ... }
  ```
- **backend.tf**
  ```hcl
  terraform {
    backend "azurerm" { ... }
  }
  ```
- **variables.tf**
  ```hcl
  variable "environment" { ... }
  ```
- **locals.tf**
  ```hcl
  locals { ... }
  ```
- **resource_group.tf**
  ```hcl
  resource "azurerm_resource_group" "example" { ... }
  ```
- **storage_account.tf**
  ```hcl
  resource "azurerm_storage_account" "example" { ... }
  ```
- **outputs.tf**
  ```hcl
  output "resource_group_name" { ... }
  ```

## Loading and Execution Order
- Terraform loads **all** `.tf` files in a directory (alphabetical order).
- **Implicit dependencies**: Referencing attributes from another resource ensures correct creation order.
- **Explicit dependencies** (`depends_on`) should be used sparingly when implicit references aren’t possible.

## File Change Frequency
- **Rarely Changed**: `backend.tf`, `provider.tf` (only when upgrading providers or changing backend)
- **Occasionally Changed**: `variables.tf`, `locals.tf` (when adding new variables or local values)
- **Frequently Changed**: Resource files and module calls

## Module and Environment Isolation
- Use the `modules/` directory for reusable code blocks.
- Keep environment-specific configurations under `environments/` folder.
- Shared/global resources can live in `global-resources/` or top-level files.

## Best Practices Summary
- Name files meaningfully (e.g., `network.tf`, `compute.tf`).
- Separate concerns: variables, backend, provider, resources, outputs.
- Organize directories by environment and by module.
- Rely on implicit dependencies; avoid unnecessary `depends_on`.
- Maintain consistent naming conventions across files and directories.

This structure facilitates clarity, collaboration, and scalability as Terraform projects grow in complexity.
