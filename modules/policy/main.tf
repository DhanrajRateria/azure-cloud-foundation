# =============================================================================
# Azure Policy Module
#
# Creates policy definitions and assigns them at the given scope.
#
# Policy definitions = the rules themselves (what to check, what to do)
# Policy assignments = applying those rules to a specific scope
#
# An unassigned definition does nothing.
# An assigned definition without scope does nothing.
# Both are needed for enforcement.
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

# ── Deny Public IP ────────────────────────────────────────────────────────────
resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip-${var.environment}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "[${upper(var.environment)}] Deny Public IP Creation"
  description  = "Prevents creation of public IP addresses. All access must go through Bastion."

  policy_rule = file("${path.module}/definitions/deny-public-ip.json")
}

resource "azurerm_resource_group_policy_assignment" "deny_public_ip" {
  name                 = "deny-public-ip-${var.environment}"
  resource_group_id    = var.scope
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  display_name         = "[${upper(var.environment)}] Deny Public IP Creation"
  description          = "Assigned by Terraform — azure-cloud-foundation"

  # In prod this would be Deny. In dev we use Audit so engineers
  # can still experiment without being fully blocked.
  # The Bastion NSG is the real enforcement mechanism in dev.
  enforce = var.environment == "prod" ? true : false
}

# ── Deny Open NSG Rules ───────────────────────────────────────────────────────
resource "azurerm_policy_definition" "deny_open_nsg" {
  name         = "deny-open-nsg-${var.environment}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "[${upper(var.environment)}] Deny Open NSG Rules (0.0.0.0/0)"
  description  = "Blocks NSG rules that allow inbound from Internet, *, or 0.0.0.0/0."

  policy_rule = file("${path.module}/definitions/deny-open-nsg.json")

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect", description = "Audit or Deny" }
      allowedValues = ["Audit", "Deny"]
      defaultValue  = "Audit"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "deny_open_nsg" {
  name                 = "deny-open-nsg-${var.environment}"
  resource_group_id    = var.scope
  policy_definition_id = azurerm_policy_definition.deny_open_nsg.id
  display_name         = "[${upper(var.environment)}] Deny Open NSG Rules"

  # Prod = Deny, dev/staging = Audit
  parameters = jsonencode({
    effect = {
      value = var.environment == "prod" ? "Deny" : "Audit"
    }
  })
}

# ── Require Tags ──────────────────────────────────────────────────────────────
resource "azurerm_policy_definition" "require_tags" {
  name        = "require-tags-${var.environment}"
  policy_type = "Custom"
  mode        = "Indexed"
  # Indexed mode = only applies to resource types that support tags.
  # This prevents false positives on things like role assignments
  # which don't support tags at all.
  display_name = "[${upper(var.environment)}] Require Mandatory Tags"
  description  = "Audits resources missing environment, owner, or cost-center tags."

  policy_rule = file("${path.module}/definitions/require-tags.json")
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "require-tags-${var.environment}"
  resource_group_id    = var.scope
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "[${upper(var.environment)}] Require Mandatory Tags"
  enforce              = true
  # Tags are always Audit, never Deny — you don't want to block resources
  # just because a tag is missing. You want visibility to fix them.
}

# ── Enforce HTTPS on Storage ──────────────────────────────────────────────────
resource "azurerm_policy_definition" "https_storage" {
  name         = "enforce-https-storage-${var.environment}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "[${upper(var.environment)}] Enforce HTTPS-Only Storage Accounts"
  description  = "Denies storage accounts that allow HTTP traffic."

  policy_rule = file("${path.module}/definitions/enforce-https-storage.json")
}

resource "azurerm_resource_group_policy_assignment" "https_storage" {
  name                 = "enforce-https-storage-${var.environment}"
  resource_group_id    = var.scope
  policy_definition_id = azurerm_policy_definition.https_storage.id
  display_name         = "[${upper(var.environment)}] Enforce HTTPS-Only Storage"
  enforce              = true
  # HTTPS enforcement is always Deny in all environments.
  # There is no legitimate reason to allow HTTP on storage in any env.
}
