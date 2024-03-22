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
    name      = var.tfe_namespace
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

resource "helm_release" "tfe_helm" {
  name       = var.tfe_namespace
  namespace  = var.tfe_namespace
  repository = "https://helm.releases.hashicorp.com"
  chart      = "hashicorp/terraform-enterprise"

  values = [
    templatefile("${path.module}/overrides.yaml", {
      tfe_hostname = var.tfe_hostname
      tfe_version  = var.tfe_version
      tfe_license  = var.raw_tfe_license
      enc_password = var.enc_password
      #email            = var.email,
      #username         = var.username,
      #password         = var.password,
      db_host     = data.terraform_remote_state.eks_cluster.outputs.pg_address
      db_name     = data.terraform_remote_state.eks_cluster.outputs.pg_dbname
      db_username = data.terraform_remote_state.eks_cluster.outputs.pg_user
      db_password = data.terraform_remote_state.eks_cluster.outputs.pg_password
      aws_region  = data.terraform_remote_state.eks_cluster.outputs.region
      #certs_bucket     = var.certs_bucket,
      storage_bucket = data.terraform_remote_state.eks_cluster.outputs.s3_bucket
      #license_bucket   = var.license_bucket,
      redis_address = data.terraform_remote_state.eks_cluster.outputs.redis_host
      redis_port    = data.terraform_remote_state.eks_cluster.outputs.redis_port
      cert_data     = "${base64encode(acme_certificate.certificate.certificate_pem)}"
      key_data      = "${base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))}"
      ca_cert_data  = "${base64encode(acme_certificate.certificate.issuer_pem)}"
      replica_count = var.replica_count
    })
  ]

}

data "kubernetes_service" "my_eks_service" {
  metadata {
    name      = var.tfe_namespace
    namespace = var.tfe_namespace
  }
  depends_on = [helm_release.tfe_helm]
}



# Create DNS for the Load Balancer
resource "aws_route53_record" "lb" {
  zone_id    = data.aws_route53_zone.zone.zone_id
  name       = "${var.tfe_subdomain}.${data.aws_route53_zone.zone.name}"
  type       = "CNAME"
  ttl        = "300"
  records    = [data.kubernetes_service.my_eks_service.status.0.load_balancer.0.ingress.0.hostname]
  depends_on = [helm_release.tfe_helm]
}