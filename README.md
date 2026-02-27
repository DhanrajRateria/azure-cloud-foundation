# Azure Cloud Foundation

Enterprise-grade Azure cloud estate provisioned with Terraform.

## Architecture

Multi-environment (Dev/Staging/Prod) Hub-Spoke network topology with:
- Zero-trust network design using Private Endpoints
- Centralized logging via Log Analytics
- Azure Key Vault for secrets management
- Azure Bastion for secure access
- RBAC with least-privilege design
- Azure Policy for governance enforcement
- Cost budgets and alerting

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Network Design](docs/network-design.md)
- [RBAC Design](docs/rbac-design.md)
- [Security Model](docs/security-model.md)
- [Runbooks](docs/runbooks/)

## Environments

| Environment | Purpose | State File |
|-------------|---------|------------|
| dev | Development and testing | `dev/terraform.tfstate` |
| staging | Pre-production validation | `staging/terraform.tfstate` |
| prod | Production workloads | `prod/terraform.tfstate` |

## Getting Started

See [docs/getting-started.md](docs/getting-started.md)
