# Create IAM Roles for use with IRSA
resource "aws_iam_role" "tkg_irsa_role" {
  for_each = { for config in var.iam_role_configs : config.name => config }
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc_provider.arn
      }
      Condition = {
        StringLike = {
          "${aws_iam_openid_connect_provider.oidc_provider.url}:aud" : "sts.amazonaws.com",
          "${aws_iam_openid_connect_provider.oidc_provider.url}:sub" : [
            "system:serviceaccount:${each.value.ns_sa_string}"
          ]
        }
      }
    }]
    Version = "2012-10-17"
  })
  managed_policy_arns  = [each.value.managed_policy_arn]
  max_session_duration = "3600"
  name                 = each.value.name
  path                 = "/"
}
