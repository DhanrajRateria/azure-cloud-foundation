#!/bin/bash
# =============================================================================
# Bootstrap Script: Creates Azure Storage for Terraform Remote State
#
# Run this ONCE before any terraform init/plan/apply.
# After this runs, all infrastructure is managed by Terraform.
#
# Usage: bash bootstrap/create-backend.sh
# =============================================================================

set -euo pipefail
# set -e  → exit immediately if any command fails
# set -u  → treat unset variables as errors
# set -o pipefail → if any command in a pipe fails, the whole pipe fails

# ── Configuration ─────────────────────────────────────────────────────────────
LOCATION="southeastasia"  # Choose a region close to your team and resources
BACKEND_RG="rg-terraform-state"
STORAGE_ACCOUNT="stterrastate$RANDOM"   # $RANDOM ensures globally unique name
CONTAINER_NAME="tfstate"
ENVIRONMENT_TAGS="environment=bootstrap owner=platform-team cost-center=platform"

echo "============================================="
echo " Azure Cloud Foundation — Bootstrap"
echo "============================================="
echo "Location:        $LOCATION"
echo "Resource Group:  $BACKEND_RG"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container:       $CONTAINER_NAME"
echo "============================================="
echo ""

# ── Step 1: Create dedicated Resource Group for Terraform state ────────────────
echo "▶ Creating resource group: $BACKEND_RG"
az group create \
  --name "$BACKEND_RG" \
  --location "$LOCATION" \
  --tags $ENVIRONMENT_TAGS
echo "✅ Resource group created"
echo ""

# ── Step 2: Create Storage Account ────────────────────────────────────────────
# Standard_LRS = Locally Redundant Storage (3 copies in same datacenter)
# Sufficient for state files — they're not customer data
echo "▶ Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$BACKEND_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags $ENVIRONMENT_TAGS
echo "✅ Storage account created"
echo ""

# ── Step 3: Enable Versioning ──────────────────────────────────────────────────
# Versioning keeps history of every state file change.
# If state gets corrupted, you can restore a previous version.
echo "▶ Enabling blob versioning"
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$BACKEND_RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30
echo "✅ Versioning enabled (30-day retention)"
echo ""

# ── Step 4: Create Blob Container ─────────────────────────────────────────────
echo "▶ Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login
echo "✅ Container created"
echo ""

# ── Step 5: Output backend config ─────────────────────────────────────────────
echo "============================================="
echo " ✅ Bootstrap Complete!"
echo "============================================="
echo ""
echo "Copy the following into each environment's backend.tf:"
echo ""
echo '  backend "azurerm" {'
echo "    resource_group_name  = \"$BACKEND_RG\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo '    key                  = "ENV_NAME/terraform.tfstate"'
echo '  }'
echo ""
echo "Replace ENV_NAME with: dev | staging | prod"
echo ""

# ── Step 6: Save config to file for reference ─────────────────────────────────
cat > bootstrap/backend-config.txt << CONF
resource_group_name  = "$BACKEND_RG"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
CONF

echo "📄 Config saved to bootstrap/backend-config.txt"
