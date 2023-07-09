variable "resource_group" {
  description = "The name of the resource group in which to create the resources."
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
variable "lists_webtest_url" {
  type = string
}
variable "top_webtest_url" {
  type = string
}

