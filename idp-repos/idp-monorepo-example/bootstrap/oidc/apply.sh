#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

# Required inputs:
: "${GITHUB_ORG:?Set GITHUB_ORG (e.g., harness-idp-sandbox)}"
# Optional:
: "${GITHUB_REPO:=}"             # e.g., monorepo-idp-example (empty = any repo in org)
: "${ALLOWED_REFS:=refs/heads/main}"  # comma-separated
: "${ROLE_NAME:=gha-oidc-role}"
: "${AWS_REGION:=us-east-1}"
: "${ATTACH_BACKEND_ACCESS:=true}"
: "${TFSTATE_BUCKET_ARN:=}"      # e.g., arn:aws:s3:::parson-tfstate-abc123
: "${LOCK_TABLE_ARN:=}"          # e.g., arn:aws:dynamodb:us-east-1:123456789012:table/tfstate-locks
: "${SESSION_SECONDS:=3600}"

# Convert comma list to TF list syntax
IFS=',' read -ra REFS_ARR <<< "${ALLOWED_REFS}"
TF_REFS=$(printf '"%s", ' "${REFS_ARR[@]}"); TF_REFS="[${TF_REFS%, }]"

pushd "${TF_DIR}" >/dev/null
  terraform init
  terraform apply -auto-approve \
    -var "region=${AWS_REGION}" \
    -var "github_org=${GITHUB_ORG}" \
    -var "github_repo=${GITHUB_REPO}" \
    -var 'allowed_refs='"${TF_REFS}" \
    -var "role_name=${ROLE_NAME}" \
    -var "session_duration_seconds=${SESSION_SECONDS}" \
    -var "attach_backend_access=${ATTACH_BACKEND_ACCESS}" \
    -var "tfstate_bucket_arn=${TFSTATE_BUCKET_ARN}" \
    -var "lock_table_arn=${LOCK_TABLE_ARN}"
  ROLE_ARN=$(terraform output -raw role_arn)
  OIDC_ARN=$(terraform output -raw oidc_provider_arn)
popd >/dev/null

# Handy .env for GitHub secrets
cat > "${ROOT}/oidc.env" <<EOF
AWS_GHA_ROLE_ARN=${ROLE_ARN}
AWS_REGION=${AWS_REGION}
EOF

echo
echo "✔ OIDC bootstrap complete."
echo "  OIDC provider: ${OIDC_ARN}"
echo "  Role ARN:      ${ROLE_ARN}"
echo
echo "Wrote: ${ROOT}/oidc.env  (copy AWS_GHA_ROLE_ARN into your repo/org secrets)"
