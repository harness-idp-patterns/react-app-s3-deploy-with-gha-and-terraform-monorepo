variable "region" {
  description = "AWS region for IAM (global-ish, but keep consistent)"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub org that will assume the role"
  type        = string
}

variable "github_repo" {
  description = "Optional: limit trust to a single repository (org/repo). If empty, all repos in org are allowed."
  type        = string
  default     = ""
}

variable "allowed_refs" {
  description = "Allowed refs (branches/tags) for OIDC subject matching, e.g., [\"refs/heads/main\", \"refs/tags/v*\"]"
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "gha-oidc-role"
}

variable "session_duration_seconds" {
  description = "Max session duration for role (must be <= 43200)"
  type        = number
  default     = 3600
}

# Optional: attach backend access so this role can read/write tfstate + locks.
variable "attach_backend_access" {
  description = "Attach S3+DynamoDB policy for Terraform backend to this role"
  type        = bool
  default     = true
}
variable "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state (if attach_backend_access=true)"
  type        = string
  default     = ""
}
variable "lock_table_arn" {
  description = "ARN of the DynamoDB lock table (if attach_backend_access=true)"
  type        = string
  default     = ""
}

# Extra policies for your infra apply/destroy (add as needed)
variable "managed_policy_arns" {
  description = "Additional AWS managed policy ARNs to attach to the role (optional)"
  type        = list(string)
  default     = []
}
