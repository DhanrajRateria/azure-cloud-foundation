# =============================================================================
# Key Vault Module
#
# Creates a Key Vault with:
# - RBAC authorization model (not legacy access policies)
# - Public network access DISABLED
# - Private endpoint for VNet-only access
# - Diagnostic logs sent to Log Analytics
# - Soft delete enabled (7-90 day recovery window)
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

# Key Vault names must be globally unique across all of Azure.
# We append a random suffix to guarantee uniqueness.
resource "random_string" "kv_suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_key_vault" "this" {
  name                = "${var.name}-${random_string.kv_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  # RBAC authorization model — modern approach.
  # The alternative is "access policies" which are vault-level and harder to audit.
  # RBAC lets you use standard Azure role assignments — same model as everything else.
  enable_rbac_authorization = true

  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # PUBLIC NETWORK ACCESS DISABLED
  # This is the critical zero-trust setting.
  # Even with the correct credentials, requests from the public internet
  # are rejected at the network layer — before auth is even checked.
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    # AzureServices bypass allows trusted Microsoft services (Azure Backup,
    # Azure Monitor, ARM) to access the vault even with public access disabled.
    # Without this, diagnostic settings would stop working.
  }

  tags = var.tags
}

# ── Private Endpoint ──────────────────────────────────────────────────────────
module "private_endpoint" {
  source = "../private-endpoint"

  name                 = "pe-${var.name}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  subnet_id            = var.private_endpoint_subnet_id
  target_resource_id   = azurerm_key_vault.this.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [var.private_dns_zone_id]

  tags = var.tags
}

# ── RBAC Assignments ──────────────────────────────────────────────────────────
# Grant roles on this Key Vault to service principals, managed identities, etc.
resource "azurerm_role_assignment" "kv" {
  for_each = var.rbac_assignments

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

# ── Diagnostic Settings ───────────────────────────────────────────────────────
# Every read, write, and delete operation on Key Vault is logged.
# This is your audit trail — who accessed which secret, when, from where.
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
    # AuditEvent captures every data-plane operation:
    # secret get, secret set, key sign, certificate create, etc.
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
