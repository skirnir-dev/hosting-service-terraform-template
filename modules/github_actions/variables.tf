variable "project_name" {
  description = "Project name used for naming resources (e.g., 'example' creates 'example-terraform' SP)"
  type        = string
}

variable "resource_group" {
  description = "Azure Resource Group where the Storage Account will be created"
  type = object({
    id       = string
    name     = string
    location = string
  })
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "skirnir-dev"
}

variable "github_environment" {
  description = "GitHub Actions environment name for OIDC subject"
  type        = string
  default     = "production"
}
