variable "resource_group" {
  description = "The name of the resource group in which to create the resources."
}
variable "network_interface" {
  description = "The ID of the network interface to which the IP configuration belongs."
}
variable "public_ip" {
  description = "The ID of the public IP to which the IP configuration belongs."
}
variable "fqdn" {
  type = string
}
variable "username" {
  type = string
}
variable "location" {
  type = string
}
variable "pubkey_resource_group_name" {
  type = string
}
