#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Validate that required Harness NG connectors and secrets exist.

USAGE:
  ./validate-env.sh --account-id ID --api-key KEY
    [--org-id ORG] [--project-id PROJ]
    [--connectors id1,id2,...]
    [--secrets id1,id2,...]
    [--base-url https://app.harness.io]
    [--use-graphql]     # optional fallback probe
    [-h|--help]

NOTES:
- Identifiers may be scoped: account.X | org.X | project.X
- For org/project scoped items, also pass --org-id / --project-id
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && { usage; exit 0; }

ACCOUNT_ID=""
API_KEY=""
ORG_ID=""
PROJECT_ID=""
BASE_URL="https://app.harness.io"
CONNECTORS=""
SECRETS=""
USE_GRAPHQL="no"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account-id) ACCOUNT_ID="${2:?}"; shift 2;;
    --api-key) API_KEY="${2:?}"; shift 2;;
    --org-id) ORG_ID="${2:?}"; shift 2;;
    --project-id) PROJECT_ID="${2:?}"; shift 2;;
    --connectors) CONNECTORS="${2:-}"; shift 2;;
    --secrets) SECRETS="${2:-}"; shift 2;;
    --base-url) BASE_URL="${2:?}"; shift 2;;
    --use-graphql) USE_GRAPHQL="yes"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$ACCOUNT_ID" ]] || { echo "ERROR: --account-id required"; exit 1; }
[[ -n "$API_KEY"    ]] || { echo "ERROR: --api-key required"; exit 1; }

# ---- helpers -------------------------------------------------------------

jq_field() { jq -r "$1" 2>/dev/null || true; }

scope_and_id() {
  # input like "account.harnessgithub" => prints: "account harnessgithub"
  local ref="$1"
  if [[ "$ref" =~ ^(account|org|project)\.(.+)$ ]]; then
    printf "%s %s\n" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  else
    # default to account scope if no prefix
    printf "account %s\n" "$ref"
  fi
}

http_get() {
  # $1: url  -> writes status code to stdout, body to /tmp/resp.json
  local url="$1"
  local code
  code="$(
    curl -sS -w '%{http_code}' -o /tmp/resp.json \
      -H "x-api-key: ${API_KEY}" \
      -H "Harness-Account: ${ACCOUNT_ID}" \
      "${url}"
  )" || code="$?"
  printf "%s" "$code"
}

check_connector_rest() {
  # expects scoped id like account.foo / org.bar / project.baz
  local scoped="$1"
  read -r scope id <<<"$(scope_and_id "$scoped")"

  local q="accountIdentifier=${ACCOUNT_ID}"
  local path="${BASE_URL}/ng/api/connectors/${id}"

  case "$scope" in
    account) ;; # account scope only needs accountIdentifier
    org)
      [[ -n "$ORG_ID" ]] || { echo "MISSING ORG_ID for $scoped"; return 2; }
      q="${q}&orgIdentifier=${ORG_ID}"
      ;;
    project)
      [[ -n "$ORG_ID" && -n "$PROJECT_ID" ]] || { echo "MISSING ORG_ID/PROJECT_ID for $scoped"; return 2; }
      q="${q}&orgIdentifier=${ORG_ID}&projectIdentifier=${PROJECT_ID}"
      ;;
  esac

  local code
  code="$(http_get "${path}?${q}")"
  if [[ "$code" == "200" ]]; then
    local ident
    ident="$(jq_field '.data.connector.identifier' < /tmp/resp.json)"
    [[ -n "$ident" && "$ident" != "null" ]] && { echo "✅ connector exists: $scoped"; return 0; }
  fi
  echo "❌ connector missing or inaccessible: $scoped (HTTP $code)"
  return 1
}

check_secret_rest() {
  local scoped="$1"
  read -r scope id <<<"$(scope_and_id "$scoped")"

  local q="accountIdentifier=${ACCOUNT_ID}"
  local path="${BASE_URL}/ng/api/secretsV2/${id}"

  case "$scope" in
    account) ;;
    org)
      [[ -n "$ORG_ID" ]] || { echo "MISSING ORG_ID for $scoped"; return 2; }
      q="${q}&orgIdentifier=${ORG_ID}"
      ;;
    project)
      [[ -n "$ORG_ID" && -n "$PROJECT_ID" ]] || { echo "MISSING ORG_ID/PROJECT_ID for $scoped"; return 2; }
      q="${q}&orgIdentifier=${ORG_ID}&projectIdentifier=${PROJECT_ID}"
      ;;
  esac

  local code
  code="$(http_get "${path}?${q}")"
  if [[ "$code" == "200" ]]; then
    local ident
    ident="$(jq_field '.data.secret.identifier' < /tmp/resp.json)"
    [[ -n "$ident" && "$ident" != "null" ]] && { echo "✅ secret exists: $scoped"; return 0; }
  fi
  echo "❌ secret missing or inaccessible: $scoped (HTTP $code)"
  return 1
}

check_connector_graphql() {
  # very light probe (optional): searches by identifier text
  local scoped="$1"
  read -r _scope id <<<"$(scope_and_id "$scoped")"
  local url="${BASE_URL}/gateway/api/graphql?accountId=${ACCOUNT_ID}"
  local query='{"query":"query { connectors(limit: 5) { nodes { identifier name } } }"}'
  local code
  code="$(
    curl -sS -w '%{http_code}' -o /tmp/resp.json \
      -H "x-api-key: ${API_KEY}" -H "Content-Type: application/json" \
      -X POST "$url" --data "$query"
  )" || code="$?"
  if [[ "$code" == "200" ]] && grep -q "\"identifier\":\"$id\"" /tmp/resp.json; then
    echo "ℹ︎ GraphQL probe saw connector id '$id' (non-authoritative)."
    return 0
  fi
  echo "ℹ︎ GraphQL probe did not see '$id' (HTTP $code)."
  return 1
}

# ---- run checks ----------------------------------------------------------

require() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1"; exit 1; }; }
require curl
require jq

echo "== Harness NG validation =="
echo "Base URL:   $BASE_URL"
echo "Account ID: $ACCOUNT_ID"
[[ -n "$ORG_ID" ]] && echo "Org ID:     $ORG_ID"
[[ -n "$PROJECT_ID" ]] && echo "Project ID: $PROJECT_ID"
echo

FAIL=0

IFS=',' read -r -a conn_arr <<<"${CONNECTORS}"
if [[ -n "${CONNECTORS}" ]]; then
  echo "-- Connectors --"
  for c in "${conn_arr[@]}"; do
    c="${c//[[:space:]]/}"
    [[ -z "$c" ]] && continue
    if ! check_connector_rest "$c"; then
      FAIL=1
      [[ "$USE_GRAPHQL" == "yes" ]] && check_connector_graphql "$c" || true
    fi
  done
  echo
fi

IFS=',' read -r -a sec_arr <<<"${SECRETS}"
if [[ -n "${SECRETS}" ]]; then
  echo "-- Secrets --"
  for s in "${sec_arr[@]}"; do
    s="${s//[[:space:]]/}"
    [[ -z "$s" ]] && continue
    if ! check_secret_rest "$s"; then
      FAIL=1
    fi
  done
  echo
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "❌ One or more items are missing. Fix before running setup."
  exit 2
fi

echo "✅ All specified connectors and secrets exist."
