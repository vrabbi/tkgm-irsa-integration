provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
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
  }
}

provider "kubernetes" {
  alias          = "mgmt"
  config_path    = var.kubeconfig_path
  config_context = var.mgmt_cluster_kube_context
}

provider "kubernetes" {
  alias          = "workload"
  config_path    = var.kubeconfig_path
  config_context = var.cluster_created ? "${var.cluster_name}-admin@${var.cluster_name}" : var.mgmt_cluster_kube_context
}
