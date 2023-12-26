data "mackerel_service" "azure" {
  name = "Azure"
}

resource "mackerel_monitor" "external" {
  name                  = var.name
  notification_interval = 15

  external {
    method                            = "GET"
    url                               = var.external_url
    service                           = data.mackerel_service.azure.name
    certification_expiration_critical = 1
    certification_expiration_warning  = 3
    max_check_attempts                = 3
    follow_redirect                   = true
    response_time_critical            = 5000
    response_time_warning             = 2000
    response_time_duration            = 3
    headers                           = { Cache-Control = "no-cache" }
  }
}
