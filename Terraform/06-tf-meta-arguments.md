# Terraform Resource Meta-Arguments: Complete Guide with Lifecycle Conditions

## Overview
Terraform meta-arguments allow dynamic resource creation and iteration patterns. This comprehensive guide covers all meta-arguments:
- **`count`**: Create multiple resource instances by index
- **`for_each`**: Iterate over a set or map for unique instances
- **`for` loops**: Generate collections in expressions (e.g., outputs)
- **`depends_on`**: Define explicit dependencies between resources
- **`lifecycle`**: Control resource behavior during create, update, and destroy operations
- **`provider`**: Specify alternate provider configurations

## 1. `count`
- **Applies to**: Any resource or module with a numeric count
- **Type**: `number`
- **Use Case**: Create N identical resources with indexed attributes

### Syntax
```hcl
resource "azurerm_storage_account" "example" {
  count                    = var.instance_count
  name                     = "${var.base_name}${count.index + 1}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

### Key Points
- `count.index` is 0-based.
- To generate unique names, append `count.index` or use a lookup list.
- Changing `count` value triggers create/destroy of instances.

### Example with List Lookup
```hcl
variable "storage_names" {
  type    = list(string)
  default = ["acct1", "acct2"]
}

resource "azurerm_storage_account" "example" {
  count                    = length(var.storage_names)
  name                     = var.storage_names[count.index]
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

## 2. `for_each`
- **Applies to**: Resources or modules using map or set of strings
- **Type**: `map(...)` or `set(...)`
- **Use Case**: Create one resource per key/value pair or unique element

### Syntax (Map)
```hcl
variable "storage_map" {
  type = map(string)
  default = {
    primary   = "acct-primary"
    secondary = "acct-secondary"
  }
}

resource "azurerm_storage_account" "example" {
  for_each                 = var.storage_map
  name                     = each.value
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

### Syntax (Set)
```hcl
variable "storage_set" {
  type    = set(string)
  default = ["acct1", "acct2"]
}

resource "azurerm_storage_account" "example" {
  for_each                 = var.storage_set
  name                     = each.value
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

### Key Points
- `each.key` and `each.value` for maps; for sets only `each.value`.
- Resources are addressed by `resource_name[each.key]`.
- Ordering is not guaranteed; only unique elements allowed.

## 3. `for` Loops in Expressions
- **Applies to**: Value expressions (locals, variables, outputs)
- **Use Case**: Transform collections, generate complex expressions

### Syntax
```hcl
# Generate names for outputs
output "storage_names" {
  value = [for sa in azurerm_storage_account.example : sa.name]
}
```

### Key Points
- Returns a list of evaluated expressions
- Can include conditional filters
- Useful in `locals`, `variables`, and `outputs`

```hcl
locals {
  rg_names = [for rg in azurerm_resource_group.example : rg.name]
}

# With conditional filtering
locals {
  production_storage = [for sa in azurerm_storage_account.example : sa.name if sa.tags.environment == "production"]
}
```

## 4. `depends_on`
- **Applies to**: Any resource or module
- **Type**: `list` of resource references
- **Use Case**: Define explicit dependencies when implicit dependencies are insufficient

### Syntax
```hcl
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Explicit dependency
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
}
```

### Types of Dependencies

#### Implicit Dependencies (Preferred)
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "my-resources"
  location = "East US"
}

resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name  # Implicit dependency
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

#### Explicit Dependencies (Use Sparingly)
```hcl
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # When no implicit reference exists but dependency is needed
  depends_on = [
    azurerm_role_assignment.storage_admin
  ]
}
```

### Key Points
- Use implicit dependencies whenever possible (more maintainable)
- Use explicit `depends_on` only when implicit dependencies aren't sufficient
- Common use cases: permissions, network policies, or complex cross-resource dependencies

## 5. `lifecycle`
- **Applies to**: Any resource
- **Type**: Configuration block
- **Use Case**: Control resource behavior during terraform operations

### Basic Lifecycle Arguments

#### `create_before_destroy`
```hcl
resource "azurerm_virtual_machine" "web" {
  name     = "web-server"
  location = var.location
  # ... other configuration

  lifecycle {
    create_before_destroy = true
  }
}
```
- Creates the replacement resource before destroying the original
- Useful for resources that can't have downtime
- **NOTE**: By default, if create_before_destroy is not set, Terraform will destroy the existing resource before creating the new one during updates. This can cause downtime if the resource is critical.

#### `prevent_destroy`
```hcl
resource "azurerm_storage_account" "critical" {
  name     = "critical-data-storage"
  location = var.location
  # ... other configuration

  lifecycle {
    prevent_destroy = true
  }
}
```
- Prevents accidental deletion of critical resources
- Must be removed from configuration before resource can be destroyed
- Only protects when the argument is present in configuration

#### `ignore_changes`
```hcl
resource "azurerm_virtual_machine" "web" {
  name     = "web-server"
  location = var.location
  tags = {
    environment = "production"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere
      tags,
      # Ignore changes to specific nested attributes
      tags["Name"],
      # Ignore changes to list elements
      network_interface_ids[0]
    ]
  }
}
```
- Ignores changes to specified attributes during `terraform plan` and `apply`
- Attributes are considered during create operations but ignored during updates
- Special keyword `all` can be used to ignore all attributes
- Only attributes defined by the resource type can be ignored

#### `ignore_changes` with `all`
```hcl
resource "azurerm_storage_account" "external" {
  name     = "externally-managed-storage"
  location = var.location
  # ... other configuration

  lifecycle {
    ignore_changes = all
  }
}
```

#### `replace_triggered_by`
```hcl
resource "azurerm_virtual_machine" "web" {
  name     = "web-server"
  location = var.location
  # ... other configuration

  lifecycle {
    replace_triggered_by = [
      # Replace VM when storage account connection string changes
      azurerm_storage_account.example.primary_connection_string,
      # Replace when any instance of a multi-instance resource changes
      azurerm_network_security_group.web
    ]
  }
}
```
- **Added in Terraform 1.2**
- Forces replacement when referenced items change
- Can reference resources, instances, or specific attributes
- Works with `count.index` and `each.key` for multi-instance resources
- Only managed resources can be referenced

#### Advanced `replace_triggered_by` Example
```hcl
resource "azurerm_app_service" "web" {
  count    = 3
  name     = "web-app-${count.index}"
  location = var.location
  # ... other configuration

  lifecycle {
    replace_triggered_by = [
      # Replace each app service when corresponding database changes
      azurerm_sql_database.web[count.index].connection_string
    ]
  }
}
```

### Custom Condition Checks

Terraform supports `precondition` and `postcondition` blocks within the `lifecycle` block to specify assumptions and guarantees about resource behavior.

#### Preconditions
```hcl
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                = "example-keyvault"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  lifecycle {
    # Ensure the key vault name meets naming requirements
    precondition {
      condition     = length(self.name) >= 3 && length(self.name) <= 24
      error_message = "Key Vault name must be between 3 and 24 characters."
    }

    # Ensure we're using the correct tenant
    precondition {
      condition     = data.azurerm_client_config.current.tenant_id != ""
      error_message = "Azure tenant ID must be available."
    }
  }
}
```

#### Postconditions
```hcl
resource "azurerm_virtual_machine" "example" {
  name     = "example-vm"
  location = var.location
  vm_size  = var.vm_size
  # ... other configuration

  lifecycle {
    # Verify the VM was created with the expected configuration
    postcondition {
      condition     = self.vm_size == var.vm_size
      error_message = "VM was not created with the expected size: ${var.vm_size}"
    }

    # Ensure VM is in running state after creation
    postcondition {
      condition     = self.power_state == "running"
      error_message = "VM must be in running state after creation."
    }
  }
}
```

#### Data Source Preconditions
```hcl
data "azurerm_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name

  lifecycle {
    # Ensure the VM exists and is in the expected state
    precondition {
      condition     = self.power_state == "running"
      error_message = "The referenced VM must be in running state."
    }
  }
}
```

#### Complex Condition Examples
```hcl
resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  lifecycle {
    # Validate storage account name format
    precondition {
      condition = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
      error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
    }

    # Ensure premium tier uses appropriate replication
    precondition {
      condition = !(var.account_tier == "Premium" && !contains(["LRS", "ZRS"], var.replication_type))
      error_message = "Premium storage accounts only support LRS and ZRS replication types."
    }

    # Verify storage account was created successfully
    postcondition {
      condition     = self.primary_blob_endpoint != ""
      error_message = "Storage account was not created successfully - missing blob endpoint."
    }

    # Ensure HTTPS is enabled for production environments
    postcondition {
      condition = var.environment != "production" || self.enable_https_traffic_only == true
      error_message = "HTTPS traffic must be enabled for production storage accounts."
    }
  }
}
```

### Key Points for Lifecycle Conditions

#### Preconditions
- Checked **before** the resource is created or updated
- Use `self` to reference the current resource's planned values
- Can reference data sources, variables, and other resources
- Help validate assumptions before applying changes
- Provide early error detection

#### Postconditions
- Checked **after** the resource is created or updated
- Use `self` to reference the current resource's actual state
- Can verify that resources were configured correctly
- Help ensure guarantees about the final resource state
- Useful for validation and testing

#### Best Practices for Conditions
- Use meaningful error messages that help users understand the issue
- Keep conditions simple and focused on specific requirements
- Use `can()` function for safe evaluation of potentially invalid expressions
- Document complex conditions with comments
- Test conditions thoroughly in non-production environments

### Complete Lifecycle Example
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    # Validation before creation/update
    precondition {
      condition     = var.node_count >= 1 && var.node_count <= 100
      error_message = "Node count must be between 1 and 100."
    }

    precondition {
      condition     = can(regex("^[a-zA-Z0-9-]+$", var.cluster_name))
      error_message = "Cluster name can only contain alphanumeric characters and hyphens."
    }

    # Validation after creation/update
    postcondition {
      condition     = self.kube_config != null
      error_message = "Kubernetes cluster must have valid kube config."
    }

    postcondition {
      condition     = self.identity[0].principal_id != ""
      error_message = "Cluster must have a system-assigned managed identity."
    }

    # Lifecycle management
    create_before_destroy = true
    prevent_destroy       = var.environment == "production"

    ignore_changes = [
      default_node_pool[0].node_count,
      tags["last_updated"]
    ]

    replace_triggered_by = [
      azurerm_resource_group.rg.location
    ]
  }
}
```

## 6. `provider`
- **Applies to**: Any resource or module
- **Type**: Provider alias reference
- **Use Case**: Use alternate provider configurations for multi-region or multi-account deployments

### Syntax
```hcl
# Define multiple provider configurations
provider "azurerm" {
  features {}
  alias = "east"
  # Configuration for East US
}

provider "azurerm" {
  features {}
  alias = "west"
  # Configuration for West US
}

# Use specific provider
resource "azurerm_resource_group" "east" {
  provider = azurerm.east
  name     = "rg-east"
  location = "East US"
}

resource "azurerm_resource_group" "west" {
  provider = azurerm.west
  name     = "rg-west"
  location = "West US"
}
```

### Key Points
- Useful for multi-region deployments
- Can specify different credentials, subscriptions, or configurations
- Must define provider aliases in the root module

## Best Practices

### General Guidelines
- **Prefer implicit dependencies** over explicit `depends_on`
- **Use `for_each`** instead of `count` when resources need to be individually addressable
- **Use lifecycle rules judiciously** - they can hide important changes
- **Document complex meta-argument usage** with comments
- **Use conditions to validate assumptions** and provide better error messages

### Choosing Between `count` and `for_each`
```hcl
# Use count for: Simple numeric repetition
resource "azurerm_virtual_machine" "web" {
  count = var.web_server_count
  name  = "web-${count.index + 1}"
  # ...
}

# Use for_each for: Named resources or when you need to add/remove specific items
resource "azurerm_virtual_machine" "app_servers" {
  for_each = var.app_servers  # map or set
  name     = each.key
  size     = each.value.size
  # ...
}
```

### Lifecycle Best Practices
```hcl
resource "azurerm_storage_account" "example" {
  name     = var.storage_name
  location = var.location
  # ... configuration

  lifecycle {
    # Validate inputs before creation
    precondition {
      condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_name))
      error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
    }

    # Verify successful creation
    postcondition {
      condition     = self.primary_blob_endpoint != ""
      error_message = "Storage account creation failed - no blob endpoint."
    }

    # Prevent accidental deletion of production resources
    prevent_destroy = var.environment == "production"
    
    # Ignore changes to tags that might be modified by other tools
    ignore_changes = [
      tags["last_modified"],
      tags["backup_policy"]
    ]
    
    # Ensure zero-downtime updates
    create_before_destroy = true
  }
}
```

## Important Notes

### Literal Values Only
The `lifecycle` settings affect how Terraform constructs and traverses the dependency graph. As a result, **only literal values can be used** in lifecycle arguments because the processing happens too early for arbitrary expression evaluation.

```hcl
# ✅ Correct - literal values
lifecycle {
  create_before_destroy = true
  prevent_destroy       = true
  ignore_changes        = [tags, vm_size]
}

# ❌ Incorrect - expressions not allowed in lifecycle meta-arguments
lifecycle {
  create_before_destroy = var.enable_cbd  # Not allowed
  prevent_destroy       = var.environment == "prod"  # Not allowed
}

# ✅ Correct - expressions allowed in conditions
lifecycle {
  precondition {
    condition     = var.environment != "prod" || var.enable_backup == true
    error_message = "Backup must be enabled for production environments."
  }
}
```

## Summary
This comprehensive guide covers all Terraform meta-arguments including the complete lifecycle functionality with custom conditions. Use these patterns to create robust, maintainable infrastructure code that handles complex scenarios, validates assumptions, and provides clear error messages while following Terraform best practices.