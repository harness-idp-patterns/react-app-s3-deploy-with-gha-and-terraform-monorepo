#!/usr/bin/env bash
set -euo pipefail

# copy-to-customer-repo.sh
# Copy this pattern into a customer admin repo and optionally push a branch.
# Requirements: bash, git; optional: gh (GitHub CLI)

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/copy-to-customer-repo.sh <target-dir>

Examples:
  ./scripts/copy-to-customer-repo.sh ../acme-admin-repo

Notes:
- This copies the following folders:
    idp-admin/idp-pipelines/
    idp-admin/idp-forms/
    idp-repos/react-app-s3-deploy-cookiecutter/
    idp-repos/idp-monorepo-example/
- After copying, update placeholders in YAML files (search for __LIKE_THIS__).
USAGE
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "" ]] && { usage; exit 0; }

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$1"

mkdir -p "$DEST"

copy_dir() {
  local rel="$1"
  echo "Copying $rel ..."
  rsync -a --delete --exclude '.DS_Store' --exclude '.git' "$SRC_ROOT/$rel" "$DEST/$rel"
}

copy_dir "idp-admin/idp-pipelines"
copy_dir "idp-admin/idp-forms"
copy_dir "idp-repos/react-app-s3-deploy-cookiecutter"
copy_dir "idp-repos/idp-monorepo-example"

echo "✅ Copy complete -> $DEST"
echo "Next steps:"
echo "  1) Replace placeholders in: $DEST/idp-admin/idp-pipelines/pipeline.yml"
echo "  2) Replace placeholders in: $DEST/idp-admin/idp-forms/workflow.yml"
echo "  3) Commit and push your changes."
