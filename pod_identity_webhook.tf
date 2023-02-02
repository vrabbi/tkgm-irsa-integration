# Template the kapp app CR that installs the pod identity webhook in the cluster
data "template_file" "irsa_app" {
  template = file("${path.module}/templates/irsa-app.yaml.tpl")
  vars = {
    cluster_name = var.cluster_name
    namespace    = var.mgmt_cluster_namespace
  }
}

# Deploy the pod identity webhook via kapp controller into the workload cluster
resource "kubectl_manifest" "irsa_app" {
  depends_on    = [aws_s3_object.keys_json]
  provider      = kubectl.mgmt
  yaml_body     = data.template_file.irsa_app.rendered
  ignore_fields = ["spec"]
  wait_for {
    field {
      key   = "status.friendlyDescription"
      value = "Reconcile succeeded"
    }
  }
}
