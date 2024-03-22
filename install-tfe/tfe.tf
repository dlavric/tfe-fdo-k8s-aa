# DNS
data "aws_route53_zone" "zone" {
  name = var.tfe_domain
}

# Create Certificates
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem              = acme_registration.reg.account_key_pem
  common_name                  = "${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"
  subject_alternative_names    = ["${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"]
  disable_complete_propagation = true

  dns_challenge {
    provider = "route53"
    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.zone.zone_id
    }
  }
}

# Add my certificates to a S3 Bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = var.certs_bucket

  tags = {
    Name        = "Daniela FDO Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "object" {
  for_each = toset(["certificate_pem", "issuer_pem", "private_key_pem"])
  bucket   = aws_s3_bucket.s3bucket.bucket
  key      = "ssl-certs/${each.key}"
  content  = lookup(acme_certificate.certificate, "${each.key}")
}

resource "aws_s3_object" "object_full_chain" {
  bucket  = aws_s3_bucket.s3bucket.bucket
  key     = "ssl-certs/full_chain"
  content = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
}

resource "kubernetes_namespace" "tfe_namespace" {
  metadata {
    name = var.tfe_namespace
  }
}

resource "kubernetes_secret" "tfe_secret" {
  metadata {
    name = var.tfe_namespace
    namespace = var.tfe_namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_server}" = {
          "username" = var.registry_username
          "password" = var.raw_tfe_license
          "auth"     = base64encode("${var.registry_username}:${var.raw_tfe_license}")
        }
      }
    })
  }
}

# kubectl create secret docker-registry terraform-enterprise 
#--docker-server=terraform-enterprise-beta.terraform.io --docker-username=$TFE_BETA_USERNAME --docker-password=$TFE_BETA_TOKEN  -n terraform-enterprise
