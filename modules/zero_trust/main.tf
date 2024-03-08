resource "cloudflare_access_application" "staging" {
  account_id                   = var.account_id
  allowed_idps                 = []
  app_launcher_visible         = true
  auto_redirect_to_identity    = false
  custom_deny_message          = null
  custom_deny_url              = null
  custom_non_identity_deny_url = null
  custom_pages                 = []
  domain                       = "${var.staging}.${var.fqdn}"
  enable_binding_cookie        = false
  http_only_cookie_attribute   = true
  logo_url                     = null
  name                         = var.staging
  service_auth_401_redirect    = false
  session_duration             = "24h"
  skip_interstitial            = false
  type                         = "self_hosted"
}

resource "cloudflare_access_application" "admin" {
  account_id                = var.account_id
  allowed_idps              = []
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  custom_deny_message       = null
  custom_deny_url           = null

  custom_non_identity_deny_url = null
  custom_pages                 = []
  domain                       = "${var.fqdn}/admin"
  enable_binding_cookie        = false
  http_only_cookie_attribute   = true
  logo_url                     = null
  name                         = "admin"
  service_auth_401_redirect    = false
  session_duration             = "24h"
  skip_interstitial            = false
  type                         = "self_hosted"
}

resource "cloudflare_access_application" "certbot_skip" {
  account_id                   = var.account_id
  allowed_idps                 = []
  app_launcher_visible         = true
  auto_redirect_to_identity    = false
  custom_deny_message          = null
  custom_deny_url              = null
  custom_non_identity_deny_url = null
  custom_pages                 = []
  domain                       = "${var.staging}.${var.fqdn}/.well-known/acme-challenge"
  enable_binding_cookie        = false
  http_only_cookie_attribute   = true
  logo_url                     = null
  name                         = "certbot skip"
  self_hosted_domains = [
    "${var.staging}.${var.fqdn}/.well-known/acme-challenge",
  ]

  service_auth_401_redirect = false
  session_duration          = "24h"
  skip_interstitial         = false
  type                      = "self_hosted"
}

resource "cloudflare_access_group" "allow_email_domain" {
  account_id = var.account_id
  name       = "Allow domains"

  include {
    email_domain = [
      "example.com",
    ]
  }
}

resource "cloudflare_access_group" "allow_ips_office" {
  account_id = var.account_id
  name       = "office"

  include {
    ip = [
      "xxx.xxx.xxx.xxx/32"
    ]
  }
}

data "cloudflare_access_identity_provider" "onetimepin" {
  name       = ""
  account_id = var.account_id
}

resource "cloudflare_access_policy" "staging_bypass_ips" {
  application_id = cloudflare_access_application.staging.id
  name           = "許可IP"
  precedence     = "1"
  decision       = "bypass"
  zone_id        = var.cloudflare_zone.id

  include {
    group = [
      cloudflare_access_group.allow_ips_office.id,
    ]
  }
}

resource "cloudflare_access_policy" "staging_onetimepin" {
  application_id = cloudflare_access_application.staging.id
  name           = "one-time pin"
  precedence     = "2"
  decision       = "allow"
  zone_id        = var.cloudflare_zone.id

  include {
    login_method = [
      data.cloudflare_access_identity_provider.onetimepin.id,
    ]
  }
  require {
    group = [
      cloudflare_access_group.allow_email_domain.id,
    ]
  }
}

resource "cloudflare_access_policy" "admin_bypass_ips" {
  application_id = cloudflare_access_application.admin.id
  name           = "office"
  precedence     = "1"
  decision       = "bypass"
  zone_id        = var.cloudflare_zone.id

  include {
    group = [
      cloudflare_access_group.allow_ips_office.id,
    ]
  }
}

resource "cloudflare_access_policy" "admin_onetimepin" {
  application_id = cloudflare_access_application.admin.id
  name           = "one-time pin"
  precedence     = "2"
  decision       = "allow"
  zone_id        = var.cloudflare_zone.id

  include {
    login_method = [
      data.cloudflare_access_identity_provider.onetimepin.id,
    ]
  }
  require {
    group = [
      cloudflare_access_group.allow_email_domain.id,
    ]
  }
}

resource "cloudflare_access_policy" "certbot_skip_bypass" {
  application_id = cloudflare_access_application.certbot_skip.id
  account_id     = var.account_id
  name           = "skip"
  precedence     = "1"
  decision       = "bypass"
  zone_id        = var.cloudflare_zone.id

  include {
    everyone = true
  }
}
