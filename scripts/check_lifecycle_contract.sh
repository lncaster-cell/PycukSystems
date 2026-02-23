#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<USAGE
Usage: $0 <core_file> <controller_file> <module_prefix> [contract_file]

Arguments:
  core_file       Path to module core .nss file.
  controller_file Path to lifecycle controller .nss file.
  module_prefix   Namespace/module prefix (used for default contract lookup and logs).
  contract_file   Optional path to a contract profile. Defaults to
                  scripts/contracts/<module_prefix>.contract
USAGE
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage
  exit 1
fi

CORE_FILE="$1"
CTRL_FILE="$2"
MODULE_PREFIX="$3"
CONTRACT_FILE="${4:-$ROOT_DIR/scripts/contracts/${MODULE_PREFIX}.contract}"

if [[ ! -f "$CORE_FILE" ]]; then
  echo "[FAIL] Core file not found: $CORE_FILE"
  exit 1
fi

if [[ ! -f "$CTRL_FILE" ]]; then
  echo "[FAIL] Controller file not found: $CTRL_FILE"
  exit 1
fi

if [[ ! -f "$CONTRACT_FILE" ]]; then
  echo "[FAIL] Contract profile not found: $CONTRACT_FILE"
  exit 1
fi

CONTRACT_NAME="$MODULE_PREFIX lifecycle contract"
HAS_CORE_PATTERNS=()
HAS_CTRL_PATTERNS=()
NOT_CORE_PATTERNS=()
NOT_CTRL_PATTERNS=()

# shellcheck disable=SC1090
source "$CONTRACT_FILE"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] Missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_not_has() {
  local pattern="$1"
  local file="$2"
  if rg -q "$pattern" "$file"; then
    echo "[FAIL] Unexpected pattern '$pattern' in $file"
    exit 1
  fi
}

for pattern in "${HAS_CTRL_PATTERNS[@]}"; do
  assert_has "$pattern" "$CTRL_FILE"
done

for pattern in "${HAS_CORE_PATTERNS[@]}"; do
  assert_has "$pattern" "$CORE_FILE"
done

for pattern in "${NOT_CTRL_PATTERNS[@]}"; do
  assert_not_has "$pattern" "$CTRL_FILE"
done

for pattern in "${NOT_CORE_PATTERNS[@]}"; do
  assert_not_has "$pattern" "$CORE_FILE"
done

echo "[OK] ${CONTRACT_NAME} checks passed"
