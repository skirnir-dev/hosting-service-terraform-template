resource "azurerm_recovery_services_vault" "rs" {
  location            = var.location
  name                = "${var.username}-valt"
  resource_group_name = var.resource_group.name
  sku                 = "RS0"
  storage_mode_type   = "LocallyRedundant"
  depends_on = [
    var.resource_group,
  ]
}
data "azurerm_backup_policy_vm" "default_policy" {
  name                = "DefaultPolicy"
  recovery_vault_name = azurerm_recovery_services_vault.rs.name
  resource_group_name = var.resource_group.name
}
resource "azurerm_backup_protected_vm" "vm_backup" {
  backup_policy_id  = data.azurerm_backup_policy_vm.default_policy.id
  exclude_disk_luns = null
  include_disk_luns = null
  # protection_state    = "Protected"
  recovery_vault_name = azurerm_recovery_services_vault.rs.name
  resource_group_name = var.resource_group.name
  source_vm_id        = var.virtual_machine.id
}

