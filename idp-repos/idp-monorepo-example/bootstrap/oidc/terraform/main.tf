# Create GitHub OIDC provider if your account doesn't have it yet
# Thumbprints are managed by AWS provider; update if ever needed.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub Actions OIDC root CA at time of writing
}

# 2) Trust policy for GitHub → IAM role
locals {
  repo_selector = trim(var.github_repo) != "" ? "repo:${var.github_org}/${var.github_repo}" : "repo:${var.github_org}/*"
  sub_patterns  = [for r in var.allowed_refs : "${local.repo_selector}:ref:${r}"]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.sub_patterns
    }
  }
}

resource "aws_iam_role" "gha_oidc" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.session_duration_seconds
  description          = "Role assumed by GitHub Actions via OIDC for ${var.github_org}/${var.github_repo != "" ? var.github_repo : "*"}"
}

# Attach optional backend access (S3+DDB)
resource "aws_iam_role_policy_attachment" "tf_backend_attach" {
  count      = length(aws_iam_policy.tf_backend_access) == 1 ? 1 : 0
  role       = aws_iam_role.gha_oidc.name
  policy_arn = aws_iam_policy.tf_backend_access[0].arn
}

# Attach any extra managed policies you want (e.g., AmazonS3ReadOnlyAccess during testing)
resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.gha_oidc.name
  policy_arn = each.value
}