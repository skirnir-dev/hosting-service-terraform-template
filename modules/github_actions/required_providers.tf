terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47"
    }
  }
}
