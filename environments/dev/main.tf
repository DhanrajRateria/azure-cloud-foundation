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
  sku                 = "Standard" # Basic SKU retires September 2026
  copy_paste_enabled  = true

  tags = local.common_tags
}

# ── Centralized Log Analytics Workspace ──────────────────────────────────────
# Lives in the Hub. Every resource in every Spoke sends diagnostics here.
# One workspace per environment — dev logs stay in dev workspace.
module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = "law-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  retention_days      = 30
  daily_quota_gb      = 1

  tags = local.common_tags
}
# ── Private DNS Zone — Key Vault ──────────────────────────────────────────────
# This zone overrides public DNS resolution for Key Vault URLs.
# When anything inside the Spoke VNet resolves *.vault.azure.net,
# Azure DNS checks this zone first and returns the private endpoint IP.
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = local.common_tags
}

# Link the DNS zone to the Spoke VNet so resources inside it use this zone
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  name                  = "link-kv-spoke-${var.environment}"
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.spoke_vnet.vnet_id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Also link to Hub VNet so Hub resources (Bastion, management VMs) can resolve it
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "link-kv-hub-${var.environment}"
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.hub_vnet.vnet_id
  registration_enabled  = false
  tags                  = local.common_tags
}

# ── Key Vault ─────────────────────────────────────────────────────────────────
module "keyvault" {
  source = "../../modules/keyvault"

  name                = "kv-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tenant_id           = var.tenant_id

  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # false in dev — easier cleanup

  private_endpoint_subnet_id = module.spoke_vnet.subnet_ids["snet-privateendpoints"]
  private_dns_zone_id        = azurerm_private_dns_zone.keyvault.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags
}

# ── Managed Identities ────────────────────────────────────────────────────────
# User-assigned managed identities are portable — you create them as standalone
# resources and assign them to multiple compute resources.
# This is the identity our AKS workloads will use to access Key Vault.

resource "azurerm_user_assigned_identity" "platform_ops" {
  name                = "id-platform-ops-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "app_workload" {
  name                = "id-app-workload-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.common_tags
}

# ── RBAC Assignments ──────────────────────────────────────────────────────────
module "rbac" {
  source = "../../modules/rbac"

  assignments = {
    # Platform ops identity gets Contributor on the spoke resource group
    # This is the identity used by CI/CD to deploy infrastructure
    "platform-ops-contributor" = {
      scope                = azurerm_resource_group.spoke.id
      role_definition_name = "Contributor"
      principal_id         = azurerm_user_assigned_identity.platform_ops.principal_id
      description          = "Platform ops automation identity — CI/CD deployments"
    }

    # App workload identity gets read-only on Key Vault secrets
    # This is the identity pods use to fetch secrets at runtime
    "app-workload-kv-secrets-user" = {
      scope                = module.keyvault.key_vault_id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = azurerm_user_assigned_identity.app_workload.principal_id
      description          = "App workload reads secrets from Key Vault at runtime"
    }

    # App workload identity gets read on Log Analytics
    # Allows the app to query its own logs programmatically
    "app-workload-law-reader" = {
      scope                = module.log_analytics.workspace_id
      role_definition_name = "Reader"
      principal_id         = azurerm_user_assigned_identity.app_workload.principal_id
      description          = "App workload reads its own logs from workspace"
    }

    # Platform ops gets Key Vault admin — can manage secrets and access policies
    "platform-ops-kv-admin" = {
      scope                = module.keyvault.key_vault_id
      role_definition_name = "Key Vault Administrator"
      principal_id         = azurerm_user_assigned_identity.platform_ops.principal_id
      description          = "Platform ops manages Key Vault secrets and configuration"
    }
  }
}

# ── Azure Policy ──────────────────────────────────────────────────────────────
# Policies are assigned at resource group scope in our setup.
# In a real multi-subscription enterprise, you'd assign at Management Group scope
# so a single assignment covers all subscriptions beneath it automatically.
# The policy definitions and logic are identical either way.

module "policy_spoke" {
  source = "../../modules/policy"

  environment = var.environment
  scope       = azurerm_resource_group.spoke.id
}

module "policy_hub" {
  source = "../../modules/policy"

  environment = var.environment
  scope       = azurerm_resource_group.hub.id
}

# ── Cost Budgets ──────────────────────────────────────────────────────────────
# Separate budgets for Hub and Spoke so you know which environment
# is generating cost. Hub costs are shared services (Bastion, Log Analytics).
# Spoke costs are workload resources (AKS, databases, etc.)

module "budget_hub" {
  source = "../../modules/budget"

  name        = "budget-hub-${var.environment}"
  scope       = azurerm_resource_group.hub.id
  amount      = var.budget_amount_hub
  alert_email = var.alert_email
  start_date  = var.budget_start_date
  thresholds  = [50, 75, 90, 100]
}

module "budget_spoke" {
  source = "../../modules/budget"

  name        = "budget-spoke-${var.environment}"
  scope       = azurerm_resource_group.spoke.id
  amount      = var.budget_amount_spoke
  alert_email = var.alert_email
  start_date  = var.budget_start_date
  thresholds  = [50, 75, 90, 100]
}
