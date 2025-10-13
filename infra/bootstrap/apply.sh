#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}"

# Required inputs:
: "${AWS_REGION:=us-east-1}"
: "${GITHUB_ORG:=}"
: "${CUSTOMER_NAME:=}"

# Optional:
: "${GITHUB_REPO:=}"             # e.g., ${CUSTOMER_NAME}-repo (empty = any repo in org)
: "${ALLOWED_REFS:=refs/heads/main}"  # comma-separated
: "${ROLE_NAME:=gha-oidc-role}"
: "${ATTACH_BACKEND_ACCESS:=true}"
: "${SESSION_SECONDS:=3600}"

# Convert comma list to TF list syntax
IFS=',' read -ra REFS_ARR <<< "${ALLOWED_REFS}"
TF_REFS=$(printf '"%s", ' "${REFS_ARR[@]}"); TF_REFS="[${TF_REFS%, }]"

# --- Preflight: ensure AWS creds are live
if ! aws sts get-caller-identity