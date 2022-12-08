locals {
  ytt_text = <<NEXTSTEPS
# Step 1 - If you have not done this yet
$ cat <<EOF > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/irsa_overlay.yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")
#@overlay/match by=overlay.subset({"kind":"KubeadmControlPlane"})
---
spec:
  kubeadmConfigSpec:
    clusterConfiguration:
      apiServer:
        extraArgs:
          #@overlay/match missing_ok=True
          api-audiences: "sts.amazonaws.com"
          #@overlay/match missing_ok=True
          service-account-issuer: #@ "https://s3-${var.aws_region}.amazonaws.com/{}-irsa-bucket".format(data.values.CLUSTER_NAME)
EOF

# Step 2 - Create the cluster as usual
$ tanzu cluster create -f <CLUSTER CONFIG FILE>

# Step 3 - Get the kubeconfig and change contexts to the new workload cluster
$ tanzu cluster kubeconfig get --admin "${var.cluster_name}"
$ kubectl config use-context "${var.cluster_name}-admin@${var.cluster_name}"

# Step 4 - Install Cert Manager To the Cluster
tanzu package install cert-manager -p cert-manager.tanzu.vmware.com -v 1.7.2+vmware.1-tkg.1 --create-namespace -n tkg-packages

# Step 5 - Change the variable for cluster provisioned to true and rerun this terraform module
NEXTSTEPS
}

output "next_steps" {
  value = var.cluster_created ? null : local.ytt_text
}

locals {
  role_map = [
    for role in aws_iam_role.tkg_irsa_role : {
      "NAME" : role.name,
      "ARN" : role.arn,
      "SUBJECT" : jsondecode(role.assume_role_policy).Statement[0].Condition.StringLike["s3-${var.aws_region}.amazonaws.com/${var.cluster_name}-irsa-bucket:sub"],
    }
  ]
}

output "iam_roles" {
  value = var.cluster_created ? local.role_map : null
}
