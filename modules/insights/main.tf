data "azurerm_log_analytics_workspace" "ws" {
  name                = "log-analytics"
  resource_group_name = "log-analytics"
}
resource "azurerm_monitor_action_group" "app_action" {
  name                = "AppAction-${var.fqdn}"
  resource_group_name = var.resource_group.name
  short_name          = var.username
  azure_app_push_receiver {
    email_address = "user@example.com"
    name          = "Administrator_-AzureAppAction-"
  }
  depends_on = [
    var.resource_group
  ]
}
resource "azurerm_application_insights" "app_insights" {
  application_type    = "web"
  location            = var.location
  name                = var.fqdn
  resource_group_name = var.resource_group.name
  sampling_percentage = 0
  workspace_id        = data.azurerm_log_analytics_workspace.ws.id
  depends_on = [
    var.resource_group
  ]
}
resource "random_uuid" "lists_webtest_id" {}
resource "random_uuid" "lists_webtest_item_guid" {}
resource "azurerm_application_insights_web_test" "lists" {
  application_insights_id = azurerm_application_insights.app_insights.id
  configuration           = <<WEBTEST
<WebTest
  Name="list"
  Id="${random_uuid.lists_webtest_id.result}"
  Enabled="True"
  CssProjectStructure=""
  CssIteration=""
  Timeout="120"
  WorkItemIds=""
  xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"
  Description=""
  CredentialUserName=""
  CredentialPassword=""
  PreAuthenticate="True"
  Proxy="default"
  StopOnError="False"
  RecordedResultFile=""
  ResultsLocale="">
    <Items>
      <Request
        Method="GET"
        Guid="${random_uuid.lists_webtest_item_guid.result}"
        Version="1.1"
        Url="${var.lists_webtest_url}"
        ThinkTime="0"
        Timeout="120"
        ParseDependentRequests="False"
        FollowRedirects="True"
        RecordResult="True"
        Cache="False"
        ResponseTimeGoal="0"
        Encoding="utf-8"
        ExpectedHttpStatusCode="200"
        ExpectedResponseUrl=""
        ReportingName=""
        IgnoreHttpStatusCode="False" />
    </Items>
</WebTest>
WEBTEST
  description             = null
  enabled                 = true
  frequency               = 300
  geo_locations           = ["apac-sg-sin-azr", "apac-jp-kaw-edge", "apac-hk-hkn-azr"]
  kind                    = "ping"
  location                = var.location
  name                    = "list-${var.fqdn}"
  resource_group_name     = var.resource_group.name
  retry_enabled           = true
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}" = "Resource"
  }
  timeout = 120
}

resource "azurerm_monitor_metric_alert" "lists" {
  auto_mitigate       = false
  name                = "list-${var.fqdn}"
  resource_group_name = var.resource_group.name
  scopes              = [azurerm_application_insights.app_insights.id, azurerm_application_insights_web_test.lists.id]
  severity            = 1
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}" = "Resource"
  }
  action {
    action_group_id    = azurerm_monitor_action_group.app_action.id
    webhook_properties = {}
  }
  application_insights_web_test_location_availability_criteria {
    component_id          = azurerm_application_insights.app_insights.id
    failed_location_count = 1
    web_test_id           = azurerm_application_insights_web_test.lists.id
  }
  depends_on = [
    var.resource_group
  ]
}
resource "random_uuid" "top_webtest_id" {}
resource "random_uuid" "top_webtest_item_guid" {}
resource "azurerm_application_insights_web_test" "top" {
  application_insights_id = azurerm_application_insights.app_insights.id
  configuration           = <<WEBTEST
<WebTest
  Name="list"
  Id="${random_uuid.top_webtest_id.result}"
  Enabled="True"
  CssProjectStructure=""
  CssIteration=""
  Timeout="120"
  WorkItemIds=""
  xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"
  Description=""
  CredentialUserName=""
  CredentialPassword=""
  PreAuthenticate="True"
  Proxy="default"
  StopOnError="False"
  RecordedResultFile=""
  ResultsLocale="">
    <Items>
      <Request
        Method="GET"
        Guid="${random_uuid.top_webtest_item_guid.result}"
        Version="1.1"
        Url="${var.top_webtest_url}"
        ThinkTime="0"
        Timeout="120"
        ParseDependentRequests="False"
        FollowRedirects="True"
        RecordResult="True"
        Cache="False"
        ResponseTimeGoal="0"
        Encoding="utf-8"
        ExpectedHttpStatusCode="200"
        ExpectedResponseUrl=""
        ReportingName=""
        IgnoreHttpStatusCode="False" />
    </Items>
</WebTest>
WEBTEST
  description             = null
  enabled                 = true
  frequency               = 300
  geo_locations           = ["apac-sg-sin-azr", "apac-jp-kaw-edge", "apac-hk-hkn-azr"]
  kind                    = "ping"
  location                = var.location
  name                    = "top-${var.fqdn}"
  resource_group_name     = var.resource_group.name
  retry_enabled           = true
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}" = "Resource"
  }
  timeout = 120
}

resource "azurerm_monitor_metric_alert" "top" {
  auto_mitigate       = false
  name                = "top-${var.fqdn}"
  resource_group_name = var.resource_group.name
  scopes              = [azurerm_application_insights.app_insights.id, azurerm_application_insights_web_test.top.id]
  severity            = 1
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}" = "Resource"
  }
  action {
    action_group_id    = azurerm_monitor_action_group.app_action.id
    webhook_properties = {}
  }
  application_insights_web_test_location_availability_criteria {
    component_id          = azurerm_application_insights.app_insights.id
    failed_location_count = 1
    web_test_id           = azurerm_application_insights_web_test.top.id
  }
  depends_on = [
    var.resource_group
  ]
}

resource "azurerm_application_insights_standard_web_test" "ssl_checker" {
  application_insights_id = azurerm_application_insights.app_insights.id
  description             = null
  enabled                 = true
  frequency               = 900
  geo_locations           = ["apac-jp-kaw-edge"]
  location                = var.location
  name                    = "ssl checker-${var.fqdn}"
  resource_group_name     = var.resource_group.name
  retry_enabled           = true
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}" = "Resource"
  }
  timeout = 120
  request {
    body                             = null
    follow_redirects_enabled         = true
    http_verb                        = "GET"
    parse_dependent_requests_enabled = false
    url                              = "https://${var.fqdn}/"
  }
  validation_rules {
    expected_status_code        = 200
    ssl_cert_remaining_lifetime = 7
    ssl_check_enabled           = true
  }
}
resource "azurerm_monitor_metric_alert" "ssl_checker" {
  auto_mitigate       = false
  name                = "ssl checker-${var.fqdn}"
  resource_group_name = var.resource_group.name
  scopes              = [azurerm_application_insights.app_insights.id, azurerm_application_insights_standard_web_test.ssl_checker.id]
  severity            = 1
  tags = {
    "hidden-link:${azurerm_application_insights.app_insights.id}"                  = "Resource"
    "hidden-link:${azurerm_application_insights_standard_web_test.ssl_checker.id}" = "Resource"
  }
  action {
    action_group_id = azurerm_monitor_action_group.app_action.id
  }
  application_insights_web_test_location_availability_criteria {
    component_id          = azurerm_application_insights.app_insights.id
    failed_location_count = 1
    web_test_id           = azurerm_application_insights_standard_web_test.ssl_checker.id
  }
  depends_on = [
    var.resource_group
  ]
}
