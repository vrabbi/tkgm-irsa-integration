# TKGm on vSphere - IRSA Integration
This Terraform module helps setup [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) on TKGm clusters running on vSphere.  

The process is a multi step process currently:
1. Run the Terraform module to create pre-requisite resources and configurations in AWS
2. Deploy your TKGm workload cluster
3. Deploy cert manager on the workload cluster via the tanzu package
4. Run the terraform module to configure the cluster and remaining steps on AWS side
  
The module requires the following pre-requisites:
1. AWS CLI is installed and credentials are configured
2. Tanzu CLI is installed
3. Tanzu CLI is logged in to the management cluster

# Terraform Module Documentation
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.45.0 |
| <a name="requirement_jwks"></a> [jwks](#requirement\_jwks) | 0.0.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.16.1 |
| <a name="requirement_template"></a> [template](#requirement\_template) | 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.45.0 |
| <a name="provider_jwks"></a> [jwks](#provider\_jwks) | 0.0.1 |
| <a name="provider_kubernetes.mgmt"></a> [kubernetes.mgmt](#provider\_kubernetes.mgmt) | 2.16.1 |
| <a name="provider_kubernetes.workload"></a> [kubernetes.workload](#provider\_kubernetes.workload) | 2.16.1 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.tkg_irsa_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.tkg_irsa_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_object.discovery_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.keys_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [kubernetes_cluster_role.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/cluster_role_binding) | resource |
| [kubernetes_deployment.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/deployment) | resource |
| [kubernetes_manifest.certificate_kube_system_pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/manifest) | resource |
| [kubernetes_manifest.clusterissuer_selfsigned](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/manifest) | resource |
| [kubernetes_mutating_webhook_configuration.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/mutating_webhook_configuration) | resource |
| [kubernetes_role.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/role) | resource |
| [kubernetes_role_binding.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/role_binding) | resource |
| [kubernetes_service.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/service) | resource |
| [kubernetes_service_account.pod_identity_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/service_account) | resource |
| [jwks_from_pem.sa_signing_key](https://registry.terraform.io/providers/iwarapter/jwks/0.0.1/docs/data-sources/from_pem) | data source |
| [kubernetes_secret.default](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/data-sources/secret) | data source |
| [kubernetes_secret.sa_rsa_pub](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/data-sources/secret) | data source |
| [kubernetes_service_account.default](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/data-sources/service_account) | data source |
| [template_file.discovery_json](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |
| [template_file.keys_json](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |
| [tls_certificate.bucket](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use for authentication to AWS | `any` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS Region to deploy resources in | `string` | `"eu-west-2"` | no |
| <a name="input_cluster_created"></a> [cluster\_created](#input\_cluster\_created) | A Boolean field to set if the cluster has already been created or not. The module must be run first with false, then create the cluster and then run with true to finish the configuration | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the TKG cluster you want to create | `any` | n/a | yes |
| <a name="input_iam_role_configs"></a> [iam\_role\_configs](#input\_iam\_role\_configs) | IAM Role configuration for IRSA Service Accounts | <pre>list(object({<br>    ns_sa_string       = string<br>    managed_policy_arn = string<br>    name               = string<br>  }))</pre> | <pre>[<br>  {<br>    "managed_policy_arn": "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",<br>    "name": "demo-tkg-01-sample-role",<br>    "ns_sa_string": "default:sample-s3-ro-user"<br>  }<br>]</pre> | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | The file path to your local kubeconfig where you have contexts for your management cluster and workload clusters | `string` | `"~/.kube/config"` | no |
| <a name="input_mgmt_cluster_kube_context"></a> [mgmt\_cluster\_kube\_context](#input\_mgmt\_cluster\_kube\_context) | The kubectl context of your TKG management cluster | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles) | n/a |
| <a name="output_next_steps"></a> [next\_steps](#output\_next\_steps) | n/a |
<!-- END_TF_DOCS -->
