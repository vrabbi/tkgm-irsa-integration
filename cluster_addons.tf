# Generate App manifest for installing the TKG Package Repo and Cert Manager
data "template_file" "tanzu_config_app" {
  template = file("${path.module}/templates/tanzu-config-app.yaml.tpl")
  vars = {
    cluster_name = var.cluster_name
    namespace    = var.mgmt_cluster_namespace
  }
}

# Create the TKG Config App CR and wait for it to complete
resource "kubectl_manifest" "tanzu_config_app" {
  depends_on    = [kubectl_manifest.cluster]
  provider      = kubectl.mgmt
  yaml_body     = data.template_file.tanzu_config_app.rendered
  ignore_fields = ["spec"]
  wait_for {
    field {
      key   = "status.friendlyDescription"
      value = "Reconcile succeeded"
    }
  }
}
