#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVITY_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
METRICS_FILE="$ROOT_DIR/src/modules/npc/npc_metrics_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] Missing pattern '$pattern' in $file"
    exit 1
  fi
}

# Метрики должны быть объявлены в helper include.
assert_has 'NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL' "$METRICS_FILE"

# При невалидном route должен инкрементиться только общий счётчик.
assert_has 'NpcBhvrMetricInc\(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL\);' "$ACTIVITY_FILE"


echo "[OK] NPC activity invalid-route metric checks passed"
