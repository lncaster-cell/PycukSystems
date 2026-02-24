#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="$ROOT_DIR/src/modules/module_skeleton"
CANONICAL_INCLUDE='^#include "mod_skel_core"$'
LEGACY_INCLUDE='^#include "module_skeleton_core"$'

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

ENTRYPOINT_FILES=(
  "$MODULE_DIR/module_skeleton_module_load.nss"
  "$MODULE_DIR/module_skeleton_area_tick.nss"
  "$MODULE_DIR/module_skeleton_spawn.nss"
)

for file in "${ENTRYPOINT_FILES[@]}"; do
  assert_has "$CANONICAL_INCLUDE" "$file"
  assert_not_has "$LEGACY_INCLUDE" "$file"
done

SHIM_FILE="$MODULE_DIR/module_skeleton_core.nss"
assert_has '^// DEPRECATED: compatibility shim\. Use canonical include "mod_skel_core"\.$' "$SHIM_FILE"
assert_has "$CANONICAL_INCLUDE" "$SHIM_FILE"
assert_not_has "$LEGACY_INCLUDE" "$SHIM_FILE"

echo "[OK] module_skeleton include contract checks passed"
