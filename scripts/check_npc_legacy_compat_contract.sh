#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEGACY_FILE="$ROOT_DIR/src/modules/npc/npc_legacy_compat_inc.nss"

# Keep this list in sync with src/modules/npc/README.md legacy contract section.
ALLOWED_LEGACY_ENTRYPOINTS=(
)

mapfile -t LEGACY_ENTRYPOINTS < <(
  awk '/^[[:space:]]*(void|int|float|string|object)[[:space:]]+NpcBhvr[[:alnum:]_]+[[:space:]]*\(/ { sub(/^[[:space:]]*(void|int|float|string|object)[[:space:]]+/, ""); sub(/[[:space:]]*\(.*/, ""); print; }' "$LEGACY_FILE"
)

if ((${#LEGACY_ENTRYPOINTS[@]} == 0)) && ((${#ALLOWED_LEGACY_ENTRYPOINTS[@]} == 0)); then
  echo "[OK] npc legacy compat contract check passed (no supported legacy entrypoints)"
  exit 0
fi

for fn in "${LEGACY_ENTRYPOINTS[@]}"; do
  bAllowed=0
  for allowed in "${ALLOWED_LEGACY_ENTRYPOINTS[@]}"; do
    if [[ "$fn" == "$allowed" ]]; then
      bAllowed=1
      break
    fi
  done

  if ((bAllowed == 0)); then
    echo "[FAIL] Unexpected legacy entrypoint in $LEGACY_FILE: $fn"
    exit 1
  fi
done

for allowed in "${ALLOWED_LEGACY_ENTRYPOINTS[@]}"; do
  bFound=0
  for fn in "${LEGACY_ENTRYPOINTS[@]}"; do
    if [[ "$fn" == "$allowed" ]]; then
      bFound=1
      break
    fi
  done

  if ((bFound == 0)); then
    echo "[FAIL] Missing expected legacy entrypoint in $LEGACY_FILE: $allowed"
    exit 1
  fi
done

echo "[OK] npc legacy compat contract check passed"
