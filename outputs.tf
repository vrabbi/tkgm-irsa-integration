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
  value = local.role_map
}
