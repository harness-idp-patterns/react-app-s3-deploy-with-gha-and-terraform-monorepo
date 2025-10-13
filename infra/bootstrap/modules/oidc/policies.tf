#policies.tf
# If caller provides policy JSON, attach it directly (preferred).
resource "aws_iam_policy" "backend_access_from_json" {
  count  = var.attach_backend_access && var.backend_access_policy_json != "" ? 1 : 0
  name   = "${var.role_name}-tf-backend"
  policy = var.backend_access_policy_json
  tags   = var.tags
}

# Fallback: synthesize minimal bucket-wide policy (less strict).
data "aws_iam_policy_document" "backend_fallback" {
  count = var.attach_backend_access && var.backend_access_policy_json == "" && var.tfstate_bucket_arn != "" && var.lock_table_arn != "" ? 1 : 0

  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.tfstate_bucket_arn]
  }

  statement {
    sid       = "RWStateObjects"
    actions   = ["s3:GetObject","s3:PutObject","s3:DeleteObject"]
    resources = ["${var.tfstate_bucket_arn}/*"]
  }

  statement {
    sid       = "LockTable"
    actions   = ["dynamodb:PutItem","dynamodb:GetItem","dynamodb:DeleteItem","dynamodb:UpdateItem"]
    resources = [var.lock_table_arn]
  }
}

resource "aws_iam_policy" "backend_access_fallback" {
  count  = length(data.aws_iam_policy_document.backend_fallback) == 1 ? 1 : 0
  name   = "${var.role_name}-tf-backend"
  policy = data.aws_iam_policy_document.backend_fallback[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_access" {
  count = (
    length(aws_iam_policy.backend_access_from_json) == 1
    ? 1
    : (length(aws_iam_policy.backend_access_fallback) == 1 ? 1 : 0)
  )
  role       = aws_iam_role.gha_oidc.name
  policy_arn = length(aws_iam_policy.backend_access_from_json) == 1
    ? aws_iam_policy.backend_access_from_json[0].arn
    : aws_iam_policy.backend_access_fallback[0].arn
}

