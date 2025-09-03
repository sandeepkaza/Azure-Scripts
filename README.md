# Multi-Environment Azure Infrastructure Deployment

This repository provides a reusable Terraform configuration for deploying Azure infrastructure across multiple environments (dev, staging, prod).

## Directory Structure

```
├── infra/                          # Main Terraform configuration
│   ├── main.tf                     # Main infrastructure code
│   ├── variables.tf                # Variable definitions
│   └── outputs.tf                  # Output definitions
├── environments/                   # Environment-specific configurations
│   ├── dev/
│   │   └── terraform.tfvars.json   # Dev environment variables
│   ├── staging/
│   │   └── terraform.tfvars.json   # Staging environment variables
│   └── prod/
│       └── terraform.tfvars.json   # Production environment variables
└── .github/workflows/              # GitHub Actions workflows
    └── iac-terraform.yml          # Main deployment workflow
```

## Features

- **Multi-Environment Support**: Deploy to dev, staging, and production environments
- **Isolated State**: Each environment uses separate Terraform state
- **Environment-Specific Configuration**: Different settings per environment
- **Automated Deployment**: GitHub Actions workflow for CI/CD
- **Plan/Apply/Destroy**: Full lifecycle management

## Prerequisites

1. **Azure Service Principal** with appropriate permissions
2. **GitHub Repository Secrets** configured:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

## Usage

### Deploy to Development Environment

```bash
# Plan deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=dev --field action=plan

# Apply deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=dev --field action=apply

# Destroy infrastructure
gh workflow run "IaC - Terraform (Azure)" --field environment=dev --field action=destroy
```

### Deploy to Staging Environment

```bash
# Plan deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=staging --field action=plan

# Apply deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=staging --field action=apply
```

### Deploy to Production Environment

```bash
# Plan deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=prod --field action=plan

# Apply deployment
gh workflow run "IaC - Terraform (Azure)" --field environment=prod --field action=apply
```

## Environment Configurations

### Development (dev)
- **Location**: East US
- **Tags**: Environment=dev, Project=super-mario-game

### Staging (staging)
- **Location**: East US 2
- **Tags**: Environment=staging, Project=super-mario-game

### Production (prod)
- **Location**: West US 2
- **Tags**: Environment=prod, Project=super-mario-game, Critical=true

## Resources Created

Each environment deploys:
- Resource Group
- Container Registry
- Container App Environment
- Container App
- Key Vault
- Application Insights
- Log Analytics Workspace
- User Assigned Managed Identity

## Adding New Environments

1. Create a new directory under `environments/`
2. Create `terraform.tfvars.json` with environment-specific values
3. Update the workflow inputs to include the new environment
4. Commit and push changes

## Security Notes

- Service principal credentials are stored as GitHub secrets
- Terraform state is stored in Azure Storage Account
- Each environment has isolated state and resources
- Production environment includes additional security tags

## Troubleshooting

- Check GitHub Actions logs for detailed error messages
- Verify Azure service principal has required permissions
- Ensure GitHub secrets are properly configured
- Check Terraform state in Azure Storage if issues persist
