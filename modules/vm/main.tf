data "azurerm_ssh_public_key" "ed25519" {
  name                = "ed25519"
  resource_group_name = var.pubkey_resource_group_name
}
resource "azurerm_linux_virtual_machine" "vm_web" {
  admin_username        = var.username
  location              = var.location
  name                  = var.fqdn
  network_interface_ids = [var.network_interface.id]
  resource_group_name   = var.resource_group.name
  size                  = "Standard_B1ms"
  zone                  = "1"
  admin_ssh_key {
    public_key = data.azurerm_ssh_public_key.ed25519.public_key
    username   = var.username
  }
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    offer     = "almalinux-x86_64"
    publisher = "almalinux"
    sku       = "8-gen2"
    version   = "latest"
  }
  depends_on = [
    var.public_ip
  ]
}
