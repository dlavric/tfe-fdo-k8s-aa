terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.23.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}

data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "${path.root}/../terraform.tfstate"
  }
}

data "aws_eks_cluster" "my_eks_cluster" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster_name
}

data "aws_eks_cluster_auth" "my_eks_auth" {
  name = data.terraform_remote_state.eks_cluster.outputs.cluster_name
}

provider "aws" {
  region = data.terraform_remote_state.eks_cluster.outputs.region
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.my_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.my_eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.my_eks_auth.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.my_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.my_eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.my_eks_auth.token
}