provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  ignore_tags {
    keys = ["Created By", "Creation Date", "IAM Role Name", "IAM User Name"]
  }
}

terraform {
  required_providers {
    aws = {
      version = "~> 4.45.0"
    }

    jwks = {
      source  = "iwarapter/jwks"
      version = "0.0.1"
    }

    kubernetes = {
      version = "2.16.1"
    }

    template = {
      version = "2.2.0"
    }

    tls = {
      version = "4.0.4"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  alias          = "mgmt"
  config_path    = var.kubeconfig_path
  config_context = var.mgmt_cluster_kube_context
}

provider "kubernetes" {
  alias                  = "workload"
  host                   = local.url
  client_certificate     = local.cert
  client_key             = local.key
  cluster_ca_certificate = local.ca
}

provider "kubectl" {
  apply_retry_count = 15
  alias             = "mgmt"
  config_path       = var.kubeconfig_path
  config_context    = var.mgmt_cluster_kube_context
}
