#!/usr/bin/env bash
set -euo pipefail

# Scaffold a customer folder and copy the selected use case templates.

usage() {
  cat <<'EOF'
Usage:
  reusable-templates/scripts/scaffold-customer-workflow.sh <customer_name_for_the_pov> <workflow_use_case>

Examples:
  reusable-templates/scripts/scaffold-customer-workflow.sh omf e2e-provisioning-react-monorepo

What it does:
  - Creates: idp-workflow-configs/<customer>/
  - Copies:  reusable-templates/<use_case>/* into that folder
  - Leaves placeholders like __ORG_ID__ for you to replace
EOF
}

if [[ $# -lt 2 ]]; then usage; exit 1; fi
CUSTOMER="$1"
USE_CASE="$2"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${ROOT}/reusable-templates/${USE_CASE}"
DEST_DIR="${ROOT}/${CUSTOMER}"
mkdir -p "${DEST_DIR}"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Use case not found: ${SRC_DIR}" >&2
  exit 2
fi

cp -a "${SRC_DIR}/." "${DEST_DIR}/"
echo "✅ Copied ${SRC_DIR} -> ${DEST_DIR}"
echo "Next:"
echo "  - Edit ${DEST_DIR}/{PIPELINE-README.md,WORKFLOW-FORM-README.md} and replace placeholders in the YAMLs."