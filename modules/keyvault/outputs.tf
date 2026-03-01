output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Resource ID of the Key Vault"
}

output "key_vault_name" {
  value       = azurerm_key_vault.this.name
  description = "Name of the Key Vault (includes random suffix)"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "URI for accessing the Key Vault — apps use this to fetch secrets"
}

output "private_ip_address" {
  value       = module.private_endpoint.private_ip_address
  description = "Private IP of the Key Vault private endpoint inside the VNet"
}
