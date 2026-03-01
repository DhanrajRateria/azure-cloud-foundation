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
