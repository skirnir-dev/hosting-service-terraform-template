resource "azurerm_network_interface" "nic" {
  location            = var.location
  name                = "${var.fqdn}-nic"
  resource_group_name = var.resource_group.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    subnet_id                     = azurerm_subnet.subnet.id
  }
  depends_on = [
    azurerm_public_ip.public_ip,
    azurerm_subnet.subnet,
  ]
}
resource "azurerm_network_interface_security_group_association" "assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_network_interface.nic,
    azurerm_network_security_group.nsg,
  ]
}
resource "azurerm_network_security_group" "nsg" {
  location            = var.location
  name                = "${var.fqdn}-nsg"
  resource_group_name = var.resource_group.name
  depends_on = [
    var.resource_group,
  ]
}
resource "azurerm_network_security_rule" "rule_http" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "80"
  direction                   = "Inbound"
  name                        = "http"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 1020
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group.name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.nsg,
  ]
}
resource "azurerm_network_security_rule" "rule_https" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "443"
  direction                   = "Inbound"
  name                        = "https"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 1030
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group.name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.nsg,
  ]
}
resource "azurerm_network_security_rule" "rule_ssh" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "ssh"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 1010
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group.name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.nsg,
  ]
}
resource "azurerm_public_ip" "public_ip" {
  allocation_method   = "Static"
  domain_name_label   = var.username
  location            = var.location
  name                = "${var.fqdn}-ip"
  resource_group_name = var.resource_group.name
  sku                 = "Standard"
  zones               = ["1"]
  depends_on = [
    var.resource_group,
  ]
}
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  name                = "${var.fqdn}-vnet"
  resource_group_name = var.resource_group.name
  depends_on = [
    var.resource_group,
  ]
}
resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/24"]
  name                 = "default"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}
