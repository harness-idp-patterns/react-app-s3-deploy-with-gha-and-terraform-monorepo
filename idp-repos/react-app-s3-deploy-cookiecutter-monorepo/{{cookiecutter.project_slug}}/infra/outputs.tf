output "bucket_name" {
  description = "Name of the S3 bucket hosting the site."
  value       = aws_s3_bucket.site.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "bucket_regional_domain_name" {
  description = "Regional S3 domain name (useful for CLI/debug)."
  value       = aws_s3_bucket.site.bucket_regional_domain_name
}

# Keep this name as-is unless you also update the workflow parser
output "cloudfront_distribution" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain" {
  description = "CloudFront domain (use this URL for testing)."
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_oac_id" {
  description = "Origin Access Control ID for the S3 origin."
  value       = aws_cloudfront_origin_access_control.oac.id
}

output "aws_region" {
  description = "AWS region used by the provider."
  value       = var.aws_region
}

output "project_slug" {
  description = "Project slug for tagging/naming."
  value       = var.project_slug
}

output "environment" {
  description = "Deployment environment (e.g., dev, prod)."
  value       = var.environment
}
