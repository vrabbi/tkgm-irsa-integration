# Get the kubeconfig of the workload cluster from the secret in the management cluster
data "kubernetes_secret" "workload_kubeconfig" {
  depends_on = [kubectl_manifest.cluster]
  provider   = kubernetes.mgmt
  metadata {
    name      = "${var.cluster_name}-kubeconfig"
    namespace = var.mgmt_cluster_namespace
  }
}

# extract relevant details from the kubeconfig secret into local variables to be used by the kubernetes provider for the workload cluster
locals {
  ca   = base64decode(yamldecode(data.kubernetes_secret.workload_kubeconfig.data.value).clusters[0].cluster.certificate-authority-data)
  url  = yamldecode(data.kubernetes_secret.workload_kubeconfig.data.value).clusters[0].cluster.server
  cert = base64decode(yamldecode(data.kubernetes_secret.workload_kubeconfig.data.value).users[0].user.client-certificate-data)
  key  = base64decode(yamldecode(data.kubernetes_secret.workload_kubeconfig.data.value).users[0].user.client-key-data)
}
