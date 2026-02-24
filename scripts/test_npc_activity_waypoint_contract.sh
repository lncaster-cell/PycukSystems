#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";' "$TARGET_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";' "$TARGET_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";' "$TARGET_FILE"
assert_has 'int NpcBhvrActivityNormalizeWaypointIndex\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityComposeWaypointState\(' "$TARGET_FILE"
assert_has 'void NpcBhvrActivityApplyRouteState\(' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex\(nWpIndex \+ 1, nWpCount, bLoop\)\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, NpcBhvrActivityResolveSlotEmote\(oNpc, sSlot\)\);' "$TARGET_FILE"

echo "[OK] NPC activity waypoint contract tests passed"
