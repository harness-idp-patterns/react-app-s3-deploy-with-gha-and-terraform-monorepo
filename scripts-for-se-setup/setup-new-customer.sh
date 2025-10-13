#!/usr/bin/env bash
set -euo pipefail

# ===================== Usage =====================
usage() {
  cat <<'EOF'
Bootstrap a new POV from the patterns repo.

USAGE:
  ./setup-new-customer.sh <CUSTOMER_NAME>
    [--patterns-org ORG]
    [--template-repo REPO]
    [--sandbox-org ORG]
    [--project-id ID]
    [--org-id ID]
    [--account-id ID]
    [--pipeline-name NAME]
    [--pipeline-identifier ID]
    [--jira-connector REF]
    [--jira-project-key KEY]
    [--k8s-connector REF]
    [--delegate-namespace NS]
    [--delegate-selector LABEL]
    [--registry-ref REF]
    [--runner-image IMAGE]
    [--git-connector REF]
    [--servicenow-connector REF]
    [--registry-connector-images REF]
    [--cookiecutter-template-url URL]
    [--github-org ORG]
    [--monorepo-name NAME]
    [--gh-token-secret SECRET_REF]
    [--catalog-github-connector REF]
    [--harness-platform-api-key-secret SECRET_REF]
    [--dry-run]
    [--skip-replace]
    [-h|--help]

NOTES:
- CUSTOMER_NAME becomes <customer>-admin and <customer>-monorepo.
- Replacements are applied to YAMLs unless --skip-replace is provided.
- CUSTOMER_NAME must match: ^[a-z0-9][a-z0-9-]*$

EOF
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }
[[ $# -lt 1 ]] && { echo "ERROR: CUSTOMER_NAME is required"; usage; exit 1; }

CUSTOMER_NAME="$(echo -n "$1" | tr '[:upper:]' '[:lower:]')"; shift || true
[[ "$CUSTOMER_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "ERROR: invalid CUSTOMER_NAME: $CUSTOMER_NAME"; exit 1; }

# ===================== Defaults =====================
PATTERNS_ORG="harness-idp-patterns"
TEMPLATE_REPO="react-app-s3-deploy-with-gha-and-terraform-monorepo"
SANDBOX_ORG="harness-idp-sandbox"

PROJECT_ID="$CUSTOMER_NAME"
ORG_ID="sandbox"
ACCOUNT_ID="${HARNESS_ACCOUNT_ID:-}" # can be overridden via flag

PIPELINE_NAME="E2E React App Provisioning (${CUSTOMER_NAME})"
PIPELINE_IDENTIFIER="e2e_react_app_provisioning_${CUSTOMER_NAME}"

# Connector & infra defaults (override via flags/env)
JIRA_CONNECTOR="account.Harness_Jira"
JIRA_PROJECT_KEY="HD"
K8S_CONNECTOR="account.harnesseks"
DELEGATE_NAMESPACE="harness-delegate-ng"
DELEGATE_SELECTOR="parson-eks-delegate"
REGISTRY_REF="org.org-docker"
RUNNER_IMAGE="parsontodd/harness-custom-runner:latest"
GIT_CONNECTOR="account.harnessgithub"
SERVICENOW_CONNECTOR="account.Harness_ServiceNow"
REGISTRY_CONNECTOR_FOR_IMAGES="account.Harness_Docker"
COOKIECUTTER_TEMPLATE_URL="https://github.com/harness-idp-sandbox/app-template-react-monorepo.git"
GITHUB_ORG="$SANDBOX_ORG"
MONOREPO_NAME="monorepo-idp-example"
GH_TOKEN_SECRET="account.harness-github-pat"
CATALOG_GITHUB_CONNECTOR="account.harnessgithub"
HARNESS_PLATFORM_API_KEY_SECRET="account.harness-api"

DRY_RUN=false
SKIP_REPLACE=false

# ===================== Parse Flags =====================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --patterns-org) PATTERNS_ORG="${2:?}"; shift 2;;
    --template-repo) TEMPLATE_REPO="${2:?}"; shift 2;;
    --sandbox-org) SANDBOX_ORG="${2:?}"; shift 2;;
    --project-id) PROJECT_ID="${2:?}"; shift 2;;
    --org-id) ORG_ID="${2:?}"; shift 2;;
    --account-id) ACCOUNT_ID="${2:?}"; shift 2;;
    --pipeline-name) PIPELINE_NAME="${2:?}"; shift 2;;
    --pipeline-identifier) PIPELINE_IDENTIFIER="${2:?}"; shift 2;;
    --jira-connector) JIRA_CONNECTOR="${2:?}"; shift 2;;
    --jira-project-key) JIRA_PROJECT_KEY="${2:?}"; shift 2;;
    --k8s-connector) K8S_CONNECTOR="${2:?}"; shift 2;;
    --delegate-namespace) DELEGATE_NAMESPACE="${2:?}"; shift 2;;
    --delegate-selector) DELEGATE_SELECTOR="${2:?}"; shift 2;;
    --registry-ref) REGISTRY_REF="${2:?}"; shift 2;;
    --runner-image) RUNNER_IMAGE="${2:?}"; shift 2;;
    --git-connector) GIT_CONNECTOR="${2:?}"; shift 2;;
    --servicenow-connector) SERVICENOW_CONNECTOR="${2:?}"; shift 2;;
    --registry-connector-images) REGISTRY_CONNECTOR_FOR_IMAGES="${2:?}"; shift 2;;
    --cookiecutter-template-url) COOKIECUTTER_TEMPLATE_URL="${2:?}"; shift 2;;
    --github-org) GITHUB_ORG="${2:?}"; shift 2;;
    --monorepo-name) MONOREPO_NAME="${2:?}"; shift 2;;
    --gh-token-secret) GH_TOKEN_SECRET="${2:?}"; shift 2;;
    --catalog-github-connector) CATALOG_GITHUB_CONNECTOR="${2:?}"; shift 2;;
    --harness-platform-api-key-secret) HARNESS_PLATFORM_API_KEY_SECRET="${2:?}"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --skip-replace) SKIP_REPLACE=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

# ===================== Helpers =====================
run() { echo "+ $*"; $DRY_RUN || eval "$@"; }

replace_in_file() {
  local file="$1"; shift
  $DRY_RUN && { echo "  (would replace) $file"; return 0; }
  local tmp="${file}.tmp.$$"
  cp "$file" "$tmp"
  while [[ $# -gt 1 ]]; do
    local from="$1"; local to="$2"; shift 2
    local esc_from esc_to
    esc_from="$(printf '%s' "$from" | sed -e 's/[\/&]/\\&/g')"
    esc_to="$(printf '%s' "$to" | sed -e 's/[\/&]/\\&/g')"
    sed "s/$esc_from/$esc_to/g" "$tmp" > "${tmp}.next" && mv "${tmp}.next" "$tmp"
  done
  mv "$tmp" "$file"
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing $1"; exit 1; }; }
require git

# ===================== Targets =====================
ADMIN_DIR="${CUSTOMER_NAME}-admin"
MONO_DIR="${CUSTOMER_NAME}-monorepo"
[[ -e "$ADMIN_DIR" ]] && { echo "ERROR: $ADMIN_DIR exists"; exit 1; }
[[ -e "$MONO_DIR" ]] && { echo "ERROR: $MONO_DIR exists"; exit 1; }

TEMPLATE_URL="https://github.com/${PATTERNS_ORG}/${TEMPLATE_REPO}.git"

echo "==> Cloning ${TEMPLATE_URL} into ${ADMIN_DIR}"
run git clone --depth 1 "$TEMPLATE_URL" "$ADMIN_DIR"

echo "==> Preparing ${MONO_DIR} from idp-repos/idp-monorepo-example"
if [[ -d "${ADMIN_DIR}/idp-repos/idp-monorepo-example" ]]; then
  run mkdir -p "$MONO_DIR"
  run bash -c "shopt -s dotglob && cp -r '${ADMIN_DIR}/idp-repos/idp-monorepo-example/'* '${MONO_DIR}/'"
else
  echo "WARNING: idp-repos/idp-monorepo-example not found in template."
fi

echo "==> Ensuring cookiecutter is present in admin root for convenience"
if [[ -d "${ADMIN_DIR}/idp-repos/react-app-s3-deploy-cookiecutter" ]]; then
  run cp -R "${ADMIN_DIR}/idp-repos/react-app-s3-deploy-cookiecutter" "${ADMIN_DIR}/react-app-s3-deploy-cookiecutter"
fi

echo "==> Copying bootstrap IaC into admin repo"
run mkdir -p "${ADMIN_DIR}/infra/bootstrap"
if [[ -d "${ADMIN_DIR}/bootstrap/iac-state" ]]; then
  run cp -R "${ADMIN_DIR}/bootstrap/iac-state" "${ADMIN_DIR}/infra/bootstrap/iac-state"
else
  echo "WARNING: bootstrap/iac-state not found in template; skipping backend bootstrap."
fi

# --- Bootstrap remote state backend for this POV (S3+DDB)
if [[ -x "${ADMIN_DIR}/infra/bootstrap/iac-state/apply.sh" ]]; then
  if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "==> Bootstrapping Terraform remote state (S3 + DynamoDB)"
    STATE_KEY_PREFIX="repos/${GITHUB_ORG}/${CUSTOMER_NAME}-monorepo"
    run bash -c "cd '${ADMIN_DIR}/infra/bootstrap/iac-state' \
      && STATE_KEY_PREFIX_OVERRIDE='${STATE_KEY_PREFIX}' ./apply.sh"
  else
    echo "⚠️  Skipping backend bootstrap — AWS credentials not found."
  fi
else
  echo "NOTE: ${ADMIN_DIR}/infra/bootstrap/iac-state/apply.sh not found or not executable; skipping backend bootstrap."
fi

# ===================== Placeholder Replacement =====================
if [[ "$SKIP_REPLACE" == "false" ]]; then
  [[ -n "${ACCOUNT_ID}" ]] || { echo "ERROR: --account-id (or HARNESS_ACCOUNT_ID) is required for replacements"; exit 1; }

  echo "==> Replacing placeholders in admin idp-pipelines/ and idp-forms/"
  PIPE_DIR="${ADMIN_DIR}/idp-pipelines"
  FORM_DIR="${ADMIN_DIR}/idp-forms"

  for f in $(find "$PIPE_DIR" "$FORM_DIR" -type f -name '*.yml' -o -name '*.yaml' 2>/dev/null || true); do
    echo "  -> $f"
    replace_in_file "$f" \
      "__PROJECT_ID__"                    "$PROJECT_ID" \
      "__ORG_ID__"                        "$ORG_ID" \
      "__ACCOUNT_ID__"                    "$ACCOUNT_ID" \
      "__PIPELINE_NAME__"                 "$PIPELINE_NAME" \
      "__PIPELINE_IDENTIFIER__"           "$PIPELINE_IDENTIFIER" \
      "__JIRA_CONNECTOR__"                "$JIRA_CONNECTOR" \
      "__JIRA_PROJECT_KEY__"              "$JIRA_PROJECT_KEY" \
      "__K8S_CONNECTOR__"                 "$K8S_CONNECTOR" \
      "__DELEGATE_NAMESPACE__"            "$DELEGATE_NAMESPACE" \
      "__DELEGATE_SELECTOR__"             "$DELEGATE_SELECTOR" \
      "__REGISTRY_REF__"                  "$REGISTRY_REF" \
      "__RUNNER_IMAGE__"                  "$RUNNER_IMAGE" \
      "__GIT_CONNECTOR__"                 "$GIT_CONNECTOR" \
      "__SERVICENOW_CONNECTOR__"          "$SERVICENOW_CONNECTOR" \
      "__REGISTRY_CONNECTOR_FOR_IMAGES__" "$REGISTRY_CONNECTOR_FOR_IMAGES" \
      "__COOKIECUTTER_TEMPLATE_URL__"     "$COOKIECUTTER_TEMPLATE_URL" \
      "__GITHUB_ORG__"                    "$GITHUB_ORG" \
      "__MONOREPO_NAME__"                 "$MONOREPO_NAME" \
      "__GH_TOKEN_SECRET__"               "$GH_TOKEN_SECRET" \
      "__CATALOG_GITHUB_CONNECTOR__"      "$CATALOG_GITHUB_CONNECTOR" \
      "__HARNESS_PLATFORM_API_KEY_SECRET__" "$HARNESS_PLATFORM_API_KEY_SECRET"
  done
else
  echo "==> Skipping placeholder replacement (per --skip-replace)"
fi

# ===================== Summary =====================
cat <<EOF

Done.

Created:
  - ${ADMIN_DIR}/
  - ${MONO_DIR}/

Template:
  ${PATTERNS_ORG}/${TEMPLATE_REPO}  ->  ${SANDBOX_ORG}/${CUSTOMER_NAME}-*

Replacements: $( [[ "$SKIP_REPLACE" == "false" ]] && echo "APPLIED" || echo "SKIPPED")
  Project:   ${PROJECT_ID}
  Org:       ${ORG_ID}
  Account:   ${ACCOUNT_ID:-<unset>}
  Pipeline:  ${PIPELINE_NAME} (${PIPELINE_IDENTIFIER})
  GitHub Org for defaults: ${GITHUB_ORG}
  Monorepo name default:   ${MONOREPO_NAME}

Next:
  - cd ${ADMIN_DIR} && git init && git add . && git commit -m "seed: ${CUSTOMER_NAME} admin"
  - cd ../${MONO_DIR} && git init && git add . && git commit -m "seed: ${CUSTOMER_NAME} monorepo"
  - Create remotes under ${SANDBOX_ORG} and push both repos.
  - Import pipeline/form YAMLs into Harness (or sync via Git Experience).

Tip:
  Use --dry-run to preview; use --skip-replace to keep placeholders.

EOF
