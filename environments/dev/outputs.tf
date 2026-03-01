output "hub_vnet_id" {
  value       = module.hub_vnet.vnet_id
  description = "Resource ID of the Hub VNet"
}

output "spoke_vnet_id" {
  value       = module.spoke_vnet.vnet_id
  description = "Resource ID of the Spoke VNet"
}

output "hub_subnet_ids" {
  value       = module.hub_vnet.subnet_ids
  description = "Map of Hub subnet names to IDs"
}

output "spoke_subnet_ids" {
  value       = module.spoke_vnet.subnet_ids
  description = "Map of Spoke subnet names to IDs"
}

output "bastion_name" {
  value       = module.bastion.bastion_name
  description = "Name of the Bastion host — use this in Azure portal to connect"
}

output "bastion_public_ip" {
  value       = module.bastion.public_ip_address
  description = "Public IP of the Bastion host"
}

output "log_analytics_workspace_id" {
  value       = module.log_analytics.workspace_id
  description = "Log Analytics Workspace ID — used when configuring diagnostic settings"
}

output "key_vault_name" {
  value       = module.keyvault.key_vault_name
  description = "Key Vault name — use this to add secrets via Azure CLI"
}

output "key_vault_uri" {
  value       = module.keyvault.key_vault_uri
  description = "Key Vault URI — apps use this to fetch secrets"
}

output "key_vault_private_ip" {
  value       = module.keyvault.private_ip_address
  description = "Private IP of Key Vault — only reachable from inside the VNet"
}
output "platform_ops_identity_id" {
  value       = azurerm_user_assigned_identity.platform_ops.id
  description = "Resource ID of platform ops managed identity — assign to CI/CD compute"
}

output "app_workload_identity_id" {
  value       = azurerm_user_assigned_identity.app_workload.id
  description = "Resource ID of app workload managed identity — assign to AKS pods"
}

output "app_workload_client_id" {
  value       = azurerm_user_assigned_identity.app_workload.client_id
  description = "Client ID of app workload identity — used in AKS workload identity annotation"
}

output "hub_budget_amount" {
  value       = module.budget_hub.budget_amount
  description = "Monthly budget for Hub resources in USD"
}

output "spoke_budget_amount" {
  value       = module.budget_spoke.budget_amount
  description = "Monthly budget for Spoke resources in USD"
}
