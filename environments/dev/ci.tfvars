# Variable values for CI pipeline
# Safe to commit — contains no secrets
# Secrets (client_id, client_secret) come from GitHub Secrets as env vars

environment    = "dev"
location       = "southeastasia"
location_short = "sea"
cost_center    = "platform-engineering"

hub_cidr   = "10.0.0.0/16"
spoke_cidr = "10.1.0.0/16"

bastion_subnet_cidr          = "10.0.1.0/26"
firewall_subnet_cidr         = "10.0.2.0/26"
shared_subnet_cidr           = "10.0.3.0/24"
aks_subnet_cidr              = "10.1.1.0/24"
db_subnet_cidr               = "10.1.2.0/24"
private_endpoint_subnet_cidr = "10.1.3.0/24"

budget_amount_hub   = 20
budget_amount_spoke = 50
budget_start_date   = "2025-03-01"
