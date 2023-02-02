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

variable "mgmt_cluster_namespace" {
  type        = string
  default     = "default"
  description = "Namespace in the MGMT cluster for creating the CAPI objects"
}

variable "cluster_class_name" {
  type        = string
  default     = "tkg-vsphere-default-v1.0.0"
  description = "Cluster Class to use for provisioning the cluster"
}

variable "os_name" {
  type        = string
  default     = "photon"
  description = "OS to use for the nodes. can be photon or ubuntu"
}

variable "cp_node_count" {
  type        = number
  default     = 1
  description = "Number of control plane nodes. for prod set to 3"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to configure for the capv user on the nodes"
}

variable "k8s_version" {
  type        = string
  default     = "v1.24.9+vmware.1"
  description = "Kubernetes version of the cluster to deploy"
}

variable "worker_node_count" {
  type        = number
  default     = 1
  description = "Number of worker nodes to create"
}

variable "vsphere_password" {
  type        = string
  description = "vSphere Password for CPI and CSI"
}

variable "vsphere_username" {
  type        = string
  description = "vSphere User for CSI and CPI"
}

variable "os_version" {
  type        = number
  default     = 3
  description = "OS version of the nodes, 3 for photon or 2004 for ubuntu"
}

variable "cloneMode" {
  type        = string
  default     = "fullClone"
  description = "vSphere Clone method - fullClone or linkedClone"
}
variable "datacenter" {
  type        = string
  default     = "/Demo-Datacenter"
  description = "vSphere Datacenter (full path) for VM placement"
}
variable "datastore" {
  type        = string
  default     = "/Demo-Datacenter/datastore/NFS_NLSAS_5"
  description = "vSphere Datastore (full path) for VM Placement"
}
variable "folder" {
  type        = string
  default     = "/Demo-Datacenter/vm/LABS/Scott"
  description = "vSphere Folder (full path) for VM placement"
}
variable "network" {
  type        = string
  default     = "/Demo-Datacenter/network/tkg-static-ips"
  description = "vSphere Port Group (full path) for node network"
}
variable "resourcePool" {
  type        = string
  default     = "/Demo-Datacenter/host/Demo-Cluster/Resources"
  description = "vSphere Resource Pool (full path) for machine placement"
}
variable "server" {
  type        = string
  default     = "demo-vc-01.terasky.demo"
  description = "vCenter FQDN or IP"
}
variable "storagePolicyID" {
  type        = string
  default     = ""
  description = "vSphere Storage Policy ID for nodes and default vSphere CSI Storage Class"
}
variable "template" {
  type        = string
  default     = "/Demo-Datacenter/vm/Templates/TKG-M/Photon/photon-3-kube-v1.24.9+vmware.1"
  description = "vSphere Template (full path) to use for the clusters nodes"
}
variable "tlsThumbprint" {
  type        = string
  default     = ""
  description = "vCenter TLS Thumbprint"
}

variable "auditLogging" {
  type        = bool
  default     = true
  description = "Enable K8s Audit Logging"
}

variable "cni" {
  type        = string
  default     = "antrea"
  description = "CNI to install. can be antrea or calico"
}

variable "controlPlaneDiskGB" {
  type        = number
  default     = 50
  description = "Control Plane Nodes disk size in GB"
}
variable "controlPlaneMemoryMB" {
  type        = number
  default     = 8192
  description = "Control Plane Nodes RAM in MB"
}
variable "controlPlaneNumCPUs" {
  type        = number
  default     = 4
  description = "Control Plane Nodes CPU count"
}
variable "workerDiskGB" {
  type        = number
  default     = 50
  description = "Worker Nodes disk size in GB"
}
variable "workerMemoryMB" {
  type        = number
  default     = 8192
  description = "Worker Nodes RAM in MB"
}
variable "workerNumCPUs" {
  type        = number
  default     = 4
  description = "Worker Nodes CPU count"
}
variable "nameserver" {
  type        = string
  default     = "10.100.100.100"
  description = "Nameserver to configure on K8s nodes"
}
variable "searchDomain" {
  type        = string
  default     = "terasky.demo"
  description = "DNS Search domain for K8s Nodes"
}
