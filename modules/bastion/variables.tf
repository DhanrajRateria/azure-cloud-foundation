variable "name" {
  type        = string
  description = "Name of the Azure Bastion host"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy Bastion into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "subnet_id" {
  type        = string
  description = "ID of the AzureBastionSubnet — must be named exactly AzureBastionSubnet"
}

variable "sku" {
  type        = string
  default     = "Basic"
  description = "Bastion SKU: Basic (no tunneling) or Standard (native client, tunneling)"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be Basic or Standard."
  }
}

variable "copy_paste_enabled" {
  type        = bool
  default     = true
  description = "Allow copy/paste in Bastion sessions"
}

variable "file_copy_enabled" {
  type        = bool
  default     = false
  description = "Allow file copy in Bastion sessions — Standard SKU only"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
