#!/bin/bash
# =============================================================================
# Creates a Service Principal for Terraform authentication
# Assigns Contributor role at subscription scope
# =============================================================================

set -euo pipefail

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SP_NAME="sp-terraform-cloud-foundation"

echo "▶ Creating Service Principal: $SP_NAME"
echo "  Subscription: $SUBSCRIPTION_ID"
echo ""

# Create SP and assign Contributor role
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --output json)

# Parse values
CLIENT_ID=$(echo $SP_OUTPUT | python3 -c "import sys,json; print(json.load(sys.stdin)['appId'])")
CLIENT_SECRET=$(echo $SP_OUTPUT | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
TENANT_ID=$(echo $SP_OUTPUT | python3 -c "import sys,json; print(json.load(sys.stdin)['tenant'])")

echo "============================================="
echo " ✅ Service Principal Created"
echo "============================================="
echo ""
echo "Add these to your shell environment (~/.bashrc):"
echo ""
echo "export ARM_CLIENT_ID=\"$CLIENT_ID\""
echo "export ARM_CLIENT_SECRET=\"$CLIENT_SECRET\""
echo "export ARM_TENANT_ID=\"$TENANT_ID\""
echo "export ARM_SUBSCRIPTION_ID=\"$SUBSCRIPTION_ID\""
echo ""
echo "⚠️  SAVE THE CLIENT SECRET — it won't be shown again"
echo "⚠️  NEVER commit these values to git"
