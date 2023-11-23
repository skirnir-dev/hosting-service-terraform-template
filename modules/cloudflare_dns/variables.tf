variable "vm_web_ip" {
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
