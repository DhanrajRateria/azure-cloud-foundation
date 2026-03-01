# =============================================================================
# Dev Environment — main.tf
#
# Deploys the complete dev network topology:
# - Hub VNet with Bastion and Firewall subnets
# - Spoke VNet with AKS, DB, and Private Endpoint subnets
# - NSGs for each subnet
# - Bidirectional Hub↔Spoke peering
# =============================================================================

# ── Resource Groups ───────────────────────────────────────────────────────────
resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-${var.environment}-${var.location_short}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-${var.environment}-${var.location_short}"
  location = var.location
  tags     = local.common_tags
}

# ── Hub VNet ──────────────────────────────────────────────────────────────────
module "hub_vnet" {
  source = "../../modules/vnet"

  name                = "vnet-hub-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  address_space       = [var.hub_cidr]

  subnets = {
    "AzureBastionSubnet" = {
      # Azure REQUIRES this exact name for Bastion — no exceptions
      address_prefix = var.bastion_subnet_cidr
    }
    "AzureFirewallSubnet" = {
      # Azure REQUIRES this exact name for Firewall — no exceptions
      address_prefix = var.firewall_subnet_cidr
    }
    "snet-shared" = {
      address_prefix    = var.shared_subnet_cidr
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }

  # Peer Hub → Spoke (spoke side created below)
  peering_configs = {
    "peer-hub-to-spoke-${var.environment}" = {
      remote_vnet_id          = module.spoke_vnet.vnet_id
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
    }
  }

  tags = local.common_tags
}

# ── Spoke VNet ────────────────────────────────────────────────────────────────
module "spoke_vnet" {
  source = "../../modules/vnet"

  name                = "vnet-spoke-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  address_space       = [var.spoke_cidr]

  subnets = {
    "snet-aks" = {
      address_prefix    = var.aks_subnet_cidr
      service_endpoints = ["Microsoft.ContainerRegistry"]
      # AKS requires subnet delegation to manage NICs
      delegation_name    = "aks-delegation"
      delegation_service = "Microsoft.ContainerService/managedClusters"
      delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
    "snet-db" = {
      address_prefix    = var.db_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    "snet-privateendpoints" = {
      address_prefix = var.private_endpoint_subnet_cidr
      # Private endpoints cannot have service endpoints or delegation
    }
  }

  # Peer Spoke → Hub (hub side created above)
  peering_configs = {
    "peer-spoke-to-hub-${var.environment}" = {
      remote_vnet_id          = module.hub_vnet.vnet_id
      allow_forwarded_traffic = true
      use_remote_gateways     = false
    }
  }

  tags = local.common_tags
}

# ── NSGs ──────────────────────────────────────────────────────────────────────

# Bastion subnet NSG — Azure mandates specific rules for Bastion to function
module "nsg_bastion" {
  source = "../../modules/nsg"

  name                = "nsg-bastion-${var.environment}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]

  security_rules = {
    "AllowHttpsInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Allow HTTPS from internet to Bastion portal"
    }
    "AllowGatewayManagerInbound" = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
      description                = "Azure Gateway Manager health probes — mandatory"
    }
    "AllowAzureLoadBalancerInbound" = {
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Azure Load Balancer health probe — mandatory"
    }
    "AllowBastionHostCommunicationInbound" = {
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Bastion host-to-host communication for scale-out"
    }
    "DenyAllInbound" = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound"
    }
    "AllowSshRdpOutbound" = {
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      description                = "Bastion reaches target VMs via SSH or RDP"
    }
    "AllowAzureCloudHttpsOutbound" = {
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
      description                = "Bastion calls Azure APIs for session management"
    }
    "AllowBastionHostCommunicationOutbound" = {
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Bastion host-to-host outbound for scale-out"
    }
    "AllowHttpOutbound" = {
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "CRL checks and GetSessionInformation — mandatory"
    }
    "DenyAllOutbound" = {
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other outbound"
    }
  }

  tags = local.common_tags
}

# AKS subnet NSG
module "nsg_aks" {
  source = "../../modules/nsg"

  name                = "nsg-aks-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  subnet_id           = module.spoke_vnet.subnet_ids["snet-aks"]

  security_rules = {
    "DenyInternetOutbound" = {
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "AKS nodes should not reach internet directly"
    }
  }

  tags = local.common_tags
}

# Private Endpoint subnet NSG
module "nsg_private_endpoints" {
  source = "../../modules/nsg"

  name                = "nsg-pe-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  subnet_id           = module.spoke_vnet.subnet_ids["snet-privateendpoints"]

  security_rules = {
    "DenyAllInbound" = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Private endpoints only accessible via private IP from VNet"
    }
  }

  tags = local.common_tags
}

# ── Azure Bastion ─────────────────────────────────────────────────────────────
# Bastion sits in the Hub. It connects to VMs in any peered Spoke
# over their private IPs. VMs need no public IP at all.
module "bastion" {
  source = "../../modules/bastion"

  name                = "bas-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]
  sku                 = "Basic"
  copy_paste_enabled  = true

  tags = local.common_tags
}
