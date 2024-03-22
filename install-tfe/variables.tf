variable "aws_region" {
  description = "TFE region where to deploy the resources"
}

variable "tfe_version" {
  description = "The TFE version release from https://developer.hashicorp.com/terraform/enterprise/releases"
}

variable "tfe_hostname" {
  description = "The TFE hostname for my installation"
}

variable "tfe_domain" {
  description = "The TFE zone name from AWS Route 53 for the domain of my TFE URL"
}

variable "tfe_subdomain" {
  description = "The name of the subdomain for my TFE URL"
}

variable "email" {
  description = "The email address for the Let's Encrypt certificate and email for my TFE initial ADMIN user"
}

variable "certs_bucket" {
  description = "The name of the S3 Bucket to save the certs to"
}

variable "tfe_namespace" {
  description = "The name of the Kubernetes namespace for TFE"
}

variable "registry_server" {
  description = "URL to download the container image" 
}

variable "registry_username" {
  description = "The username to be used for the registry" 
}

variable "raw_tfe_license" {
  description = "The Raw TFE license" 
}


