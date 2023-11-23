variable "fqdn" {
  type = string
}
variable "staging" {
  type = string
}
variable "username" {
  type = string
}
variable "account_id" {
  type        = string
  description = "The Cloudflare account ID."
}
variable "cloudflare_zone" {
  description = "The name of the Cloudflare zone."
}
