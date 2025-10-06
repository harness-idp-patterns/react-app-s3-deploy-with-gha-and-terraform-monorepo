# identity.tf
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition # aws / aws-us-gov / aws-cn
}

# Example usage:
# "arn:${local.partition}:s3:::${aws_s3_bucket.site.id}"
# "arn:${local.partition}:iam::${local.account_id}:role/whatever"
