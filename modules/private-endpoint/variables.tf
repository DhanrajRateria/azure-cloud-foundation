variable "name" {
  type        = string
  description = "Name of the private endpoint"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the private endpoint into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the private endpoint NIC will be placed"
}

variable "target_resource_id" {
  type        = string
  description = "Resource ID of the service to connect privately (Key Vault, Storage, etc.)"
}

variable "subresource_names" {
  type        = list(string)
  description = "Subresource type to connect. e.g. ['vault'] for Key Vault, ['blob'] for Storage"
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "List of Private DNS Zone IDs to register the endpoint in"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
