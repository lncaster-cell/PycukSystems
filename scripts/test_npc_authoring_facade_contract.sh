#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FACADE_FILE="$ROOT_DIR/src/modules/npc/npc_authoring_facade_inc.nss"
CORE_FILE="$ROOT_DIR/src/modules/npc/npc_core.nss"
LIFECYCLE_FILE="$ROOT_DIR/src/modules/npc/npc_lifecycle_inc.nss"
AUTHORING_DOC="$ROOT_DIR/docs/npc_toolset_authoring_contract.md"
RUNTIME_DOC="$ROOT_DIR/docs/npc_runtime_internal_contract.md"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "[FAIL] missing file $file"
    exit 1
  fi
}

assert_file "$FACADE_FILE"
assert_file "$AUTHORING_DOC"
assert_file "$RUNTIME_DOC"

# facade layer exists and is wired
assert_has '#include "npc_authoring_facade_inc"' "$CORE_FILE"
assert_has 'NpcBhvrAuthoringApplyNpcFacade\(oNpc\);' "$LIFECYCLE_FILE"
assert_has 'NpcBhvrAuthoringApplyAreaFacade\(oArea\);' "$LIFECYCLE_FILE"

# role/area_profile presets + slot-route canonical authoring
assert_has 'citizen' "$FACADE_FILE"
assert_has 'worker' "$FACADE_FILE"
assert_has 'merchant' "$FACADE_FILE"
assert_has 'guard' "$FACADE_FILE"
assert_has 'innkeeper' "$FACADE_FILE"
assert_has 'static' "$FACADE_FILE"

assert_has 'npc_cfg_slot_dawn_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_morning_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_afternoon_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_evening_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_night_route' "$FACADE_FILE"
assert_has 'npc_cfg_alert_route' "$FACADE_FILE"
assert_has 'NPC_BHVR_VAR_ROUTE_PROFILE_ALERT' "$FACADE_FILE"

# legacy schedule presets remain as compatibility-only migration path
assert_has 'day_worker' "$FACADE_FILE"
assert_has 'day_shop' "$FACADE_FILE"
assert_has 'night_guard' "$FACADE_FILE"
assert_has 'tavern_late' "$FACADE_FILE"
assert_has 'always_home' "$FACADE_FILE"
assert_has 'always_static' "$FACADE_FILE"
assert_has 'custom' "$FACADE_FILE"

assert_has 'city_exterior' "$FACADE_FILE"
assert_has 'shop_interior' "$FACADE_FILE"
assert_has 'house_interior' "$FACADE_FILE"
assert_has 'tavern' "$FACADE_FILE"
assert_has 'guard_post' "$FACADE_FILE"

# authoring locals wired
assert_has 'npc_cfg_role' "$FACADE_FILE"
assert_has 'npc_cfg_slot_dawn_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_morning_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_afternoon_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_evening_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_night_route' "$FACADE_FILE"
assert_has 'npc_cfg_alert_route' "$FACADE_FILE"
assert_has 'npc_cfg_city' "$FACADE_FILE"
assert_has 'npc_cfg_cluster' "$FACADE_FILE"
assert_has 'npc_cfg_area_profile' "$FACADE_FILE"
# docs split and human/runtime separation
assert_has 'Строгие границы канонического пути \(anti-drift\)' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_dawn_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_morning_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_afternoon_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_evening_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_night_route' "$AUTHORING_DOC"
assert_has 'compatibility-only / deprecated / migration-only' "$AUTHORING_DOC"
assert_has '\*\_schedule_\*_start/end' "$AUTHORING_DOC"
assert_has 'не являются primary authoring path' "$ROOT_DIR/src/modules/npc/README.md"
assert_has 'Scope boundary \(strict\)' "$RUNTIME_DOC"
assert_has 'не primary authoring path' "$RUNTIME_DOC"

assert_has 'Human-facing authoring contract' "$AUTHORING_DOC"
assert_has 'Runtime/internal contract reference' "$RUNTIME_DOC"
assert_has 'Three-level local model' "$RUNTIME_DOC"

# runtime contour compatibility anchors still present
assert_has 'NpcBhvrLegacyBridgeMigrateNpc\(' "$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
assert_has 'npc_runtime_layer' "$ROOT_DIR/src/modules/npc/npc_runtime_modes_inc.nss"
assert_has 'npc_dispatch_mode' "$ROOT_DIR/src/modules/npc/npc_runtime_modes_inc.nss"

echo "[OK] NPC authoring facade contract checks passed"
