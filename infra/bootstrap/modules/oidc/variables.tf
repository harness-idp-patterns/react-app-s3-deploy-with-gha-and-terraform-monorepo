#variables.tf
variable "region" { type = string, default = "us-east-1" }

variable "github_org"  { type = string }
variable "github_repo" { type = string, default = "" } # empty => all repos in org

# Accept both branch/tag refs and special subjects like "pull_request" or "environment:dev"
variable "allowed_subjects" {
  description = <<EOT
Subjects allowed to assume the role. Examples:
- "refs/heads/main"
- "refs/tags/*"
- "pull_request"
- "environment:dev"
EOT
  type    = list(string)
  default = ["refs/heads/main"]
}

variable "role_name"                 { type = string, default = "gha-oidc-role" }
variable "session_duration_seconds"  { type = number, default = 3600 }

# OIDC provider controls
variable "create_oidc_provider"      { type = bool,   default = false }
variable "existing_oidc_provider_arn"{ type = string, default = "" }
variable "oidc_thumbprint_list" {
  type    = list(string)
  default = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # override if needed
}

# Optional backend access (prefer prefix-scoped JSON from iac-state)
variable "attach_backend_access" { type = bool,   default = false }
variable "backend_access_policy_json" {
  description = "If provided, this policy JSON is attached verbatim to the role (use iac-state's output)."
  type        = string
  default     = ""
}
variable "tfstate_bucket_arn" { type = string, default = "" } # used only if JSON not provided
variable "lock_table_arn"     { type = string, default = "" }

variable "tags" { type = map(string), default = {} }
