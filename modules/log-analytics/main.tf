# =============================================================================
# Log Analytics Workspace Module
#
# Central logging destination for all Azure resources.
# Every VNet, NSG, Key Vault, and Storage Account sends diagnostic
# logs here. One workspace per environment, in the Hub.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags
}

# ── Diagnostic Solutions ──────────────────────────────────────────────────────
# Solutions are add-ons that parse specific log types into structured tables.
# SecurityInsights enables Azure Sentinel-compatible security queries.

resource "azurerm_log_analytics_solution" "security" {
  solution_name         = "Security"
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name
  resource_group_name   = var.resource_group_name
  location              = var.location

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = var.tags
}
