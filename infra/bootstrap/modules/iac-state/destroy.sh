#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

FORCE="${1:-}"
if [[ "$FORCE" != "--force" ]]; then
  read -r -p "⚠️  This will destroy the backend (bucket & lock table). Type 'destroy' to continue: " ans
  [[ "$ans" == "destroy" ]] || { echo "Aborted."; exit 2; }
fi

pushd "${TF_DIR}" >/dev/null
  terraform destroy -auto-approve
popd >/dev/null
