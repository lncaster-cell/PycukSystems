#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_FILE="$ROOT_DIR/tools/npc_behavior_system/npc_behavior_core.nss"
CTRL_FILE="$ROOT_DIR/src/controllers/lifecycle_controller.nss"

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

assert_has 'const int NPC_AREA_LIFECYCLE_RUNNING = 1;' "$CTRL_FILE"
assert_has 'const int NPC_AREA_LIFECYCLE_PAUSED = 2;' "$CTRL_FILE"
assert_has 'void NpcControllerAreaPause\(object oArea\)' "$CTRL_FILE"
assert_has 'void NpcControllerAreaStop\(object oArea\)' "$CTRL_FILE"

assert_has '#include "controllers/lifecycle_controller"' "$CORE_FILE"
assert_has 'NpcControllerAreaStart\(oArea\);' "$CORE_FILE"
assert_has 'NpcControllerAreaCanProcessTick\(oArea\)' "$CORE_FILE"
assert_has 'void NpcBehaviorAreaPause\(object oArea\)' "$CORE_FILE"
assert_has 'void NpcBehaviorAreaResume\(object oArea\)' "$CORE_FILE"
assert_not_has 'string NPC_VAR_AREA_ACTIVE = "nb_area_active";' "$CORE_FILE"
assert_not_has 'string NPC_VAR_AREA_TIMER_RUNNING = "nb_area_timer_running";' "$CORE_FILE"

echo "[OK] Area lifecycle contract checks passed"
