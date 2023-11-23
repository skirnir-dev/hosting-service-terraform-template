variable "resource_group" {
  description = "The name of the resource group in which to create the resources."
}
variable "vm_web_ip" {
  description = "The public IP address of the VM."
}
variable "fqdn" {
  type = string
}
variable "username" {
  type = string
}
