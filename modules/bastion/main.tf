# =============================================================================
# Azure Bastion Module
#
# Bastion requires two resources:
# 1. A Public IP — Bastion itself has a public IP (that's how users reach it)
#    but the VMs it connects TO have no public IP. This is the key distinction.
# 2. The Bastion host resource itself
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
  }
}

# Bastion needs a static public IP — this is Bastion's own IP, not the VMs'.
# Users connect to this IP via the Azure portal over HTTPS (443).
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Bastion requires Standard SKU public IP — Basic SKU is not supported
  sku               = "Standard"
  allocation_method = "Static"

  tags = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  copy_paste_enabled = var.copy_paste_enabled
  # file_copy requires Standard SKU — only set it if SKU is Standard
  file_copy_enabled = var.sku == "Standard" ? var.file_copy_enabled : false

  ip_configuration {
    name                 = "ipconfig-bastion"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}
