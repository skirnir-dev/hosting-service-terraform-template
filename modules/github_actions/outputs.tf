output "azure_client_id" {
  value       = azuread_application.terraform.client_id
  description = "Azure AD Application (Client) ID for GitHub Actions - Save this to 1Password"
  sensitive   = true
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Storage Account name for Terraform state"
}

output "storage_account_id" {
  value       = azurerm_storage_account.tfstate.id
  description = "Storage Account ID"
}

output "service_principal_object_id" {
  value       = azuread_service_principal.terraform.object_id
  description = "Service Principal Object ID"
}

output "application_id" {
  value       = azuread_application.terraform.id
  description = "Azure AD Application ID (Object ID)"
}
