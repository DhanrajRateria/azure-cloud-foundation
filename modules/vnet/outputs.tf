# =============================================================================
# VNet Module Outputs
#
# These values are consumed by other modules:
# - bastion module needs the bastion subnet ID
# - private-endpoint module needs the PE subnet ID
# - peering configs need the vnet_id
# =============================================================================

output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "The resource ID of the Virtual Network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "The name of the Virtual Network"
}

output "subnet_ids" {
  value       = { for k, v in azurerm_subnet.this : k => v.id }
  description = "Map of subnet name to subnet resource ID"
}

output "address_space" {
  value       = azurerm_virtual_network.this.address_space
  description = "The address space of the Virtual Network"
}
