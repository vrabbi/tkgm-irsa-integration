# Generate vSphere creds secret manifest
data "template_file" "vsphere_creds" {
  template = file("${path.module}/templates/vsphere-creds.yaml.tpl")
  vars = {
    cluster_name     = var.cluster_name
    namespace        = var.mgmt_cluster_namespace
    vsphere_password = base64encode(var.vsphere_password)
    vsphere_username = base64encode(var.vsphere_username)
  }
}

# Generate TKG Cluster YAML manifest
data "template_file" "cluster" {
  template = file("${path.module}/templates/cluster.yaml.tpl")
  vars = {
    os_version            = var.os_version
    cluster_name          = var.cluster_name
    namespace             = var.mgmt_cluster_namespace
    cluster_class_name    = var.cluster_class_name
    os_name               = var.os_name
    cp_node_count         = var.cp_node_count
    ssh_public_key        = var.ssh_public_key
    k8s_version           = var.k8s_version
    worker_node_count     = var.worker_node_count
    aws_region            = var.aws_region
    cloneMode             = var.cloneMode
    datacenter            = var.datacenter
    datastore             = var.datastore
    folder                = var.folder
    network               = var.network
    resourcePool          = var.resourcePool
    server                = var.server
    storagePolicyID       = var.storagePolicyID
    template              = var.template
    tlsThumbprint         = var.tlsThumbprint
    cni                   = var.cni
    auditLogging          = var.auditLogging
    controlPlaneDiskGB   = var.controlPlaneDiskGB
    controlPlaneMemoryMB = var.controlPlaneMemoryMB
    controlPlaneNumCPUs   = var.controlPlaneNumCPUs
    workerDiskGB         = var.workerDiskGB
    workerMemoryMB       = var.workerMemoryMB
    workerNumCPUs         = var.workerNumCPUs
    nameserver            = var.nameserver
    searchDomain          = var.searchDomain
  }
}

# Create vSphere authentication secret
resource "kubectl_manifest" "vsphere_creds" {
  provider      = kubectl.mgmt
  yaml_body     = data.template_file.vsphere_creds.rendered
  ignore_fields = ["data"]
}

# Create the TKG Cluster and wait for API server to be up and ready
resource "kubectl_manifest" "cluster" {
  depends_on    = [kubectl_manifest.vsphere_creds]
  provider      = kubectl.mgmt
  yaml_body     = data.template_file.cluster.rendered
  ignore_fields = ["spec"]
  wait_for {
    field {
      key   = "status.controlPlaneReady"
      value = true
    }
    field {
      key   = "status.infrastructureReady"
      value = true
    }
    field {
      key   = "status.phase"
      value = "Provisioned"
    }
  }
}
