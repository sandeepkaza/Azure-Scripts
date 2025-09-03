<#
Local helper to run Terraform from the repo. This script will:
 - allow optional backend configuration via environment variables
 - run terraform init/plan and optionally apply
Usage (PowerShell):
  Set-Location 'C:\Users\Admin\Documents\GitHub\3-Tier-Notes-Application'
  $env:TF_WORKING_DIR='Terraform'
  $env:BACKEND_RG='tfstate-rg'
  $env:BACKEND_STORAGE_ACCOUNT='uniquestorageacct'
  $env:BACKEND_CONTAINER='tfstate'
  $env:BACKEND_KEY='state.tfstate'
  .\Azure\ Scripts\run-terraform.ps1 -Apply
#>
param(
    [switch]$Apply
)

# ...existing code...
$tfDir = $env:TF_WORKING_DIR
if (-not $tfDir) { $tfDir = 'Terraform' }

Write-Host "Using TF dir: $tfDir"

Push-Location $tfDir
try {
    if ($env:BACKEND_STORAGE_ACCOUNT) {
        $backendArgs = @(
            "-backend-config=resource_group_name=$($env:BACKEND_RG)",
            "-backend-config=storage_account_name=$($env:BACKEND_STORAGE_ACCOUNT)",
            "-backend-config=container_name=$($env:BACKEND_CONTAINER)",
            "-backend-config=key=$($env:BACKEND_KEY)"
        )
        Write-Host "Initializing with backend..."
        terraform init @backendArgs -input=false
    } else {
        Write-Host "Initializing without remote backend..."
        terraform init -input=false
    }

    $rv = & terraform validate
    if ($LASTEXITCODE -ne 0) { Write-Host "Validate failed (exit code $LASTEXITCODE)" }
    & terraform plan -out=tfplan -input=false
    if ($Apply) {
        terraform apply -auto-approve tfplan
    } else {
        Write-Host "Plan created at tfplan. Use -Apply to run terraform apply."
    }
} finally {
    Pop-Location
}
