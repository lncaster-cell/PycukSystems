#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_FILE="$ROOT_DIR/src/modules/npc/npc_core.nss"
LIFECYCLE_FILE="$ROOT_DIR/src/modules/npc/npc_lifecycle_inc.nss"
RUNTIME_MODES_FILE="$ROOT_DIR/src/modules/npc/npc_runtime_modes_inc.nss"
CLUSTER_FILE="$ROOT_DIR/src/modules/npc/npc_cluster_supervisor_inc.nss"
LOD_FILE="$ROOT_DIR/src/modules/npc/npc_lod_projection_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

# runtime split
assert_has 'NPC_BHVR_LAYER_AMBIENT' "$RUNTIME_MODES_FILE"
assert_has 'NPC_BHVR_LAYER_REACTIVE' "$RUNTIME_MODES_FILE"
assert_has 'NpcBhvrAreaAllowsAmbientDispatch\(' "$RUNTIME_MODES_FILE"
assert_has 'NpcBhvrAreaAllowsReactiveDispatch\(' "$RUNTIME_MODES_FILE"

# cluster supervisor
assert_has 'NpcBhvrClusterOrchestrateArea\(' "$CLUSTER_FILE"
assert_has 'npc_cfg_cluster_transition_rate' "$CLUSTER_FILE"
assert_has 'npc_cfg_cluster_interior_soft_cap' "$CLUSTER_FILE"
assert_has 'npc_cluster_grace_until_at' "$CLUSTER_FILE"

# LOD/projection hooks
assert_has 'NpcBhvrLodApplyAreaState\(' "$LOD_FILE"
assert_has 'NpcBhvrLodShouldSkipIdleTick\(' "$LOD_FILE"
assert_has 'NpcBhvrLodRevealResync\(' "$LOD_FILE"
assert_has 'npc_lod_projected_slot' "$LOD_FILE"
assert_has 'npc_cfg_lod_reveal_cooldown_sec' "$LOD_FILE"

# integration points in core/lifecycle
assert_has '#include "npc_runtime_modes_inc"' "$CORE_FILE"
assert_has '#include "npc_cluster_supervisor_inc"' "$CORE_FILE"
assert_has '#include "npc_lod_projection_inc"' "$CORE_FILE"
assert_has 'NpcBhvrClusterOrchestrateArea\(oArea\);' "$LIFECYCLE_FILE"
assert_has 'NpcBhvrLodApplyAreaState\(oArea, NPC_BHVR_AREA_STATE_PAUSED\);' "$LIFECYCLE_FILE"
assert_has 'NpcBhvrLodApplyAreaState\(oArea, NPC_BHVR_AREA_STATE_STOPPED\);' "$LIFECYCLE_FILE"

printf '[OK] NPC runtime contour contract checks passed\n'
