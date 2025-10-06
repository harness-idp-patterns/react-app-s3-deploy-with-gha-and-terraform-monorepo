# backend.tf
terraform {
  required_version = ">= 1.6"
  backend "s3" {}
}

