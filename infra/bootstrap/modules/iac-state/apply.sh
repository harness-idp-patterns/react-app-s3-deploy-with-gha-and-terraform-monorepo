#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

: "${AWS_REGION:=us-east-1}"
: "${USE_KMS:=false}"
: "${STATE_KEY_PREFIX_OVERRIDE:=}"   # allow caller to pass this

# --- Preflight: ensure AWS creds are live
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "❌ No valid AWS credentials found for this shell."
  echo "   Use 'aws sso login --profile <name>' + 'export AWS_PROFILE=<name>'"
  echo "   or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY [/ AWS_SESSION_TOKEN]."
  exit 1
fi

# --- Derive org/repo slug (for the recommended prefix) BEFORE TF apply
derive_slug() {
  local url
  url="$(git -C "${ROOT}/../.." config --get remote.origin.url 2>/dev/null || true)"
  # Matches both git@github.com:org/repo.git and https://github.com/org/repo(.git)
  if [[ "$url" =~ github\.com[:/]+([^/]+)/([^/.]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  fi
}
SLUG="$(derive_slug || true)"

# Recommended default: repos/<org>/<repo>
STATE_KEY_PREFIX_DEFAULT="repos/${SLUG:-<org>/<repo>}"
if [[ -n "$STATE_KEY_PREFIX_OVERRIDE" ]]; then
  STATE_KEY_PREFIX_DEFAULT="$STATE_KEY_PREFIX_OVERRIDE"
fi

# --- Provision backend infra (now with the exact state_key_prefix)
pushd "${TF_DIR}" >/dev/null
  terraform init -input=false
  terraform apply -auto-approve -input=false \
    -var "region=${AWS_REGION}" \
    -var "use_kms=${USE_KMS}" \
    -var "state_key_prefix=${STATE_KEY_PREFIX_DEFAULT}"
  BUCKET=$(terraform output -raw bucket)
  TABLE=$(terraform output -raw dynamodb_table)
  REGION=$(terraform output -raw region)
  BACKEND_EXAMPLE=$(terraform output -raw backend_hcl_example)
popd >/dev/null

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TFSTATE_BUCKET_ARN="arn:aws:s3:::${BUCKET}"
LOCK_TABLE_ARN="arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${TABLE}"

# --- Write the original example template (from TF outputs)
cat > "${ROOT}/backend.hcl.tpl" <<EOF
${BACKEND_EXAMPLE}
EOF

# --- Write the recommended template (stable key prefix)
cat > "${ROOT}/backend.hcl.recommended.tpl" <<EOF
bucket         = "${BUCKET}"
key            = "${STATE_KEY_PREFIX_DEFAULT}/<app-path>/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${TABLE}"
encrypt        = true
EOF

# --- Convenience .env (handy for GH Actions repo secrets)
cat > "${ROOT}/backend.env" <<EOF
TFSTATE_BUCKET=${BUCKET}
TF_LOCK_TABLE=${TABLE}
AWS_REGION=${REGION}
STATE_KEY_PREFIX=${STATE_KEY_PREFIX_DEFAULT}
# Useful for OIDC bootstrap (attach backend access policy):
TFSTATE_BUCKET_ARN=${TFSTATE_BUCKET_ARN}
LOCK_TABLE_ARN=${LOCK_TABLE_ARN}
EOF

echo
echo "✔ Remote state bootstrap complete."
echo "  S3 bucket:        ${BUCKET}"
echo "  DynamoDB table:   ${TABLE}"
echo "  Region:           ${REGION}"
echo
echo "Wrote:"
echo "  - ${ROOT}/backend.hcl.tpl              (original example; contains <project_slug>)"
echo "  - ${ROOT}/backend.hcl.recommended.tpl (preferred: key uses '${STATE_KEY_PREFIX_DEFAULT}/<app-path>')"
echo "  - ${ROOT}/backend.env                 (values to copy into GH repo secrets)"

# --- NEXT STEPS (friendly guide)
NEXT="${ROOT}/NEXT_STEPS.txt"
cat > "$NEXT" <<EOF
Remote backend is ready ✅

Add these GitHub secrets in your monorepo (Settings → Secrets → Actions):
  TFSTATE_BUCKET=${BUCKET}
  TF_LOCK_TABLE=${TABLE}
  AWS_REGION=${REGION}
  STATE_KEY_PREFIX=${STATE_KEY_PREFIX_DEFAULT}

(If you're bootstrapping the OIDC role and want to attach backend access:)
  TFSTATE_BUCKET_ARN=${TFSTATE_BUCKET_ARN}
  LOCK_TABLE_ARN=${LOCK_TABLE_ARN}

Recommended backend.hcl (replace <app-path> with e.g. apps/my-react-app):
-----------------------------------------------
bucket         = "${BUCKET}"
key            = "${STATE_KEY_PREFIX_DEFAULT}/<app-path>/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${TABLE}"
encrypt        = true
-----------------------------------------------

In your workflow, write backend.hcl like:
-----------------------------------------------
cat > backend.hcl <<'EOT'
bucket         = "\${{ secrets.TFSTATE_BUCKET }}"
key            = "\${{ secrets.STATE_KEY_PREFIX }}/\${{ needs.detect.outputs.project_path }}/terraform.tfstate"
region         = "\${{ secrets.AWS_REGION }}"
dynamodb_table = "\${{ secrets.TF_LOCK_TABLE }}"
encrypt        = true
EOT
-----------------------------------------------
EOF

echo "📄 Wrote next steps to: $NEXT"
echo "   Copy these into GitHub repo secrets:"
echo "     - TFSTATE_BUCKET=${BUCKET}"
echo "     - TF_LOCK_TABLE=${TABLE}"
echo "     - AWS_REGION=${REGION}"
echo "     - STATE_KEY_PREFIX=${STATE_KEY_PREFIX_DEFAULT}"

# Optional: set secrets automatically with GitHub CLI if available
if command -v gh >/dev/null 2>&1; then
  echo
  read -r -p "Use 'gh secret set' to push these to the current repo? [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    gh secret set TFSTATE_BUCKET   -b "${BUCKET}"
    gh secret set TF_LOCK_TABLE    -b "${TABLE}"
    gh secret set AWS_REGION       -b "${REGION}"
    gh secret set STATE_KEY_PREFIX -b "${STATE_KEY_PREFIX_DEFAULT}"
    echo "✔ Secrets set via GitHub CLI."
  fi
fi
