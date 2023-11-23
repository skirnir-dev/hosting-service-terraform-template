resource "cloudflare_ruleset" "custom_rule" {
  kind    = "zone"
  name    = "default"
  phase   = "http_request_firewall_custom"
  zone_id = var.cloudflare_zone.id
  rules {
    action      = "skip"
    description = "AppInsights と wp-cron と Let's Encrypt をスキップ"
    enabled     = true
    expression  = "(http.user_agent contains \"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0; AppInsights)\") or (http.request.uri.path contains \"/.well-known/acme-challenge\")"
    action_parameters {
      phases = [
        "http_request_sbfm"
      ]
    }
    logging {
      enabled = true
    }
  }
  rules {
    action      = "block"
    description = "AWS ブロック"
    enabled     = true
    expression  = "(ip.geoip.asnum eq 16509 and not http.request.uri.path contains \"/.well-known/acme-challenge\")"
  }
  rules {
    action      = "skip"
    description = "office"
    enabled     = true
    expression  = "(ip.src eq xxx.xxx.xxx.xxx)"
    action_parameters {
      phases = [
        "http_ratelimit",
        "http_request_firewall_managed",
        "http_request_sbfm"
      ]
      ruleset = "current"
    }
    logging {
      enabled = true
    }
  }
  rules {
    action      = "managed_challenge"
    description = "/shopping reCAPTCHA"
    enabled     = true
    expression  = "(http.request.uri.path contains \"/shopping\")"
  }
}
resource "cloudflare_bot_management" "bot_fight_mode" {
  zone_id                         = var.cloudflare_zone.id
  enable_js                       = false
  sbfm_definitely_automated       = "block"
  sbfm_verified_bots              = "allow"
  sbfm_static_resource_protection = false
  optimize_wordpress              = true
}
