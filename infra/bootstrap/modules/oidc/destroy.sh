#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

CONFIRM="${1:-}"
if [[ "$CONFIRM" != "--yes" ]]; then
  read -r -p "⚠️  This will destroy the OIDC role/policies. Type 'destroy' to continue: " ans
  [[ "$ans" == "destroy" ]] || { echo "Aborted."; exit 2; }
fi

pushd "${TF_DIR}" >/dev/null
  terraform destroy -auto-approve
popd >/dev/null
