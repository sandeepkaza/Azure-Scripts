Purpose
This document shows step-by-step instructions to run Terraform IaC from GitHub Actions against Azure. It creates a reusable workflow that performs terraform init/plan and can apply on manual dispatch.

Checklist
- Create Azure service principal with Contributor rights (or scoped least-privilege role)
- Add GitHub secret AZURE_CREDENTIALS containing the service principal JSON
- Push Terraform code to the repo under `Terraform/` (or update TF_WORKING_DIR in the workflow)
- Run workflow via push to main or via Manual (Actions -> workflow_dispatch)

1) Create an Azure service principal (locally or Cloud Shell)
- Log in: az login
- Create SP and get JSON credentials:
  az ad sp create-for-rbac --name "github-actions-terraform" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID> --sdk-auth

- Copy the resulting JSON. It looks like:
  {
    "clientId": "...",
    "clientSecret": "...",
    "subscriptionId": "...",
    "tenantId": "...",
    "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
    "resourceManagerEndpointUrl": "https://management.azure.com/",
    "activeDirectoryGraphResourceId": "https://graph.windows.net/",
    "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
    "galleryEndpointUrl": "https://gallery.azure.com/",
    "managementEndpointUrl": "https://management.core.windows.net/"
  }

2) Add GitHub secret
- In your repo, go to Settings -> Secrets -> Actions -> New repository secret
- Name: AZURE_CREDENTIALS
- Value: paste the JSON from the previous step

3) Prepare your Terraform code
- Put your .tf files in `Terraform/` (or another folder and set TF_WORKING_DIR in the workflow)
- Ensure your Terraform backend and providers are configured; for remote state use Azure Storage / Terraform Cloud as appropriate.

Backend (optional automatic bootstrap)
- The workflow can create an Azure Storage account + container to hold Terraform state when you provide the following repository secrets:
  - BACKEND_RG: resource group name for the backend (e.g. tfstate-rg)
  - BACKEND_STORAGE_ACCOUNT: storage account name (must be globally unique)
  - BACKEND_CONTAINER: blob container name (e.g. tfstate)
  - BACKEND_LOCATION: Azure region (default: eastus)

Set those secrets (Settings -> Secrets -> Actions) if you want the workflow to create the backend automatically on runs.

4) Trigger the workflow
- Push changes to `main` under the Terraform folder, or open Actions -> select "IaC - Terraform (Azure)" -> Run workflow (manual)
- The workflow will run terraform init and plan. If you use manual dispatch it will also apply.

Pull requests
- When you open a pull request that touches Terraform files the workflow will run plan and post the plan output as a comment on the PR (truncated if large). This is useful to review changes before applying.

Notes and troubleshooting
- Least privilege: prefer assigning narrower roles than Contributor.
- If you need approvals before apply, remove the automatic apply step and use the plan artifact for review.
- The workflow uses hashicorp/setup-terraform and azure/login actions.

Contact
If you want, I can:
- Add a job that stores Terraform state in an Azure Storage backend and initialize it automatically
- Add environment protection rules and manual approval gates
- Implement workspace-specific variable files and secret passing

*** End of instructions ***
