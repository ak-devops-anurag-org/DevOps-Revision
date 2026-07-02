# Terraform Complete Guide: Infrastructure as Code

## Table of Contents

- [What is Infrastructure as Code (IaC)](#what-is-infrastructure-as-code-iac)
- [Why Terraform](#why-terraform)
- [Terraform Lifecycle](#terraform-lifecycle)
- [Terraform Providers](#terraform-providers)
- [Terraform Configuration Blocks](#terraform-configuration-blocks)
- [Version Management](#version-management)
- [Random Provider Example](#random-provider-example)
- [Azure Resource Group Example](#azure-resource-group-example)
- [Terraform State Management](#terraform-state-management)
- [Remote Backend Configuration](#remote-backend-configuration)
- [Additional Commands and Best Practices](#additional-commands-and-best-practices)

***

## What is Infrastructure as Code (IaC)

Infrastructure as Code (IaC) is a method of managing and provisioning computing infrastructure through machine-readable definition files, rather than through physical hardware configuration or interactive configuration tools.

### Key Benefits:

- **Version Control**: Infrastructure configurations can be versioned and tracked
- **Reproducibility**: Same infrastructure can be deployed across different environments
- **Consistency**: Eliminates configuration drift and manual errors
- **Scalability**: Easy to scale infrastructure up or down
- **Cost Management**: Better resource tracking and optimization
- **Collaboration**: Teams can collaborate on infrastructure changes

***

## Why Terraform

Terraform is a popular open-source IaC tool developed by HashiCorp that offers several advantages:

### Key Features:

- **Cloud Agnostic**: Works with multiple cloud providers (AWS, Azure, GCP, etc.)
- **Declarative Language**: Define what you want, not how to achieve it
- **State Management**: Tracks infrastructure state and manages changes
- **Plan Before Apply**: Preview changes before execution
- **Resource Graph**: Understands dependencies between resources
- **Large Ecosystem**: Extensive provider and module library


### Terraform vs Other Tools:

| Feature | Terraform | CloudFormation | Ansible |
| :-- | :-- | :-- | :-- |
| Multi-Cloud | ✅ | ❌ (AWS Only) | ✅ |
| State Management | ✅ | ✅ | ❌ |
| Declarative | ✅ | ✅ | ❌ |
| Agent-less | ✅ | ✅ | ✅ |


***

## Terraform Lifecycle

Terraform follows a simple four-step lifecycle for managing infrastructure:

### 1. `terraform init`

- Initializes a Terraform working directory
- Downloads required provider plugins
- Sets up backend configuration
- Creates `.terraform` directory

```bash
terraform init
```


### 2. `terraform plan`

- Creates an execution plan
- Shows what actions Terraform will perform
- Compares current state with desired state
- No actual changes are made

```bash
terraform plan
terraform plan -out=tfplan  # Save plan to file
```


### 3. `terraform apply`

- Executes the actions proposed in plan
- Creates, updates, or deletes resources
- Updates the state file
- Requires confirmation unless auto-approved

```bash
terraform apply
terraform apply tfplan      # Apply saved plan
terraform apply --auto-approve  # Skip confirmation
```


### 4. `terraform destroy`

- Destroys all resources managed by Terraform
- Removes infrastructure created by current configuration
- Updates state file to reflect destruction

```bash
terraform destroy
terraform destroy --auto-approve  # Skip confirmation
```


***

## Terraform Providers

Providers are plugins that Terraform uses to interact with cloud providers, SaaS providers, and other APIs.

### Types of Providers:

1. **Official Providers** (maintained by HashiCorp)
    - AWS, Azure, Google Cloud, etc.
2. **Partner Providers** (maintained by third-party companies)
    - Datadog, New Relic, PagerDuty, etc.
3. **Community Providers** (maintained by community)
    - Various smaller services and tools

### How Providers Work:

- Terraform providers hit the respective APIs
- Each provider exposes resources and data sources
- Providers handle authentication and API communication
- Providers are downloaded during `terraform init`

***

## Terraform Configuration Blocks

### Terraform Block

The `terraform` block configures Terraform behavior and requirements:

```hcl
terraform {
  required_version = ">= 1.1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
```


### Required Providers Block

Specifies which providers the configuration requires:

- **source**: Where to download the provider from
- **version**: Version constraint for the provider


### Provider Block

Configures the named provider:

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```


***

## Version Management

### Terraform Version Constraint

```hcl
required_version = ">= 1.1.0"
```

- If not specified, Terraform uses the latest available version
- Best practice: Always specify version constraints


### Provider Version Constraints

| Operator | Description | Example |
| :-- | :-- | :-- |
| `=` | Exact version | `= 1.2.0` |
| `!=` | Not equal | `!= 1.2.0` |
| `>` | Greater than | `> 1.2.0` |
| `>=` | Greater than or equal | `>= 1.2.0` |
| `<` | Less than | `< 1.2.0` |
| `<=` | Less than or equal | `<= 1.2.0` |
| `~>` | Pessimistic constraint | `~> 1.2.0` |

### Pessimistic Constraint (`~>`)

The `~>` operator allows the rightmost version number to increment:

- `~> 1.2.0` allows `>= 1.2.0` and `< 1.3.0`
- `~> 1.2` allows `>= 1.2.0` and `< 2.0.0`

***

## Random Provider Example

The Random provider is useful for generating random values in Terraform configurations:

```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

resource "random_string" "example" {
  length  = 8
  special = false
  upper   = false
}

resource "random_password" "example" {
  length  = 16
  special = true
}

output "random_string" {
  value = random_string.example.result
}

output "random_password" {
  value = random_password.example.result
  sensitive = true
}
```


***

## Azure Resource Group Example

### Prerequisites: Service Principal Setup

Before running Terraform with Azure, you need to set up authentication. Export the following environment variables:

```bash
# Create Service Principal (run once)
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Export credentials (run before terraform commands)
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

> **⚠️ Security Note**: Never commit these credentials to version control. Store them securely and use environment variables or Azure Key Vault.

### Terraform Configuration

```hcl
# main.tf
terraform {
  required_version = ">= 1.1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-terraform-demo"
  location = "East US"

  tags = {
    Environment = "Development"
    CreatedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "resource_group_location" {
  value = azurerm_resource_group.example.location
}
```


### Deployment Steps

```bash
# Initialize Terraform
terraform init

# Validate the syntax 
terraform validate

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Clean up resources
terraform destroy
```


***

## Terraform State Management

### Understanding State Files

Terraform uses state files to track the real-world resources it manages:

#### `.tf` files (Desired State)

- Define what infrastructure you want
- Written in HCL (HashiCorp Configuration Language)
- Version controlled and shared among team members


#### `terraform.tfstate` (Actual State)

- JSON file that maps Terraform configuration to real-world resources
- Contains resource metadata and dependencies
- **Critical**: Never edit manually


### State File Updates

The state file gets updated during:

- `terraform apply`
- `terraform plan`
- `terraform refresh`


### State File Challenges with Local Storage

#### Problems with Local State:

1. **Team Collaboration**: State file can't be shared easily
2. **Security**: Sensitive data stored in plain text
3. **Locking**: No mechanism to prevent concurrent modifications
4. **Backup**: Risk of losing state file
5. **Isolation**: Difficult to manage multiple environments

### Remote Backend Benefits

#### Why Use Remote Backend:

- **Collaboration**: Shared access for team members
- **State Locking**: Prevents concurrent modifications
- **Security**: Encrypted storage and access controls
- **Backup**: Automatic versioning and backup
- **Isolation**: Separate state files per environment

***

## Remote Backend Configuration

### AWS S3 Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

# Create S3 bucket and DynamoDB table first
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```


### Azure Blob Storage Backend

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "terraformstatestg"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Create storage account for state (run this first)
resource "azurerm_resource_group" "state" {
  name     = "rg-terraform-state"
  location = "East US"
}

resource "azurerm_storage_account" "state" {
  name                     = "terraformstatestg"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}
```


### Backend Initialization Process

1. **Create Backend Resources First**:
```bash
# Deploy storage resources without backend
terraform init
terraform apply
```

2. **Configure Backend**:
```bash
# Add backend configuration to terraform block
# Run init with -migrate-state flag
terraform init -migrate-state
```

3. **Verify Backend**:
```bash
terraform plan  # Should show no changes if migration successful
```


***

## Additional Commands and Best Practices

### Useful Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"
alias tff="terraform fmt"
alias tfv="terraform validate"
```


### Essential Terraform Commands

```bash
# Format and validate
terraform fmt              # Format configuration files
terraform validate         # Validate configuration syntax

# State management
terraform state list       # List resources in state
terraform state show       # Show resource details
terraform import           # Import existing resources
terraform state rm         # Remove resource from state

# Workspace management
terraform workspace list   # List workspaces
terraform workspace new    # Create new workspace
terraform workspace select # Switch workspace

# Output and variables
terraform output           # Show output values
terraform refresh          # Update state from real infrastructure

# Advanced options
terraform apply -auto-approve           # Skip confirmation
terraform apply -target=resource_name   # Target specific resource
terraform plan -out=tfplan             # Save plan to file
terraform apply tfplan                 # Apply saved plan
terraform destroy -auto-approve        # Destroy without confirmation
```

