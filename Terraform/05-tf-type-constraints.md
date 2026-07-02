# Terraform Type Constraints - Simply Explained

## Overview
This guide explains Terraform’s **type constraints** for variables, covering primitive types, complex structures, and advanced patterns. Enforcing types helps catch configuration errors early and ensures robust, maintainable infrastructure as code.

## Primitive Types

### 1. string
- Text values
- Example: environment names, resource prefixes

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}
```

### 2. number
- Numeric values (integers, floats)
- Example: disk size GB, instance counts

```hcl
variable "disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 80
}
```

### 3. bool
- Boolean values (`true` or `false`)
- Example: flags to enable/disable features

```hcl
variable "delete_os_disk" {
  type        = bool
  description = "Delete OS disk on VM termination"
  default     = true
}
```

## Complex Types

### 4. list(<TYPE>)
- Ordered collection of elements of the same type
- Access elements by index (0-based)

```hcl
variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions"
  default     = ["West Europe", "North Europe", "East US"]
}

# Usage: first element
resource "azurerm_resource_group" "rg" {
  location = var.allowed_locations[0]
}
```

### 5. map(<TYPE>)
- Unordered key-value pairs where all values share the same type
- Access by key

```hcl
variable "resource_tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {
    environment = "staging"
    managed_by  = "terraform"
    department  = "devops"
  }
}

resource "azurerm_resource_group" "rg" {
  tags = var.resource_tags
}
```

### 6. set(<TYPE>)
- Unordered collection of unique elements
- No index-based access
- Useful for validating membership via lifecycle or `contains`

```hcl
variable "allowed_vm_sizes" {
  type        = set(string)
  description = "Valid VM sizes for deployments"
  default     = ["Standard_B1s", "Standard_D2s_v3"]
}

# Use contains() in validation or lifecycle hooks
```

## Advanced Types

### 7. tuple([<TYPE1>, <TYPE2>, ...])
- Ordered sequence of elements with fixed types
- Access via `element()` function

```hcl
variable "network_config" {
  type        = tuple([string, string, number])
  description = "[vnet_cidr, subnet_cidr, subnet_mask]"
  default     = ["10.0.0.0/16", "10.0.1.0/24", 24]
}

resource "azurerm_virtual_network" "vnet" {
  address_space = [
    element(var.network_config, 0)
  ]
}

resource "azurerm_subnet" "subnet" {
  address_prefix = element(var.network_config, 1)
  subnet_mask    = element(var.network_config, 2)
}
```

### 8. object({ <ATTR1> = <TYPE1>, <ATTR2> = <TYPE2>, ... })
- Complex nested type with named attributes
- Ensures strict schema for compound data

```hcl
variable "vm_config" {
  type = object({
    sku       = string
    publisher = string
    offer     = string
    version   = string
  })
  description = "VM image configuration"
  default = {
    sku       = "16.04-LTS"
    publisher = "Canonical"
    offer     = "UbuntuServer"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  source_image_reference {
    publisher = var.vm_config.publisher
    offer     = var.vm_config.offer
    sku       = var.vm_config.sku
    version   = var.vm_config.version
  }
}
```

## Best Practices
1. **Always specify types** to catch errors early.  
2. **Use `validation` blocks** for additional constraints (e.g., allowed values):
    ```hcl
    variable "environment" {
      type    = string
      default = "dev"
      validation {
        condition     = contains(["dev", "staging", "prod"], var.environment)
        error_message = "Environment must be dev, staging, or prod."
      }
    }
    ```
3. **Prefer primitive and simple complex types** when possible; use `object` for structured data.
4. **Document variable purposes** and defaults for clarity.

This guide summarizes Terraform type constraints with examples for robust input validation and clear infrastructure code.