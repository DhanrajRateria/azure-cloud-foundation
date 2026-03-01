variable "name" {
  type        = string
  description = "Name of the Log Analytics Workspace"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the workspace into"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "sku" {
  type        = string
  default     = "PerGB2018"
  description = "Pricing SKU. PerGB2018 is pay-as-you-go — recommended for most cases."
}

variable "retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain log data. Min 30, max 730. After this, data is deleted."

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  type        = number
  default     = 1
  description = "Daily ingestion cap in GB. Prevents runaway costs if something logs excessively. -1 means unlimited."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
