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

module "dns" {
  source         = "./modules/dns"
  resource_group = azurerm_resource_group.rg
  vm_web_ip      = module.networks.public_ip
  fqdn           = var.fqdn
  username       = var.username
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
