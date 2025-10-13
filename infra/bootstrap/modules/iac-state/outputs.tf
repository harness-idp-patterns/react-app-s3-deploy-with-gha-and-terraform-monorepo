# outputs.tf
output "bucket"             { value = aws_s3_bucket.tf.bucket }
output "bucket_arn"         { value = aws_s3_bucket.tf.arn }
output "dynamodb_table"     { value = aws_dynamodb_table.locks.name }
output "dynamodb_table_arn" { value = aws_dynamodb_table.locks.arn }
output "region"             { value = var.region }

# policy JSON your OIDC role module can attach directly
output "backend_access_policy_json" {
  value = data.aws_iam_policy_document.backend_access.json
}

# helper template for backend.hcl (keeps your recommended pattern)
output "backend_hcl_example" {
  value = <<EOT
bucket         = "${aws_s3_bucket.tf.bucket}"
key            = "${var.state_key_prefix}/<app-path>/terraform.tfstate"
region         = "${var.region}"
dynamodb_table = "${aws_dynamodb_table.locks.name}"
encrypt        = true
EOT
}

output "backend_access_policy_encoded" {
  description = "Base64-encoded version of backend access policy"
  value       = base64encode(data.aws_iam_policy_document.backend_access.json)
}

output "backend_metadata" {
  description = "Convenient map of backend values"
  value = {
    bucket         = aws_s3_bucket.tf.bucket
    bucket_arn     = aws_s3_bucket.tf.arn
    dynamodb_table = aws_dynamodb_table.locks.name
    dynamodb_arn   = aws_dynamodb_table.locks.arn
    region         = var.region
  }
}
