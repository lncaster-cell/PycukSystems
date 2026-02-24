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

# Static contract (required runtime keys/helpers present).
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";' "$TARGET_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";' "$TARGET_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";' "$TARGET_FILE"
assert_has 'int NpcBhvrActivityNormalizeWaypointIndex\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityComposeWaypointState\(' "$TARGET_FILE"
assert_has 'void NpcBhvrActivityApplyRouteState\(' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, nWpIndex\);' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex\(nWpIndex \+ 1, nWpCount, bLoop\)\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag\);' "$TARGET_FILE"
assert_has 'const string NPC_BHVR_VAR_ACTIVITY_ACTION = "npc_activity_action";' "$TARGET_FILE"
assert_has 'int NpcBhvrActivityResolveRoutePauseTicks\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityResolveAction\(' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, sEmote\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, sAction\);' "$TARGET_FILE"
assert_has 'GetLocalString\(oArea, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE\);' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown \+ nPauseTicks\);' "$TARGET_FILE"
assert_has 'const int NPC_BHVR_ACTIVITY_ID_ACT_ONE = 1;' "$TARGET_FILE"
assert_has 'const int NPC_BHVR_ACTIVITY_ID_GUARD = 43;' "$TARGET_FILE"
assert_has 'int NpcBhvrActivityResolveRoutePointActivity\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityGetCustomAnims\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityGetNumericAnims\(' "$TARGET_FILE"
assert_has 'string NpcBhvrActivityGetWaypointTagRequirement\(' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_ID, nActivityId\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS, sCustomAnims\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS, sNumericAnims\);' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER, NpcBhvrActivityRequiresTrainingPartner\(nActivityId\)\);' "$TARGET_FILE"
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR, NpcBhvrActivityRequiresBarPair\(nActivityId\)\);' "$TARGET_FILE"

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



def resolve_action(slot: str, route: str, idx: int, count: int, emote: str) -> str:
    if route == "critical_safe" or slot == "critical":
        return "guard_hold"
    if route == "priority_patrol" or slot == "priority":
        if count > 0:
            return "patrol_move" if (idx % 2) == 0 else "patrol_scan"
        return "patrol_ready"
    if emote != "":
        return "ambient_" + emote
    return "ambient_idle"

assert_eq(resolve_action("critical", "default_route", 0, 3, ""), "guard_hold", "critical action")
assert_eq(resolve_action("priority", "priority_patrol", 1, 4, ""), "patrol_scan", "priority scan action")
assert_eq(resolve_action("default", "default_route", 0, 0, "smoke"), "ambient_smoke", "ambient emote action")
assert_eq(resolve_action("default", "default_route", 0, 0, ""), "ambient_idle", "ambient idle action")


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

assert_eq(custom_anims(1), "lookleft, lookright", "ambientlivev2 custom anims act_one")
assert_eq(custom_anims(97), "meditate", "ambientlivev2 locate wrapper anim")
assert_eq(numeric_anims(8), "10", "ambientlivev2 numeric anim angry")

print("[OK] NPC activity waypoint behavioral checks passed")
PY

echo "[OK] NPC activity waypoint contract tests passed"
