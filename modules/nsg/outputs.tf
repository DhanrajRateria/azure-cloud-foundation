output "nsg_id" {
  value       = azurerm_network_security_group.this.id
  description = "The resource ID of the Network Security Group"
}

output "nsg_name" {
  value       = azurerm_network_security_group.this.name
  description = "The name of the Network Security Group"
}
