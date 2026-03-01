locals {
  common_tags = {
    environment = var.environment
    owner       = "platform-team"
    cost-center = var.cost_center
    managed-by  = "terraform"
    project     = "azure-cloud-foundation"
  }
}
