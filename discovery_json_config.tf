# Generate OIDC Dicovery JSON File
data "template_file" "discovery_json" {
  template = file("${path.module}/templates/discovery_json.tpl")
  vars = {
    region = var.aws_region
    bucket = aws_s3_bucket.tkg_irsa_bucket.id
  }
}

# Upload OIDC Discovery JSON File to the S3 bucket
resource "aws_s3_object" "discovery_json" {
  bucket       = aws_s3_bucket.tkg_irsa_bucket.id
  key          = ".well-known/openid-configuration"
  content      = data.template_file.discovery_json.rendered
  acl          = "public-read"
  content_type = "application/json"
}
