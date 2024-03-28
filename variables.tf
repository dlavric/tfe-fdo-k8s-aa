variable "aws_region" {
  description = "TFE region where to deploy the resources"
}

variable "storage_bucket" {
  description = "The name of the S3 Bucket to save all the TFE data to"
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

variable "eks_desired_size" {
  description = "The DB password"
}

variable "eks_max_size" {
  description = "The DB password"
}

variable "eks_min_size" {
  description = "The DB password"
}






