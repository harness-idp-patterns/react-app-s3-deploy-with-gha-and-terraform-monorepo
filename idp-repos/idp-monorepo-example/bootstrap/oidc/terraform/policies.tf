# Minimal backend access policy (optional)
data "aws_iam_policy_document" "tf_backend_access" {
  statement {
    sid     = "StateList"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      var.tfstate_bucket_arn
    ]
  }
  statement {
    sid     = "StateRW"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${var.tfstate_bucket_arn}/*"
    ]
  }
  statement {
    sid    = "LockTableRW"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem", "dynamodb:PutItem",
      "dynamodb:DeleteItem", "dynamodb:UpdateItem"
    ]
    resources = [var.lock_table_arn]
  }
}

resource "aws_iam_policy" "tf_backend_access" {
  count       = var.attach_backend_access && var.tfstate_bucket_arn != "" && var.lock_table_arn != "" ? 1 : 0
  name        = "${var.role_name}-tf-backend"
  description = "Allow Terraform state read/write and lock ops"
  policy      = data.aws_iam_policy_document.tf_backend_access.json
}
