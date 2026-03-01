# =============================================================================
# RBAC Module
#
# Creates Azure role assignments.
#
# Why a dedicated module for something this simple?
# Because centralising all role assignments in one place means:
# 1. You can audit all access by reading one module call
# 2. You can enforce description requirements via variables
# 3. Adding/removing access is a code change — reviewed, versioned, audited
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

resource "azurerm_role_assignment" "this" {
  for_each = var.assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

  # skip_service_principal_aad_check speeds up assignment when
  # principal_id is a service principal or managed identity
  # (avoids an extra AAD lookup that sometimes fails on fresh identities)
  skip_service_principal_aad_check = true
}
