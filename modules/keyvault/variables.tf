variable "name" {
  type        = string
  description = "Name of the Key Vault. Must be globally unique, 3-24 chars, alphanumeric and hyphens only."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy Key Vault into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID — Key Vault uses this to validate identity tokens"
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "Key Vault SKU: standard or premium. Premium adds HSM-backed keys."

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Days to retain soft-deleted vaults and objects. Min 7, max 90."

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    When true, even admins cannot permanently delete the vault during retention period.
    Set to true in prod. Keep false in dev so you can clean up freely.
  EOT
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the Key Vault private endpoint"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS Zone ID for privatelink.vaultcore.azure.net"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID to send Key Vault audit logs to"
}

variable "rbac_assignments" {
  type = map(object({
    principal_id = string
    role         = string
    # Role options for Key Vault RBAC:
    # "Key Vault Administrator"       — full control
    # "Key Vault Secrets Officer"     — manage secrets
    # "Key Vault Secrets User"        — read secrets (for apps)
    # "Key Vault Reader"              — read metadata only
  }))
  default     = {}
  description = "Map of RBAC assignments to grant on this Key Vault"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
