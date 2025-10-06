output "region" { value = var.region }
output "bucket" { value = aws_s3_bucket.tfstate.bucket }
output "dynamodb_table" { value = aws_dynamodb_table.locks.name }
output "kms_key_arn" { value = try(aws_kms_key.tfstate[0].arn, null) }

output "backend_hcl_example" {
  description = "Drop-in backend.hcl (replace <project_slug>)"
  value       = <<EOT
bucket         = "${aws_s3_bucket.tfstate.bucket}"
key            = "${local.backend_key_template}"
region         = "${var.region}"
dynamodb_table = "${aws_dynamodb_table.locks.name}"
encrypt        = true
EOT
}
