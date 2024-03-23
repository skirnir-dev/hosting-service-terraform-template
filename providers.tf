terraform {
  cloud {
    organization = "skirnir"
    workspaces {
      name = "hosting-service-terraform"
    }
  }
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.63.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    ansible = {
      version = "~> 1.1.0"
      source  = "ansible/ansible"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.19"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "~> 0.3.2"
    }
    sendgrid = {
      source  = "registry.terraform.io/kenzo0107/sendgrid"
      version = "~> 1.0.3"
    }
  }
}

provider "azurerm" {
  features {}
}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
provider "mackerel" {
  api_key = var.mackerel_api_key
}
provider "sendgrid" {
  api_key = var.sendgrid_api_key
  subuser = "<subuser>"
}
