variable "region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for the TF state bucket; a random suffix is added"
  type        = string
  default     = "harnesspov-tfstate"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locks"
  type        = string
  default     = "tfstate-locks"
}

variable "key_prefix" {
  description = "Key prefix for state files (e.g., per-repo/monorepo)"
  type        = string
  default     = "monorepo"
}

variable "use_kms" {
  description = "Create a dedicated KMS key and use SSE-KMS for the bucket"
  type        = bool
  default     = false
}

variable "kms_alias" {
  description = "Alias to assign to the KMS key if use_kms=true"
  type        = string
  default     = "alias/tfstate"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project = "terraform-backend"
    Owner   = "HarnessPOV"
  }
}
