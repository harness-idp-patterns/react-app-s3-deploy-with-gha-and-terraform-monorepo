#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT}/terraform"

pushd "${TF_DIR}" >/dev/null
  terraform destroy -auto-approve
popd >/dev/null
