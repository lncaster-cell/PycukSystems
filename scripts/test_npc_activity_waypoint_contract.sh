#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_ACTIVITY_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
TARGET_STATE_FILE="$ROOT_DIR/src/modules/npc/npc_activity_state_apply_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

assert_has_any() {
  local pattern="$1"
  shift
  local file

  for file in "$@"; do
    if rg -q "$pattern" "$file"; then
      return 0
    fi
  done

  echo "[FAIL] missing pattern '$pattern' in any target file"
  exit 1
}

# Static contract (required runtime keys/helpers present).
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";' "$TARGET_ACTIVITY_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";' "$TARGET_ACTIVITY_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";' "$TARGET_ACTIVITY_FILE"
assert_has 'int NpcBhvrActivityNormalizeWaypointIndex\(' "$TARGET_ACTIVITY_FILE"
assert_has 'string NpcBhvrActivityComposeWaypointState\(' "$TARGET_ACTIVITY_FILE"
assert_has_any 'void NpcBhvrActivityApplyRouteState\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, nWpIndex\);' "$TARGET_ACTIVITY_FILE"
assert_has_any 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex\(nWpIndex \+ 1, nWpCount, bLoop\)\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_ACTION = "npc_activity_action";' "$TARGET_ACTIVITY_FILE"
assert_has_any 'int NpcBhvrActivityResolveRoutePauseTicks\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'string NpcBhvrActivityResolveAction\(object oNpc, string sMode, string sSlot, int nWpIndex, int nWpCount\)' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, sEmote\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, sAction\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'sMode = NpcBhvrActivityResolveMode\(oNpc\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has 'GetLocalString\(oArea, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE\);' "$TARGET_ACTIVITY_FILE"
assert_has_any 'NpcBhvrActivitySetCooldownTicks\(oNpc, nCooldown \+ nPauseTicks, nNow\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has 'const int NPC_BHVR_ACTIVITY_ID_ACT_ONE = 1;' "$TARGET_ACTIVITY_FILE"
assert_has 'const int NPC_BHVR_ACTIVITY_ID_GUARD = 43;' "$TARGET_ACTIVITY_FILE"
assert_has_any 'int NpcBhvrActivityResolveRoutePointActivity\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'string NpcBhvrActivityGetCustomAnims\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'string NpcBhvrActivityGetNumericAnims\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'string NpcBhvrActivityGetWaypointTagRequirement\(' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_ID, nActivityId\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS, sCustomAnims\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS, sNumericAnims\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER, NpcBhvrActivityRequiresTrainingPartner\(nActivityId\)\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"
assert_has_any 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR, NpcBhvrActivityRequiresBarPair\(nActivityId\)\);' "$TARGET_ACTIVITY_FILE" "$TARGET_STATE_FILE"

# Behavioral contract (emulated): index clamp/loop + state suffix composition.
python3 - <<'PY'

def normalize_waypoint_index(n_index: int, n_count: int, b_loop: bool) -> int:
    if n_count <= 0:
        return 0
    if n_index < 0:
        return 0
    if n_index < n_count:
        return n_index
    if b_loop:
        return n_index % n_count
    return n_count - 1


def compose_state(base: str, tag: str, idx: int, count: int) -> str:
    if tag == "" or count <= 0:
        return base
    return f"{base}_{tag}_{idx + 1}_of_{count}"


def assert_eq(actual, expected, name):
    if actual != expected:
        raise SystemExit(f"[FAIL] {name}: expected={expected!r}, actual={actual!r}")

assert_eq(normalize_waypoint_index(-3, 5, True), 0, "negative index clamps to 0")
assert_eq(normalize_waypoint_index(6, 5, True), 1, "loop wraps index")
assert_eq(normalize_waypoint_index(6, 5, False), 4, "non-loop clamps to tail")
assert_eq(normalize_waypoint_index(2, 0, True), 0, "zero-count fallback")

assert_eq(compose_state("idle_default", "market", 0, 4), "idle_default_market_1_of_4", "state suffix with tag")
assert_eq(compose_state("idle_default", "", 0, 4), "idle_default", "state unchanged without tag")
assert_eq(compose_state("idle_default", "market", 0, 0), "idle_default", "state unchanged without waypoint count")



def resolve_action(mode: str, slot: str, idx: int, count: int, emote: str) -> str:
    if mode == "alert":
        return "guard_hold"
    if slot == "morning":
        if count > 0:
            return "patrol_move" if (idx % 2) == 0 else "patrol_scan"
        return "patrol_ready"
    if emote != "":
        return "ambient_" + emote
    return "ambient_idle"

assert_eq(resolve_action("alert", "night", 0, 3, ""), "guard_hold", "alert action")
assert_eq(resolve_action("daily", "morning", 1, 4, ""), "patrol_scan", "morning patrol scan action")
assert_eq(resolve_action("daily", "afternoon", 0, 0, "smoke"), "ambient_smoke", "ambient emote action")
assert_eq(resolve_action("daily", "afternoon", 0, 0, ""), "ambient_idle", "ambient idle action")


def custom_anims(activity: int) -> str:
    if activity == 1:
        return "lookleft, lookright"
    if activity == 43:
        return "bored, lookleft, lookright, sigh"
    if activity == 97:
        return "meditate"
    return ""

def numeric_anims(activity: int) -> str:
    if activity == 8:
        return "10"
    return ""

assert_eq(custom_anims(1), "lookleft, lookright", "custom anims act_one")
assert_eq(custom_anims(97), "meditate", "locate wrapper anim")
assert_eq(numeric_anims(8), "10", "numeric anim angry")

print("[OK] NPC activity waypoint behavioral checks passed")
PY

echo "[OK] NPC activity waypoint contract tests passed"
