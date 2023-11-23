resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.fqdn
}
module "virtual_machine" {
  source                     = "./modules/vm"
  resource_group             = azurerm_resource_group.rg
  network_interface          = module.networks.network_interface
  public_ip                  = module.networks.public_ip
  location                   = var.location
  fqdn                       = var.fqdn
  username                   = var.username
  pubkey_resource_group_name = var.pubkey_resource_group_name
}

module "azure_dns" {
  source         = "./modules/azure_dns"
  resource_group = azurerm_resource_group.rg
  vm_web_ip      = module.networks.public_ip
  fqdn           = var.fqdn
  username       = var.username
}

data "cloudflare_zone" "zone" {
  name = var.fqdn
}

data "cloudflare_accounts" "main" {
  name = var.cloudflare_account_name
}

module "cloudflare_dns" {
  source          = "./modules/cloudflare_dns"
  fqdn            = var.fqdn
  staging         = var.staging
  username        = var.username
  cloudflare_zone = data.cloudflare_zone.zone
  public_ip       = module.networks.public_ip
}

module "networks" {
  source         = "./modules/networks"
  resource_group = azurerm_resource_group.rg
  fqdn           = var.fqdn
  username       = var.username
  location       = var.location
}

module "backup" {
  source          = "./modules/backup"
  resource_group  = azurerm_resource_group.rg
  username        = var.username
  location        = var.location
  virtual_machine = module.virtual_machine.vm_web
}

module "insights" {
  source            = "./modules/insights"
  resource_group    = azurerm_resource_group.rg
  fqdn              = var.fqdn
  username          = var.username
  location          = var.location
  lists_webtest_url = "https://${var.fqdn}/products/list.php"
  top_webtest_url   = "https://${var.fqdn}/"
}

module "zero_trust" {
  source              = "./modules/zero_trust"
  fqdn                = var.fqdn
  staging             = var.staging
  username            = var.username
  account_id          = data.cloudflare_accounts.main.accounts[0].id
  cloudflare_zone     = data.cloudflare_zone.zone
  cloudflare_zone_xyz = data.cloudflare_zone.zone_xyz
}

module "waf" {
  source          = "./modules/waf"
  fqdn            = var.fqdn
  staging         = var.staging
  username        = var.username
  cloudflare_zone = data.cloudflare_zone.zone
}

resource "ansible_host" "web_server" {
  name   = "${var.username}.${var.location}.cloudapp.azure.com"
  groups = ["web"]
  variables = {
    ansible_user                 = var.username
    ansible_ssh_private_key_file = "~/.ssh/id_rsa",
    ansible_python_interpreter   = "/usr/bin/python3"
    ansible_become               = "yes"
    ansible_become_method        = "sudo"
  }
}
