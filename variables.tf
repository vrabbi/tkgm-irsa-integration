variable "aws_region" {
  description = "The AWS Region to deploy resources in"
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication to AWS"
}

variable "cluster_name" {
  description = "The name of the TKG cluster you want to create"
}

variable "cluster_created" {
  description = "A Boolean field to set if the cluster has already been created or not. The module must be run first with false, then create the cluster and then run with true to finish the configuration"
  default     = false
}

variable "iam_role_configs" {
  description = "IAM Role configuration for IRSA Service Accounts"
  type = list(object({
    ns_sa_string       = string
    managed_policy_arn = string
    name               = string
  }))
  default = [{
    ns_sa_string       = "default:sample-s3-ro-user"
    managed_policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    name               = "demo-tkg-01-sample-role"
  }]
}

variable "kubeconfig_path" {
  description = "The file path to your local kubeconfig where you have contexts for your management cluster and workload clusters"
  default     = "~/.kube/config"
}

variable "mgmt_cluster_kube_context" {
  description = "The kubectl context of your TKG management cluster"
}

