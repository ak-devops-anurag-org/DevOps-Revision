# Terraform Variables - Input, Output & Local Variables

## Overview

This guide covers the three main types of variables in Terraform: **Input Variables**, **Output Variables**, and **Local Values**. Understanding these variable types is crucial for writing clean, maintainable, and reusable Terraform configurations.

## Types of Variables in Terraform

### 1. **Input Variables**
- Variables that you provide as input to your Terraform configuration
- Similar to function parameters in programming
- Allow users to customize configurations without modifying the core code

### 2. **Output Variables** 
- Values returned by Terraform after resource creation
- Similar to function return values
- Used to display important information or pass data between modules

### 3. **Local Values (Locals)**
- Internal variables defined and used within the same Terraform configuration
- Help avoid repetition and improve code maintainability
- Values that don't change frequently

## Variable Type Constraints

Terraform supports different data types for variables:

### **Primitive Types** (store single values)
- `string` - Text values
- `number` - Numeric values  
- `bool` - Boolean (true/false) values

### **Non-Primitive Types** (store complex values)
- `list` - Ordered collection of values
- `set` - Unordered collection of unique values
- `map` - Key-value pairs
- `object` - Complex structure with named attributes
- `tuple` - Ordered collection of values with different types

**Default Type**: If no type is specified, Terraform uses `any` which accepts any value type.

## Input Variables

### Basic Syntax

```hcl
variable "variable_name" {
  type        = string
  description = "Description of the variable"
  default     = "default_value"
}
```

### Example: Environment Variable

```hcl
variable "environment" {
  type        = string
  description = "Environment type"
  default     = "staging"
}

# Using the variable in resources
resource "azurerm_storage_account" "example" {
  name                     = "examplestorageacc"
  resource_group_name      = azurerm_resource_group.example.name
  location                = azurerm_resource_group.example.location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}
```

### Variable Usage

To reference an input variable, use the `var.` prefix:

```hcl
var.environment
var.variable_name
```

## Methods to Assign Variable Values

### 1. **Default Values** (Lowest Precedence)
Define default values directly in the variable block:

```hcl
variable "environment" {
  type        = string
  description = "Environment type"
  default     = "staging"
}
```

### 2. **Environment Variables**
Set variables using environment variables with `TF_VAR_` prefix:

```bash
export TF_VAR_environment="production"
terraform plan
```

### 3. **terraform.tfvars File**
Create a `terraform.tfvars` file with key-value pairs:

```hcl
# terraform.tfvars
environment = "demo"
region      = "us-west-2"
```

### 4. **Command Line (-var flag)** (Highest Precedence)
Pass variables directly via command line:

```bash
terraform plan -var="environment=dev"
terraform apply -var="environment=prod"
```

## Variable Precedence Order

Terraform follows a specific precedence order when multiple values are provided for the same variable:

1. **Environment variables** (`TF_VAR_name`) - Lowest precedence
2. **terraform.tfvars** file
3. **terraform.tfvars.json** file  
4. ***.auto.tfvars** or ***.auto.tfvars.json** files
5. **Command line flags** (`-var` and `-var-file`) - Highest precedence

**Later sources take precedence over earlier ones.**

## Output Variables

### Basic Syntax

```hcl
output "output_name" {
  value       = resource.resource_name.attribute
  description = "Description of the output"
  sensitive   = false  # Optional: mark as sensitive
}
```

### Example: Storage Account Name Output

```hcl
output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}
```

### Viewing Output Values

After running `terraform apply`, view outputs using:

```bash
# View all outputs
terraform output

# View specific output
terraform output storage_account_name
```

### Output Usage

Outputs can be used for:
- Displaying important resource information
- Passing data between Terraform modules
- Integration with external systems
- Documentation and reference purposes

## Local Values (Locals)

### Basic Syntax

```hcl
locals {
  local_name = value
  # Multiple locals can be defined
}
```

### Example: Common Tags

```hcl
locals {
  common_tags = {
    environment = "dev"
    lob         = "banking"  # Line of Business
    stage       = "alpha"
    project     = "terraform-demo"
  }
  
  # You can also compute values
  name_prefix = "${var.environment}-${var.project}"
}

# Using locals in resources
resource "azurerm_storage_account" "example" {
  name                     = "${local.name_prefix}storage"
  resource_group_name      = azurerm_resource_group.example.name
  location                = azurerm_resource_group.example.location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}
```

### Local Values Usage

Reference local values using the `local.` prefix:

```hcl
local.common_tags
local.name_prefix
```

### When to Use Locals

- **Avoid repetition**: When the same complex expression is used multiple times
- **Improve readability**: Give meaningful names to complex expressions
- **Values that don't change often**: Unlike input variables, locals are meant for internal use
- **Computed values**: When you need to process or combine other variables

## Complete Example

Here's a comprehensive example showing all three variable types:

```hcl
# Input Variables
variable "environment" {
  type        = string
  description = "Environment type"
  default     = "staging"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "East US"
}

# Local Values
locals {
  common_tags = {
    environment = var.environment
    lob         = "banking"
    stage       = "alpha"
    managed_by  = "terraform"
  }
  
  storage_name = "${var.environment}storage${random_integer.suffix.result}"
}

# Resources
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "example" {
  name     = "${var.environment}-rg"
  location = var.location
  
  tags = local.common_tags
}

resource "azurerm_storage_account" "example" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.example.name
  location                = azurerm_resource_group.example.location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# Output Variables
output "resource_group_name" {
  value       = azurerm_resource_group.example.name
  description = "Name of the created resource group"
}

output "storage_account_name" {
  value       = azurerm_storage_account.example.name
  description = "Name of the created storage account"
}

output "storage_account_id" {
  value       = azurerm_storage_account.example.id
  description = "ID of the created storage account"
  sensitive   = false
}
```

## Variable Assignment Examples

### terraform.tfvars file
```hcl
environment = "production"
location    = "West US 2"
```

### Command line usage
```bash
# Using tfvars file
terraform plan -var-file="custom.tfvars"

# Using command line variables
terraform plan -var="environment=dev" -var="location=East US"

# Using environment variables
export TF_VAR_environment="test"
export TF_VAR_location="Central US"
terraform plan
```

## Best Practices

### 1. **Input Variables**
- Always provide meaningful descriptions
- Use appropriate type constraints
- Provide sensible default values when possible
- Use validation rules for complex constraints

### 2. **Output Variables**
- Include descriptions for all outputs
- Mark sensitive outputs appropriately
- Use outputs to expose important resource attributes

### 3. **Local Values**
- Use for computed values and to avoid repetition
- Group related locals together
- Use meaningful names that describe the purpose

### 4. **General Guidelines**
- Follow consistent naming conventions
- Use separate `.tfvars` files for different environments
- Never hardcode sensitive values
- Document variable purposes and expected values

## Common Use Cases

### Environment-Specific Configurations
```hcl
variable "environment" {
  type = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

locals {
  instance_count = var.environment == "prod" ? 3 : 1
  instance_size  = var.environment == "prod" ? "Standard_D2s_v3" : "Standard_B1s"
}
```

### Resource Naming
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  
  resource_names = {
    rg      = "${local.name_prefix}-rg"
    storage = "${local.name_prefix}storage${random_integer.suffix.result}"
    vm      = "${local.name_prefix}-vm"
  }
}
```

This comprehensive guide covers the fundamentals of Terraform variables and provides practical examples for implementing clean, maintainable infrastructure code.