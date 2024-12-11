resource "sendgrid_api_key" "web" {
  name = var.fqdn
  scopes = [
    # "2fa_exempt",
    # "2fa_required",
    "mail.send",
    # "sender_verification_exempt"
  ]

  lifecycle {
    ignore_changes = [
      scopes,
    ]
  }
}

# resource "sendgrid_teammate" "user" {
#   email  = "user@example.com"
#   scopes = var.teammate_scopes

#   lifecycle {
#     ignore_changes = [
#       scopes,
#     ]
#   }
# }

resource "sendgrid_sender_authentication" "fqdn" {
  domain = var.fqdn
}

resource "sendgrid_link_branding" "fqdn" {
  domain = var.fqdn
}

resource "sendgrid_click_tracking_settings" "web" {
  enabled = false
}
