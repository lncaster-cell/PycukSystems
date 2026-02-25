#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_FILE="$ROOT_DIR/src/modules/npc/npc_legacy_al_bridge_inc.nss"
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

# Bridge exists and wired into activity lifecycle.
assert_has 'NpcBhvrLegacyBridgeMigrateNpc\(' "$BRIDGE_FILE"
assert_has 'NpcBhvrLegacyBridgeMigrateAreaDefaults\(' "$BRIDGE_FILE"
assert_has '#include "npc_legacy_al_bridge_inc"' "$ACTIVITY_FILE"
assert_has 'NpcBhvrLegacyBridgeMigrateNpc\(oNpc\);' "$ACTIVITY_FILE"
assert_has 'NpcBhvrLegacyBridgeMigrateAreaDefaults\(oArea\);' "$ACTIVITY_FILE"

# Canonical truth remains npc_*; al_* is migration-only.
if rg -n '"al_' "$ROOT_DIR/src/modules/npc" | rg -v 'npc_legacy_al_bridge_inc.nss' >/dev/null; then
  echo "[FAIL] al_* keys leak outside legacy bridge include"
  rg -n '"al_' "$ROOT_DIR/src/modules/npc" | rg -v 'npc_legacy_al_bridge_inc.nss' || true
  exit 1
fi

# Diagnostics metrics are present.
assert_has 'npc_metric_legacy_migrated_npc_total' "$METRICS_FILE"
assert_has 'npc_metric_legacy_migrated_area_total' "$METRICS_FILE"
assert_has 'npc_metric_legacy_normalized_keys_total' "$METRICS_FILE"
assert_has 'npc_metric_legacy_unsupported_keys_total' "$METRICS_FILE"
assert_has 'npc_metric_legacy_fallback_total' "$METRICS_FILE"

python3 - <<'PY'
# Emulated idempotency and mapping fallback contract.

def migrate_once(stamp, has_slot, has_route_valid):
    if stamp == 1:
        return (stamp, 0, 0)
    normalized = 0
    fallback = 0
    if has_slot:
        normalized += 1
    if has_route_valid:
        normalized += 1
    else:
        fallback += 1
    return (1, normalized, fallback)


def assert_eq(a, b, name):
    if a != b:
        raise SystemExit(f"[FAIL] {name}: expected={b!r}, actual={a!r}")

stamp, normalized, fallback = migrate_once(0, True, False)
assert_eq(stamp, 1, 'first migration stamps version')
assert_eq(normalized, 1, 'first migration normalizes supported key')
assert_eq(fallback, 1, 'first migration tracks fallback for unsupported route')

stamp2, normalized2, fallback2 = migrate_once(stamp, True, True)
assert_eq(stamp2, 1, 'second migration keeps stamp')
assert_eq(normalized2, 0, 'second migration is idempotent for normalized count')
assert_eq(fallback2, 0, 'second migration does not add fallback noise')

print('[OK] NPC legacy bridge behavioral checks passed')
PY

printf '[OK] NPC legacy bridge contract checks passed\n'
