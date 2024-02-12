variable "aws_region" {
  description = "TFE region where to deploy the resources"
}

variable "ami" {
  description = "The id of the AMI for the OS"
}

variable "instance_type" {
  description = "The instance type of the EC2 instance"
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

variable "username" {
  description = "The TFE username for my Initial ADMIN user of my installation"
}

variable "password" {
  description = "The TFE password for my Initial ADMIN user of my installation"
}

variable "certs_bucket" {
  description = "The name of the S3 Bucket to save the certs to"
}

variable "license_bucket" {
  description = "The name of the S3 Bucket to save the license to"
}

variable "storage_bucket" {
  description = "The name of the S3 Bucket to save all the TFE data to"
}

variable "license_filename" {
  description = "The name of the file that contains the TFE FDO License"
}

variable "key_pair" {
  description = "The name of the AWS Key Pair for my EC2 instance"
}

variable "enc_password" {
  description = "The encryption password for my TFE installation"
}

variable "db_identifier" {
  description = "The DB identifier name"
}

variable "db_name" {
  description = "The DB name"
}

variable "db_username" {
  description = "The DB username"
}

variable "db_password" {
  description = "The DB password"
}








