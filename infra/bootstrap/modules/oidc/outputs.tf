#outputs.tf
output "role_arn" {
  value = aws_iam_role.gha_oidc.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}