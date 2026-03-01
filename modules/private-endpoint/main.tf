# =============================================================================
# Private Endpoint Module
#
# A Private Endpoint is a network interface with a private IP from your
# subnet's address space. It represents a specific Azure service (Key Vault,
# Storage, SQL, etc.) inside your VNet.
#
# Traffic flow:
#   App in AKS subnet
#     → resolves kv-dev.vault.azure.net
#     → Private DNS Zone returns 10.1.3.4 (private IP)
#     → traffic goes to Private Endpoint NIC at 10.1.3.4
#     → Azure routes to Key Vault internally
#     → never touches public internet
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

resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-connection"
    private_connection_resource_id = var.target_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
    # is_manual_connection = false means Azure auto-approves the connection
    # For third-party services, you'd set this to true and wait for manual approval
  }

  private_dns_zone_group {
    name                 = "${var.name}-dns-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}
