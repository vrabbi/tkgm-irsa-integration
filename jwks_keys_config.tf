# Get The SA Signing Key From The MGMT Cluster
data "kubernetes_secret" "sa_rsa_pub" {
  depends_on = [kubectl_manifest.tanzu_config_app]
  provider   = kubernetes.mgmt
  metadata {
    name      = "${var.cluster_name}-sa"
    namespace = "default"
  }
}

# Create Base JWKS Data Structure From The SA Signing Key
data "jwks_from_pem" "sa_signing_key" {
  depends_on = [kubectl_manifest.tanzu_config_app]
  pem        = data.kubernetes_secret.sa_rsa_pub.data["tls.crt"]
}

# Create K8s secret with service account token for the default SA in the workload cluster
# This is needed in K8s 1.24 and above as service account token secrets are no longer created by default for every SA
# We need this secret to be able to disect data from the JWT Token that is generated in this secret
resource "kubernetes_secret" "default" {
  depends_on = [kubectl_manifest.tanzu_config_app]
  provider   = kubernetes.workload
  type       = "kubernetes.io/service-account-token"
  metadata {
    name = "default"
    annotations = {
      "kubernetes.io/service-account.name" = "default"
    }
    namespace = "default"
  }
}

# Extract the Key ID in the way kubernetes represents it from the SAs JWT Token Headers
locals {
  token_headers = try(split(".", kubernetes_secret.default.data.token)[0], "")
  token_fixed   = "${local.token_headers}=="
  kid           = try(jsondecode(base64decode(local.token_fixed)).kid, null)
  alg           = try(jsondecode(base64decode(local.token_fixed)).alg, null)
  jwks_data     = try(jsondecode(data.jwks_from_pem.sa_signing_key.jwks), null)
}


# Generate OIDC Keys JSON file with JWKS data
data "template_file" "keys_json" {
  depends_on = [kubectl_manifest.tanzu_config_app]
  template   = file("${path.module}/templates/keys_json.tpl")
  vars = {
    kid = local.kid
    kty = local.jwks_data.kty
    e   = local.jwks_data.e
    n   = local.jwks_data.n
    use = "sig"
    alg = local.alg
  }
}

# Push the OIDC keys JSON file to S3 bucket
resource "aws_s3_object" "keys_json" {
  depends_on   = [kubectl_manifest.tanzu_config_app]
  bucket       = aws_s3_bucket.tkg_irsa_bucket.id
  key          = "keys.json"
  content      = data.template_file.keys_json.rendered
  acl          = "public-read"
  content_type = "application/json"
}
