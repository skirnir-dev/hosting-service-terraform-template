resource "azurerm_dns_zone" "zone" {
  name                = var.fqdn
  resource_group_name = var.resource_group.name
  depends_on = [
    var.resource_group,
  ]
}
resource "azurerm_dns_a_record" "fqdn" {
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 600
  target_resource_id  = var.vm_web_ip.id
}
resource "azurerm_dns_a_record" "staging" {
  name                = "test-${var.username}"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 600
  target_resource_id  = var.vm_web_ip.id
}
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 600
  record              = var.fqdn
}
resource "azurerm_dns_mx_record" "mx" {
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 600

  record {
    preference = 10
    exchange   = "mail.example.com"
  }
}
resource "azurerm_dns_txt_record" "txt" {
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = var.resource_group.name
  ttl                 = 600

  record {
    value = "v=spf1 include:example.com ~all"
  }
}

