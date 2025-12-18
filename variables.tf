variable "project_name" {
  description = "Project name for CI/CD resources (e.g., 'example' creates 'example-terraform' SP, 'stateexample' Storage Account)"
  type        = string
  default     = "example"
}
variable "fqdn" {
  default = "example.com"
  type    = string
}
variable "server_alias" {
  default = "www.example.com"
  type    = string
}
variable "username" {
  default = "user"
  type    = string
}
variable "staging" {
  default = "test-user"
  type    = string
}
variable "location" {
  default = "japaneast"
  type    = string
}
variable "pubkey_resource_group_name" {
  default = "pubkey-rg"
  type    = string
}
variable "cloudflare_account_name" {
  default = "example"
  type    = string
}
variable "cloudflare_api_token" {
  type = string
}
variable "sendgrid_api_key" {
  type = string
}
variable "mackerel_api_key" {
  type = string
}
