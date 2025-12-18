terraform {
  # Azure Storage Backend
  # NOTE: Bootstrap時はこのブロックをコメントアウトして local backend で実行
  # Storage Account 作成後にコメント解除して `terraform init -migrate-state` を実行
  backend "azurerm" {
    resource_group_name  = "<fqdn>"              # var.fqdn と同じ値
    storage_account_name = "state<project>"      # var.project_name から生成
    container_name       = "tfstate"
    key                  = "<project>-terraform.tfstate"
  }

  required_version = ">=1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.19"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "~> 0.3"
    }
    sendgrid = {
      source  = "registry.terraform.io/kenzo0107/sendgrid"
      version = "~> 1.4"
    }
  }
}

provider "azurerm" {
  features {}
}
provider "azuread" {}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
provider "mackerel" {
  api_key = var.mackerel_api_key
}
provider "sendgrid" {
  api_key = var.sendgrid_api_key
  subuser = var.username
}
