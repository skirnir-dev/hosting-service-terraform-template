output "sendgrid_api_key_web" {
  value     = sendgrid_api_key.web.api_key
  sensitive = true
}
output "sendgrid_sender_authentication_dns" {
  value = sendgrid_sender_authentication.fqdn.dns
}
output "sendgrid_link_branding_dns" {
  value = sendgrid_link_branding.fqdn.dns
}

