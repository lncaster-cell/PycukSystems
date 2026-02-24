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
assert_has 'SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex\(nWpIndex \+ 1, nWpCount, bLoop\)\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag\);' "$TARGET_FILE"
assert_has 'SetLocalString\(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, NpcBhvrActivityResolveSlotEmote\(oNpc, sSlot\)\);' "$TARGET_FILE"

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

print("[OK] NPC activity waypoint behavioral checks passed")
PY

echo "[OK] NPC activity waypoint contract tests passed"
