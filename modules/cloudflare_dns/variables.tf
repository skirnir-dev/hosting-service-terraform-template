variable "public_ip" {
  description = "The public IP address of the VM."
}
variable "fqdn" {
  type = string
}
variable "staging" {
  type = string
}
variable "username" {
  type = string
}
variable "cloudflare_zone" {
  description = "The name of the Cloudflare zone."
}
variable "sendgrid_sender_dns" {
  description = "The DNS record for the SendGrid sender authentication."
}
variable "sendgrid_link_dns" {
  description = "The DNS record for the SendGrid link branding."
}
