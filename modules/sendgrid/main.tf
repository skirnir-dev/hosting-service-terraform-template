resource "sendgrid_api_key" "web" {
  name = var.fqdn
  scopes = [
    "2fa_exempt",
    "2fa_required",
    "mail.send",
    "sender_verification_exempt"
  ]
}

resource "sendgrid_sender_authentication" "fqdn" {
  domain = var.fqdn
}

resource "sendgrid_link_branding" "fqdn" {
  domain = var.fqdn
}
