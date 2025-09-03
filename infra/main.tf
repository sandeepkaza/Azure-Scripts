terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = ">= 1.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurecaf_name" "rg" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg.result
  location = var.location
}

resource "azurecaf_name" "log" {
  name          = var.environment_name
  resource_type = "azurerm_log_analytics_workspace"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = azurecaf_name.log.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurecaf_name" "appinsights" {
  name          = var.environment_name
  resource_type = "azurerm_application_insights"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_application_insights" "appinsights" {
  name                = azurecaf_name.appinsights.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurecaf_name" "kv" {
  name          = var.environment_name
  resource_type = "azurerm_key_vault"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_key_vault" "kv" {
  name                        = azurecaf_name.kv.result
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "kv_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurecaf_name" "mi" {
  name          = var.environment_name
  resource_type = "azurerm_user_assigned_identity"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = azurecaf_name.mi.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "mi_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurecaf_name" "acr" {
  name          = var.environment_name
  resource_type = "azurerm_container_registry"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_container_registry" "acr" {
  name                = azurecaf_name.acr.result
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "mi_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurecaf_name" "cae" {
  name          = var.environment_name
  resource_type = "azurerm_container_app_environment"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_container_app_environment" "cae" {
  name                       = azurecaf_name.cae.result
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id
}

resource "azurecaf_name" "ca" {
  name          = var.environment_name
  resource_type = "azurerm_container_app"
  prefixes      = []
  suffixes      = []
}

resource "azurerm_container_app" "ca" {
  name                         = azurecaf_name.ca.result
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    identity             = azurerm_user_assigned_identity.mi.id
  }

  template {
    container {
      name   = "super-mario-game"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    azd-service-name = "super-mario-game"
  }
}

resource "azapi_resource_action" "cors" {
  type        = "Microsoft.App/containerApps"
  resource_id = azurerm_container_app.ca.id
  method      = "PATCH"
  body = {
    properties = {
      configuration = {
        ingress = {
          corsPolicy = {
            allowedOrigins = ["*"]
            allowedHeaders = ["*"]
            allowedMethods = ["*"]
          }
        }
      }
    }
  }
}

variable "environment_name" {
  type = string
}

variable "location" {
  type = string
}
