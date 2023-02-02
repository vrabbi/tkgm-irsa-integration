# Create OIDC provider Backend S3 bucket
resource "aws_s3_bucket" "tkg_irsa_bucket" {
  bucket              = "${var.cluster_name}-irsa-bucket"
  force_destroy       = "false"
  object_lock_enabled = "false"

}

# Retrieve Certificate of the S3 Buckets URI
data "tls_certificate" "bucket" {
  url = "https://s3-${var.aws_region}.amazonaws.com/${aws_s3_bucket.tkg_irsa_bucket.id}"
}

# Create OIDC Provider with our new S3 Bucket as the backend
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [join("", data.tls_certificate.bucket.*.certificates.0.sha1_fingerprint)]
  url             = "https://s3-${var.aws_region}.amazonaws.com/${aws_s3_bucket.tkg_irsa_bucket.id}"
}
