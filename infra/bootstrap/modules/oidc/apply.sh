#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

# ========= Required =========
: "${GITHUB_ORG:?Set GITHUB_ORG (e.g., harness-idp-sandbox)}"

# ========= Optional (sane defaults) =========
: "${GITHUB_REPO:=}"                           # empty => any repo in org
: "${ALLOWED_SUBJECTS:=refs/heads/main}"       # CSV: refs/heads/main,pull_request,environment:dev
: "${ROLE_NAME:=gha-oidc-role}"
: "${SESSION_SECONDS:=3600}"                    # <= 43200
: "${AWS_REGION:=us-east-1}"

# OIDC provider controls (prefer NOT creating provider here)
: "${CREATE_OIDC_PROVIDER:=false}"              # true to create provider in this account
: "${EXISTING_OIDC_PROVIDER_ARN:=}"             # e.g. arn:aws:iam::<acct>:oidc-provider/token.actions.githubusercontent.com
: "${OIDC_THUMBPRINTS:=6938fd4d98bab03faadb97b34396831e3780aea1}"  # CSV

# Backend access (prefer path-scoped JSON from iac-state)
: "${ATTACH_BACKEND_ACCESS:=false}"
: "${BACKEND_POLICY_JSON:=}"                    # raw JSON from iac-state (preferred)
: "${BACKEND_POLICY_JSON_B64:=}"                # or base64-encoded JSON
: "${TFSTATE_BUCKET_ARN:=}"                     # fallback if no JSON
: "${LOCK_TABLE_ARN:=}"                         # fallback if no JSON

# ========= Preflight =========
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "❌ No valid AWS credentials. Run 'aws sso login' and set AWS_PROFILE, or export keys."
  exit 1
fi

# CSV -> Terraform list helpers
csv_to_tf_list() {  # usage: csv_to_tf_list "a,b,c"
  local IFS=','; read -ra A <<< "$1"; local out=
  for x in "${A[@]}"; do out+=$(printf '"%s", ' "$x"); done
  printf '[%s]' "${out%, }"
}

TF_SUBJS="$(csv_to_tf_list "${ALLOWED_SUBJECTS}")"
TF_TPS="$(csv_to_tf_list "${OIDC_THUMBPRINTS}")"

# Decide how to pass backend access
BACKEND_VARS=( "-var" "attach_backend_access=${ATTACH_BACKEND_ACCESS}" )
if [[ -n "$BACKEND_POLICY_JSON" ]]; then
  BACKEND_VARS+=( "-var" "backend_access_policy_json=${BACKEND_POLICY_JSON}" )
elif [[ -n "$BACKEND_POLICY_JSON_B64" ]]; then
  BACKEND_VARS+=( "-var" "backend_access_policy_json=$(printf %s "$BACKEND_POLICY_JSON_B64" | base64 -d)" )
else
  BACKEND_VARS+=( "-var" "tfstate_bucket_arn=${TFSTATE_BUCKET_ARN}" "-var" "lock_table_arn=${LOCK_TABLE_ARN}" )
fi

# ========= Terraform =========
pushd "${TF_DIR}" >/dev/null
  terraform init -input=false
  terraform apply -auto-approve -input=false \
    -var "region=${AWS_REGION}" \
    -var "github_org=${GITHUB_ORG}" \
    -var "github_repo=${GITHUB_REPO}" \
    -var 'allowed_subjects='"${TF_SUBJS}" \
    -var "role_name=${ROLE_NAME}" \
    -var "session_duration_seconds=${SESSION_SECONDS}" \
    -var "create_oidc_provider=${CREATE_OIDC_PROVIDER}" \
    -var "existing_oidc_provider_arn=${EXISTING_OIDC_PROVIDER_ARN}" \
    -var 'oidc_thumbprint_list='"${TF_TPS}" \
    "${BACKEND_VARS[@]}"

  ROLE_ARN=$(terraform output -raw role_arn)
  OIDC_ARN=$(terraform output -raw oidc_provider_arn)
popd >/dev/null

# ========= Outputs for CI =========
cat > "${ROOT}/oidc.env" <<EOF
AWS_GHA_ROLE_ARN=${ROLE_ARN}
AWS_REGION=${AWS_REGION}
EOF

echo
echo "✔ OIDC bootstrap complete."
echo "  OIDC provider ARN: ${OIDC_ARN}"
echo "  Role ARN:          ${ROLE_ARN}"
echo
echo "Wrote: ${ROOT}/oidc.env  (copy AWS_GHA_ROLE_ARN into repo/org secrets)"
