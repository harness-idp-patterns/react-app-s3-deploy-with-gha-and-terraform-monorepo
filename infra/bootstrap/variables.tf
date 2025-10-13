module "iac_state" {
  source = "./modules/iac-state"

  region            = var.region
  bucket_name_prefix = var.bucket_name_prefix
  lock_table_name   = var.lock_table_name
  tags              = var.tags
}

module "oidc" {
  source = "./modules/oidc"

  region                   = var.region
  github_org               = var.github_org
  github_repo              = var.github_repo
  allowed_refs             = var.allowed_refs
  role_name                = var.role_name
  session_duration_seconds = var.session_duration_seconds
}

output "bucket" {
  value = module.iac_state.bucket
}

output "dynamodb_table" {
  value = module.iac_state.dynamodb_table
}

output "region" {
  value = module.iac_state.region
}

output "role_arn" {
  value = module.oidc.role_arn
}

output "oidc_provider_arn" {
  value = module.oidc.oidc_provider_arn
}