# =============================================================================
# Remote Backend Configuration — staging
#
# State is stored in Azure Blob Storage with:
# - Automatic state locking (prevents concurrent applies)
# - Versioning enabled (restore previous state if corrupted)
# - Encryption at rest (Azure-managed keys)
# =============================================================================

terraform {
  required_version = ">= 1.7.0"
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterrastate19989"
    container_name       = "tfstate"
    key                  = "staging/terraform.tfstate"
  }
}
