# =============================================================================
# VNet Module Variables
# =============================================================================

variable "name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the VNet into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment (e.g. eastus, westeurope)"
}

variable "address_space" {
  type        = list(string)
  description = "CIDR address space for the VNet (e.g. [\"10.0.0.0/16\"])"
}

variable "subnets" {
  type = map(object({
    address_prefix     = string
    service_endpoints  = optional(list(string), [])
    delegation_name    = optional(string, null)
    delegation_service = optional(string, null)
    delegation_actions = optional(list(string), [])
  }))
  description = "Map of subnets to create. Key is subnet name, value is config."
}

variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "Custom DNS server IPs. Empty list uses Azure default DNS."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources in this module"
}

variable "peering_configs" {
  type = map(object({
    remote_vnet_id          = string
    allow_forwarded_traffic = optional(bool, true)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  }))
  default     = {}
  description = "Map of VNet peerings to create. Key is peering name."
}
