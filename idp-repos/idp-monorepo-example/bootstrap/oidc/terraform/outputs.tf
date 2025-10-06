output "role_arn" {
  value       = aws_iam_role.gha_oidc.arn
  description = "Put this in GitHub as AWS_GHA_ROLE_ARN"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "GitHub OIDC provider ARN"
}
