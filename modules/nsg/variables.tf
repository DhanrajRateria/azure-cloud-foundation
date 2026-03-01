variable "name" {
  type        = string
  description = "Name of the Network Security Group"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the NSG into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "security_rules" {
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = optional(string, null)
    destination_port_ranges    = optional(list(string), null)
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  default     = {}
  description = "Map of security rules. Use destination_port_range for single port, destination_port_ranges for multiple."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to associate this NSG with"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
