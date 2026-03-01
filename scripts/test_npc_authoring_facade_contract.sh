#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FACADE_FILE="$ROOT_DIR/src/modules/npc/npc_authoring_facade_inc.nss"
CORE_FILE="$ROOT_DIR/src/modules/npc/npc_core.nss"
LIFECYCLE_FILE="$ROOT_DIR/src/modules/npc/npc_lifecycle_inc.nss"
AUTHORING_DOC="$ROOT_DIR/docs/npc_toolset_authoring_contract.md"
RUNTIME_DOC="$ROOT_DIR/docs/npc_runtime_internal_contract.md"

ROLE_PRESETS=(citizen worker merchant guard innkeeper static)
SCHEDULE_PRESETS=(day_worker day_shop night_guard tavern_late always_home always_static custom)
AREA_PRESETS=(city_exterior shop_interior house_interior tavern guard_post)

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

assert_doc_has_preset_bullet() {
  local preset="$1"
  local file="$2"
  local pattern
  printf -v pattern -- '- `%s`' "$preset"
  if ! rg -Fq -- "$pattern" "$file"; then
    echo "[FAIL] missing documented preset '${preset}' in ${file}"
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

# role/schedule/area_profile presets exist in resolver
for preset in "${ROLE_PRESETS[@]}"; do
  assert_has "$preset" "$FACADE_FILE"
  assert_doc_has_preset_bullet "$preset" "$AUTHORING_DOC"
done
for preset in "${SCHEDULE_PRESETS[@]}"; do
  assert_has "$preset" "$FACADE_FILE"
  assert_doc_has_preset_bullet "$preset" "$AUTHORING_DOC"
done
for preset in "${AREA_PRESETS[@]}"; do
  assert_has "$preset" "$FACADE_FILE"
done

# resolver must actually combine role + schedule + routes
assert_has 'NpcBhvrAuthoringResolveRoleDefaultSchedule\(' "$FACADE_FILE"
assert_has 'NpcBhvrAuthoringResolveSchedulePreset\(' "$FACADE_FILE"
assert_has 'NpcBhvrAuthoringResolveFirstNonEmptyRoute\(' "$FACADE_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_CFG_DERIVED_ROLE, sRole\);' "$FACADE_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_CFG_DERIVED_SCHEDULE, sSchedule\);' "$FACADE_FILE"

# authoring locals wired
assert_has 'npc_cfg_role' "$FACADE_FILE"
assert_has 'npc_cfg_identity_type' "$FACADE_FILE"
assert_has 'npc_cfg_slot_dawn_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_morning_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_afternoon_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_evening_route' "$FACADE_FILE"
assert_has 'npc_cfg_slot_night_route' "$FACADE_FILE"
assert_has 'npc_cfg_alert_route' "$FACADE_FILE"
assert_has 'npc_cfg_city' "$FACADE_FILE"
assert_has 'npc_cfg_cluster' "$FACADE_FILE"
assert_has 'npc_cfg_area_profile' "$FACADE_FILE"
assert_has 'npc_cfg_derived_identity_type' "$FACADE_FILE"
assert_has 'NpcBhvrAuthoringResolveIdentityType\(' "$FACADE_FILE"
assert_has 'NpcBhvrAuthoringIsFutureRespawnCandidate\(' "$FACADE_FILE"
# docs split and human/runtime separation
assert_has 'Строгие границы канонического пути \(anti-drift\)' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_dawn_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_morning_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_afternoon_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_evening_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_slot_night_route' "$AUTHORING_DOC"
assert_has 'npc_cfg_identity_type' "$AUTHORING_DOC"
assert_has 'compatibility-only / deprecated / migration-only' "$AUTHORING_DOC"
assert_has '\*\_schedule_\*_start/end' "$AUTHORING_DOC"
assert_has 'не являются primary authoring path' "$ROOT_DIR/src/modules/npc/README.md"
assert_has 'Scope boundary \(strict\)' "$RUNTIME_DOC"
assert_has 'не primary authoring path' "$RUNTIME_DOC"
assert_has 'npc_cfg_derived_identity_type' "$RUNTIME_DOC"

assert_has 'Human-facing authoring contract' "$AUTHORING_DOC"
assert_has 'Runtime/internal contract reference' "$RUNTIME_DOC"
assert_has 'Three-level local model' "$RUNTIME_DOC"
assert_has 'Каноническая slot-модель' "$AUTHORING_DOC"
assert_has 'Role semantics' "$AUTHORING_DOC"
assert_has 'Schedule semantics' "$AUTHORING_DOC"

# runtime contour compatibility anchors still present
assert_has 'NpcBhvrLegacyBridgeMigrateNpc\(' "$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
assert_has 'npc_runtime_layer' "$ROOT_DIR/src/modules/npc/npc_runtime_modes_inc.nss"
assert_has 'npc_dispatch_mode' "$ROOT_DIR/src/modules/npc/npc_runtime_modes_inc.nss"

echo "[OK] NPC authoring facade contract checks passed"
