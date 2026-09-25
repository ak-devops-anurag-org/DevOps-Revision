# Azure provider conventions

## Backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<project>-tfstate-rg"
    storage_account_name = "<project>tfstate<suffix>"  # must be globally unique, lowercase, no dashes
    container_name       = "tfstate"
    key                  = "<env>/<component>.tfstate"
  }
}
```

Bootstrap the resource group + storage account once, outside the config that
consumes them as backend. Enable blob versioning and soft-delete on the
storage account so a bad `apply` doesn't lose state history.

## Resource groups & naming

- One resource group per environment per major component
  (`<project>-<env>-network-rg`, `<project>-<env>-aks-rg`) rather than one
  giant RG for everything — makes teardown and RBAC scoping much cleaner.
- Azure naming rules are stricter than AWS/GCP for some resource types
  (storage accounts: lowercase alphanumeric only, 3–24 chars, globally
  unique) — check the specific resource's naming constraints before
  generating names programmatically.

## AKS-specific patterns

```hcl
resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.project}-${var.environment}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "${var.project}-${var.environment}"

  default_node_pool {
    name       = "system"
    vm_size    = var.system_node_vm_size
    node_count = var.system_node_count
    # prefer a node pool with only_critical_addons_only = true here,
    # and put workloads on a separate user node pool
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"   # or "kubenet" — azure CNI needed for most
                                 # enterprise/banking network policy requirements
  }
}
```

Notes relevant to a banking/regulated environment:
- Prefer `private_cluster_enabled = true` unless there's an explicit reason
  the API server needs a public endpoint — flag this choice rather than
  defaulting silently.
- Use a separate `azurerm_kubernetes_cluster_node_pool` resource for user
  workloads rather than overloading the default system pool.
- RBAC: enable `role_based_access_control_enabled = true` and prefer Azure
  AD integration (`azure_active_directory_role_based_access_control` block)
  over local cluster admin accounts.
- Node pool changes (VM size, availability zones) generally force
  replacement — check the plan output carefully before applying node pool
  edits on a live cluster; consider `create_before_destroy` on the node pool
  resource to avoid downtime.

## Tagging

```hcl
tags = {
  environment = var.environment
  project     = var.project
  owner       = var.owner
  managed_by  = "terraform"
}
```

Azure tag keys are case-sensitive and there's a hard limit of 50 tags per
resource — keep the tag set small and consistent rather than sprawling.