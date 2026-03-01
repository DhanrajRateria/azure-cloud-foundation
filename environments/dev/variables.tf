variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "location_short" {
  type        = string
  description = "Short location name for resource naming (e.g. eus for eastus)"
}

variable "hub_cidr" {
  type        = string
  description = "CIDR block for the Hub VNet"
}

variable "spoke_cidr" {
  type        = string
  description = "CIDR block for the Spoke VNet"
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "CIDR for AzureBastionSubnet (must be /26 or larger)"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR for AzureFirewallSubnet"
}

variable "shared_subnet_cidr" {
  type        = string
  description = "CIDR for shared services subnet in Hub"
}

variable "aks_subnet_cidr" {
  type        = string
  description = "CIDR for AKS node pool subnet"
}

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR for database subnet"
}

variable "private_endpoint_subnet_cidr" {
  type        = string
  description = "CIDR for private endpoints subnet"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag value for billing attribution"
}

variable "alert_email" {
  type        = string
  description = "Email address for budget and alert notifications"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "budget_amount_hub" {
  type        = number
  description = "Monthly budget in USD for Hub resource group"
}

variable "budget_amount_spoke" {
  type        = number
  description = "Monthly budget in USD for Spoke resource group"
}

variable "budget_start_date" {
  type        = string
  description = "Budget period start date — must be first of a month, format YYYY-MM-DD"
}
