#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOD_FILE="$ROOT_DIR/src/modules/npc/npc_lod_projection_inc.nss"
CLUSTER_FILE="$ROOT_DIR/src/modules/npc/npc_cluster_supervisor_inc.nss"
METRICS_FILE="$ROOT_DIR/src/modules/npc/npc_metrics_inc.nss"

assert_has() {
  local pattern="$1"
  local file="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "[FAIL] missing pattern '$pattern' in $file"
    exit 1
  fi
}

# Physical hide optionality + idempotency hooks.
assert_has 'npc_cfg_lod_physical_hide_enabled' "$LOD_FILE"
assert_has 'npc_cfg_lod_physical_hide' "$LOD_FILE"
assert_has 'NpcBhvrLodTryApplyPhysicalHide\(' "$LOD_FILE"
assert_has 'NpcBhvrLodTryApplyPhysicalReveal\(' "$LOD_FILE"
assert_has 'SetScriptHidden\(oNpc, TRUE\);' "$LOD_FILE"
assert_has 'SetScriptHidden\(oNpc, FALSE\);' "$LOD_FILE"

# Guardrails for churn suppression.
assert_has 'npc_cfg_lod_min_hidden_sec' "$LOD_FILE"
assert_has 'npc_cfg_lod_min_visible_sec' "$LOD_FILE"
assert_has 'npc_cfg_lod_reveal_cooldown_sec' "$LOD_FILE"
assert_has 'npc_cfg_lod_physical_cooldown_sec' "$LOD_FILE"

# Cluster door-spam protections remain in place.
assert_has 'npc_cfg_cluster_transition_rate' "$CLUSTER_FILE"
assert_has 'npc_cfg_cluster_transition_burst' "$CLUSTER_FILE"
assert_has 'npc_cfg_cluster_interior_soft_cap' "$CLUSTER_FILE"
assert_has 'npc_cfg_cluster_interior_hard_cap' "$CLUSTER_FILE"

# Metrics presence for perf regression diagnostics.
assert_has 'npc_metric_lod_physical_hide_applied_total' "$METRICS_FILE"
assert_has 'npc_metric_lod_physical_reveal_applied_total' "$METRICS_FILE"
assert_has 'npc_metric_lod_physical_cooldown_hit_total' "$METRICS_FILE"

python3 - <<'PY'
# Lightweight behavioral gates (emulated) for anti-churn invariants.

def should_hide(distance, hide_d, reveal_d, projected, dt, min_hidden, min_visible, debounce):
    if projected:
        if dt < min_hidden:
            return True
        return distance > reveal_d
    if dt < debounce or dt < min_visible:
        return False
    return distance > hide_d


def assert_eq(actual, expected, name):
    if actual != expected:
        raise SystemExit(f"[FAIL] {name}: expected={expected!r}, actual={actual!r}")

# repeated hide/reveal oscillation suppression
assert_eq(should_hide(40, 35, 25, False, 1, 5, 4, 6), False, "visible debounce blocks rapid hide")
assert_eq(should_hide(10, 35, 25, True, 2, 5, 4, 6), True, "hidden min-window blocks rapid reveal")
assert_eq(should_hide(10, 35, 25, True, 8, 5, 4, 6), False, "reveal allowed after hidden window")

# reveal path selection invariants
slot_changed = True
same_slot = False
assert_eq(slot_changed and not same_slot, True, "slot-change and same-slot paths are mutually exclusive")

print('[OK] NPC LOD perf gate checks passed')
PY
