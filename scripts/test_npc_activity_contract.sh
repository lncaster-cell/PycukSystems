#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVITY_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
METRICS_FILE="$ROOT_DIR/src/modules/npc/npc_metrics_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"

  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_has "NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL" "$METRICS_FILE"
assert_has "int NpcBhvrActivityAdapterWasSlotFallback\(" "$ACTIVITY_FILE"
assert_has "SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_FALLBACK, nSlotFallback\);" "$ACTIVITY_FILE"
assert_has "NpcBhvrMetricInc\(oNpc, NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL\);" "$ACTIVITY_FILE"

# Регресс-кейс: invalid slot не блокирует route fallback;
# route всё равно резолвится по нормализованному slot.
assert_has "sSlot = NpcBhvrActivityAdapterNormalizeSlot\(sSlotRaw\);" "$ACTIVITY_FILE"
assert_has "sRoute = NpcBhvrActivityResolveRouteProfile\(oNpc, sSlot\);" "$ACTIVITY_FILE"

echo "[OK] NPC activity contract tests passed"
