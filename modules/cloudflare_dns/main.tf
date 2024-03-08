resource "cloudflare_record" "fqdn" {
  name    = var.fqdn
  proxied = true
  tags    = []
  ttl     = 1
  type    = "A"
  value   = var.public_ip.ip_address
  zone_id = var.cloudflare_zone.id
}

resource "cloudflare_record" "staging" {
  name    = var.staging
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  value   = var.fqdn
  zone_id = var.cloudflare_zone.id
}

resource "cloudflare_record" "www" {
  name    = "www"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  value   = var.fqdn
  zone_id = var.cloudflare_zone.id
}

resource "cloudflare_record" "mx" {
  name     = var.fqdn
  priority = 10
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "MX"
  value    = "mail.example.com"
  zone_id  = var.cloudflare_zone.id
}

resource "cloudflare_record" "txt_spf" {
  name    = var.fqdn
  proxied = false
  tags    = []
  ttl     = 1
  type    = "TXT"
  value   = "\"v=spf1 include:example.com ~all\""
  zone_id = var.cloudflare_zone.id
}
resource "cloudflare_record" "cname_s1_domainkey" {
  allow_overwrite = null
  comment         = null
  name            = tolist(var.sendgrid_sender_dns)[0].host
  priority        = null
  proxied         = false
  tags            = []
  ttl             = 1
  type            = upper(tolist(var.sendgrid_sender_dns)[0].type)
  value           = tolist(var.sendgrid_sender_dns)[0].data
  zone_id         = var.cloudflare_zone.id
}
resource "cloudflare_record" "cname_s2_domainkey" {
  allow_overwrite = null
  comment         = null
  name            = tolist(var.sendgrid_sender_dns)[1].host
  priority        = null
  proxied         = false
  tags            = []
  ttl             = 1
  type            = upper(tolist(var.sendgrid_sender_dns)[1].type)
  value           = tolist(var.sendgrid_sender_dns)[1].data
  zone_id         = var.cloudflare_zone.id
}
resource "cloudflare_record" "cname_em" {
  allow_overwrite = null
  comment         = null
  name            = tolist(var.sendgrid_sender_dns)[2].host
  priority        = null
  proxied         = false
  tags            = []
  ttl             = 1
  type            = upper(tolist(var.sendgrid_sender_dns)[2].type)
  value           = tolist(var.sendgrid_sender_dns)[2].data
  zone_id         = var.cloudflare_zone.id
}
resource "cloudflare_record" "cname_sendgrid" {
  allow_overwrite = null
  comment         = null
  name            = tolist(var.sendgrid_link_dns)[0].host
  priority        = null
  proxied         = false
  tags            = []
  ttl             = 1
  type            = upper(tolist(var.sendgrid_link_dns)[0].type)
  value           = tolist(var.sendgrid_link_dns)[0].data
  zone_id         = var.cloudflare_zone.id
}
resource "cloudflare_record" "cname_sendgrid_url" {
  allow_overwrite = null
  comment         = null
  name            = tolist(var.sendgrid_link_dns)[1].host
  priority        = null
  proxied         = false
  tags            = []
  ttl             = 1
  type            = upper(tolist(var.sendgrid_link_dns)[1].type)
  value           = tolist(var.sendgrid_link_dns)[1].data
  zone_id         = var.cloudflare_zone.id
}
