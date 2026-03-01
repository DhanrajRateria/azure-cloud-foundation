output "bastion_id" {
  value       = azurerm_bastion_host.this.id
  description = "Resource ID of the Bastion host"
}

output "bastion_name" {
  value       = azurerm_bastion_host.this.name
  description = "Name of the Bastion host"
}

output "public_ip_address" {
  value       = azurerm_public_ip.bastion.ip_address
  description = "Public IP address of the Bastion host"
}

output "public_ip_id" {
  value       = azurerm_public_ip.bastion.id
  description = "Resource ID of the Bastion public IP — used for diagnostic settings"
}
