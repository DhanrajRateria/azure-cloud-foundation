# =============================================================================
# VNet Module — main.tf
#
# Creates:
# - Virtual Network
# - Subnets (variable number, defined by caller)
# - VNet Peerings (Hub↔Spoke connections)
# - Network Watcher (required for diagnostics)
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

# ── Virtual Network ───────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

# ── Subnets ───────────────────────────────────────────────────────────────────
# We use for_each on the subnets map so callers define exactly which
# subnets they need. Hub gets Bastion+Firewall subnets. Spokes get
# AKS+DB+PrivateEndpoint subnets. Same module, different inputs.
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = each.value.service_endpoints

  # Delegation allows specific Azure services (like AKS) to inject
  # NICs directly into the subnet with full control
  dynamic "delegation" {
    for_each = each.value.delegation_name != null ? [1] : []
    content {
      name = each.value.delegation_name
      service_delegation {
        name    = each.value.delegation_service
        actions = each.value.delegation_actions
      }
    }
  }
}

# ── VNet Peerings ─────────────────────────────────────────────────────────────
# Peering is one-directional in Azure — you must create it on BOTH sides.
# This module creates the "local" side. The remote side is created when
# the Hub module peers back to the Spoke.
resource "azurerm_virtual_network_peering" "this" {
  for_each = var.peering_configs

  name                      = each.key
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.remote_vnet_id

  allow_forwarded_traffic = each.value.allow_forwarded_traffic
  allow_gateway_transit   = each.value.allow_gateway_transit
  use_remote_gateways     = each.value.use_remote_gateways
}
