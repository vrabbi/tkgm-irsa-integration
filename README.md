# TKGm on vSphere - IRSA Integration
This Terraform module helps setup [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) on TKG 2.1 clusters running on vSphere.  

The module requires the following pre-requisites:
1. AWS CLI is installed and credentials are configured
2. Tanzu CLI is installed
3. Tanzu CLI is logged in to the management cluster

For more information check out the related [blog post](https://vrabbi.cloud/post/making-tkgm-feel-like-eks/)

This module will:
1. Create the pre-requisites in AWS
2. Create requested IAM roles
2. Deploy a TKG workload cluster
3. Install the TKG PAckage repo in the workload cluster
4. Install Cert Manager in the workload cluster
5. Configure OIDC provider in AWS
6. Deploy the IRSA Pod IDentity webhook in the workload cluster
  
# Terraform Module Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 4.45.0)

- <a name="requirement_jwks"></a> [jwks](#requirement\_jwks) (0.0.1)

- <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) (>= 2.0.0)

- <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) (2.16.1)

- <a name="requirement_template"></a> [template](#requirement\_template) (2.2.0)

- <a name="requirement_tls"></a> [tls](#requirement\_tls) (4.0.4)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (~> 4.45.0)

- <a name="provider_jwks"></a> [jwks](#provider\_jwks) (0.0.1)

- <a name="provider_kubectl.mgmt"></a> [kubectl.mgmt](#provider\_kubectl.mgmt) (>= 2.0.0)

- <a name="provider_kubernetes.mgmt"></a> [kubernetes.mgmt](#provider\_kubernetes.mgmt) (2.16.1)

- <a name="provider_kubernetes.workload"></a> [kubernetes.workload](#provider\_kubernetes.workload) (2.16.1)

- <a name="provider_template"></a> [template](#provider\_template) (2.2.0)

- <a name="provider_tls"></a> [tls](#provider\_tls) (4.0.4)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) (resource)
- [aws_iam_role.tkg_irsa_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_s3_bucket.tkg_irsa_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) (resource)
- [aws_s3_object.discovery_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) (resource)
- [aws_s3_object.keys_json](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) (resource)
- [kubectl_manifest.cluster](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) (resource)
- [kubectl_manifest.irsa_app](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) (resource)
- [kubectl_manifest.tanzu_config_app](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) (resource)
- [kubectl_manifest.vsphere_creds](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) (resource)
- [kubernetes_secret.default](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/resources/secret) (resource)
- [jwks_from_pem.sa_signing_key](https://registry.terraform.io/providers/iwarapter/jwks/0.0.1/docs/data-sources/from_pem) (data source)
- [kubernetes_secret.sa_rsa_pub](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/data-sources/secret) (data source)
- [kubernetes_secret.workload_kubeconfig](https://registry.terraform.io/providers/hashicorp/kubernetes/2.16.1/docs/data-sources/secret) (data source)
- [template_file.cluster](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [template_file.discovery_json](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [template_file.irsa_app](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [template_file.keys_json](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [template_file.tanzu_config_app](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [template_file.vsphere_creds](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) (data source)
- [tls_certificate.bucket](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/data-sources/certificate) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile)

Description: The AWS profile to use for authentication to AWS

Type: `any`

### <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name)

Description: The name of the TKG cluster you want to create

Type: `any`

### <a name="input_mgmt_cluster_kube_context"></a> [mgmt\_cluster\_kube\_context](#input\_mgmt\_cluster\_kube\_context)

Description: The kubectl context of your TKG management cluster

Type: `any`

### <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key)

Description: SSH public key to configure for the capv user on the nodes

Type: `string`

### <a name="input_vsphere_password"></a> [vsphere\_password](#input\_vsphere\_password)

Description: vSphere Password for CPI and CSI

Type: `string`

### <a name="input_vsphere_username"></a> [vsphere\_username](#input\_vsphere\_username)

Description: vSphere User for CSI and CPI

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_auditLogging"></a> [auditLogging](#input\_auditLogging)

Description: Enable K8s Audit Logging

Type: `bool`

Default: `true`

### <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region)

Description: The AWS Region to deploy resources in

Type: `string`

Default: `"eu-west-2"`

### <a name="input_cloneMode"></a> [cloneMode](#input\_cloneMode)

Description: vSphere Clone method - fullClone or linkedClone

Type: `string`

Default: `"fullClone"`

### <a name="input_cluster_class_name"></a> [cluster\_class\_name](#input\_cluster\_class\_name)

Description: Cluster Class to use for provisioning the cluster

Type: `string`

Default: `"tkg-vsphere-default-v1.0.0"`

### <a name="input_cni"></a> [cni](#input\_cni)

Description: CNI to install. can be antrea or calico

Type: `string`

Default: `"antrea"`

### <a name="input_controlPlaneDiskGB"></a> [controlPlaneDiskGB](#input\_controlPlaneDiskGB)

Description: Control Plane Nodes disk size in GB

Type: `number`

Default: `50`

### <a name="input_controlPlaneMemoryMB"></a> [controlPlaneMemoryMB](#input\_controlPlaneMemoryMB)

Description: Control Plane Nodes RAM in MB

Type: `number`

Default: `8192`

### <a name="input_controlPlaneNumCPUs"></a> [controlPlaneNumCPUs](#input\_controlPlaneNumCPUs)

Description: Control Plane Nodes CPU count

Type: `number`

Default: `4`

### <a name="input_cp_node_count"></a> [cp\_node\_count](#input\_cp\_node\_count)

Description: Number of control plane nodes. for prod set to 3

Type: `number`

Default: `1`

### <a name="input_datacenter"></a> [datacenter](#input\_datacenter)

Description: vSphere Datacenter (full path) for VM placement

Type: `string`

Default: `"/Demo-Datacenter"`

### <a name="input_datastore"></a> [datastore](#input\_datastore)

Description: vSphere Datastore (full path) for VM Placement

Type: `string`

Default: `"/Demo-Datacenter/datastore/NFS_NLSAS_5"`

### <a name="input_folder"></a> [folder](#input\_folder)

Description: vSphere Folder (full path) for VM placement

Type: `string`

Default: `"/Demo-Datacenter/vm/LABS/Scott"`

### <a name="input_iam_role_configs"></a> [iam\_role\_configs](#input\_iam\_role\_configs)

Description: IAM Role configuration for IRSA Service Accounts

Type:

```hcl
list(object({
    ns_sa_string       = string
    managed_policy_arn = string
    name               = string
  }))
```

Default:

```json
[
  {
    "managed_policy_arn": "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "name": "demo-tkg-01-sample-role",
    "ns_sa_string": "default:sample-s3-ro-user"
  }
]
```

### <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version)

Description: Kubernetes version of the cluster to deploy

Type: `string`

Default: `"v1.24.9+vmware.1"`

### <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path)

Description: The file path to your local kubeconfig where you have contexts for your management cluster and workload clusters

Type: `string`

Default: `"~/.kube/config"`

### <a name="input_mgmt_cluster_namespace"></a> [mgmt\_cluster\_namespace](#input\_mgmt\_cluster\_namespace)

Description: Namespace in the MGMT cluster for creating the CAPI objects

Type: `string`

Default: `"default"`

### <a name="input_nameserver"></a> [nameserver](#input\_nameserver)

Description: Nameserver to configure on K8s nodes

Type: `string`

Default: `"10.100.100.100"`

### <a name="input_network"></a> [network](#input\_network)

Description: vSphere Port Group (full path) for node network

Type: `string`

Default: `"/Demo-Datacenter/network/tkg-static-ips"`

### <a name="input_os_name"></a> [os\_name](#input\_os\_name)

Description: OS to use for the nodes. can be photon or ubuntu

Type: `string`

Default: `"photon"`

### <a name="input_os_version"></a> [os\_version](#input\_os\_version)

Description: OS version of the nodes, 3 for photon or 2004 for ubuntu

Type: `number`

Default: `3`

### <a name="input_resourcePool"></a> [resourcePool](#input\_resourcePool)

Description: vSphere Resource Pool (full path) for machine placement

Type: `string`

Default: `"/Demo-Datacenter/host/Demo-Cluster/Resources"`

### <a name="input_searchDomain"></a> [searchDomain](#input\_searchDomain)

Description: DNS Search domain for K8s Nodes

Type: `string`

Default: `"terasky.demo"`

### <a name="input_server"></a> [server](#input\_server)

Description: vCenter FQDN or IP

Type: `string`

Default: `"demo-vc-01.terasky.demo"`

### <a name="input_storagePolicyID"></a> [storagePolicyID](#input\_storagePolicyID)

Description: vSphere Storage Policy ID for nodes and default vSphere CSI Storage Class

Type: `string`

Default: `""`

### <a name="input_template"></a> [template](#input\_template)

Description: vSphere Template (full path) to use for the clusters nodes

Type: `string`

Default: `"/Demo-Datacenter/vm/Templates/TKG-M/Photon/photon-3-kube-v1.24.9+vmware.1"`

### <a name="input_tlsThumbprint"></a> [tlsThumbprint](#input\_tlsThumbprint)

Description: vCenter TLS Thumbprint

Type: `string`

Default: `""`

### <a name="input_workerDiskGB"></a> [workerDiskGB](#input\_workerDiskGB)

Description: Worker Nodes disk size in GB

Type: `number`

Default: `50`

### <a name="input_workerMemoryMB"></a> [workerMemoryMB](#input\_workerMemoryMB)

Description: Worker Nodes RAM in MB

Type: `number`

Default: `8192`

### <a name="input_workerNumCPUs"></a> [workerNumCPUs](#input\_workerNumCPUs)

Description: Worker Nodes CPU count

Type: `number`

Default: `4`

### <a name="input_worker_node_count"></a> [worker\_node\_count](#input\_worker\_node\_count)

Description: Number of worker nodes to create

Type: `number`

Default: `1`

## Outputs

The following outputs are exported:

### <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles)

Description: n/a
<!-- END_TF_DOCS -->
