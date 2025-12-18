# =============================================================================
# GitHub Actions Module
# =============================================================================
# This module creates resources for GitHub Actions OIDC authentication and
# Terraform state management.
#
# Resources created:
# - Azure AD Application and Service Principal
# - Federated Identity Credential for GitHub Actions OIDC
# - Storage Account and Container for Terraform state
# - Role Assignments (Contributor, User Access Administrator, Storage Blob Data Contributor)
# =============================================================================

# Current Azure configuration
data "azurerm_client_config" "current" {}

# =============================================================================
# Azure AD Application and Service Principal
# =============================================================================

resource "azuread_application" "terraform" {
  display_name = "${var.project_name}-terraform"
}

resource "azuread_service_principal" "terraform" {
  application_id = azuread_application.terraform.client_id
}

resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.terraform.id
  display_name   = "${var.project_name}-github-actions"
  description    = "GitHub Actions OIDC for ${var.project_name}-terraform"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.project_name}-terraform:environment:${var.github_environment}"
}

# =============================================================================
# Storage Account for Terraform State
# =============================================================================

resource "azurerm_storage_account" "tfstate" {
  name                     = "state${replace(var.project_name, "-", "")}"
  resource_group_name      = var.resource_group.name
  location                 = var.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# =============================================================================
# Role Assignments for Service Principal
# =============================================================================

# Contributor at Subscription level
# Note: This is created manually in Phase 1 and imported into Terraform
resource "azurerm_role_assignment" "terraform_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform.object_id

  lifecycle {
    ignore_changes = [scope]
  }
}

# User Access Administrator at Resource Group level
resource "azurerm_role_assignment" "terraform_user_access_admin" {
  scope                = var.resource_group.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.terraform.object_id
}

# Storage Blob Data Contributor at Storage Account level
resource "azurerm_role_assignment" "terraform_storage" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform.object_id
}
