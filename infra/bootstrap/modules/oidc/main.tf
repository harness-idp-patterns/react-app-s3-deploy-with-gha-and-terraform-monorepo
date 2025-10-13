#main.tf
# Create GitHub OIDC provider if your account doesn't have it yet
# Thumbprints are managed by AWS provider; update if ever needed.
# Optionally create the account-level GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprint_list
  tags            = var.tags
}

resource "aws_iam_role" "gha_oidc" {
  name                 = var.role_name
  description          = "Role assumed by GitHub Actions via OIDC for ${var.github_org}/${var.github_repo != "" ? var.github_repo : "*"}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.session_duration_seconds
  tags                 = var.tags
}

# Choose provider ARN (created or pre-existing)
locals {
  oidc_provider_arn = var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : var.existing_oidc_provider_arn
  repo_selector = trim(var.github_repo) != "" ? "repo:${var.github_org}/${var.github_repo}" : "repo:${var.github_org}/*"

  # If subject starts with "refs/", format as "...:ref:<ref>".
  # Otherwise pass it through verbatim (e.g., "pull_request", "environment:dev").
  subject_patterns = [
    for s in var.allowed_subjects :
      startswith(s, "refs/")
      ? "${local.repo_selector}:ref:${s}"
      : "${local.repo_selector}:${s}"
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subject_patterns
    }
  }
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