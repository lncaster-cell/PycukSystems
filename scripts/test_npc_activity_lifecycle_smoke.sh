#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"

if [[ ! -f "$TARGET" ]]; then
  echo "[FAIL] target file not found: $TARGET"
  exit 1
fi

python3 - "$TARGET" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

errors = []


def body(func_name: str) -> str:
    m = re.search(rf"void\s+{re.escape(func_name)}\s*\([^)]*\)\s*\{{(.*?)\n\}}", text, re.S)
    if not m:
        errors.append(f"missing function body: {func_name}")
        return ""
    return m.group(1)


def expect_contains(haystack: str, needle: str, ctx: str) -> None:
    if needle not in haystack:
        errors.append(f"{ctx}: missing '{needle}'")


def expect_not_contains(haystack: str, needle: str, ctx: str) -> None:
    if needle in haystack:
        errors.append(f"{ctx}: unexpected '{needle}'")


def expect_order(haystack: str, needles: list[str], ctx: str) -> None:
    pos = -1
    for needle in needles:
        idx = haystack.find(needle)
        if idx == -1:
            errors.append(f"{ctx}: missing '{needle}'")
            return
        if idx < pos:
            errors.append(f"{ctx}: order violation for '{needle}'")
            return
        pos = idx


def expect_regex(haystack: str, pattern: str, ctx: str) -> None:
    if not re.search(pattern, haystack, re.S):
        errors.append(f"{ctx}: pattern not matched /{pattern}/")

resolve_body = re.search(r"string\s+NpcBhvrActivityResolveRouteProfile\s*\([^)]*\)\s*\{(.*?)\n\}", text, re.S)
if not resolve_body:
    errors.append("missing function body: NpcBhvrActivityResolveRouteProfile")
    resolve = ""
else:
    resolve = resolve_body.group(1)

spawn = body("NpcBhvrActivityOnSpawn")
idle = body("NpcBhvrActivityOnIdleTick")

# Case 1: Spawn initializes required lifecycle keys through centralized refresh.
expect_contains(spawn, 'NpcBhvrActivityRefreshProfileState(oNpc);', 'spawn init')
expect_contains(spawn, 'sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);', 'spawn init')
expect_contains(spawn, 'sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);', 'spawn init')
expect_contains(spawn, 'NpcBhvrActivityAdapterStampTransition(oNpc, "spawn_ready");', 'spawn init')
expect_contains(spawn, 'SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 0);', 'spawn init')

# Case 2: Idle tick cooldown > 0 path decrements only and returns.
expect_contains(idle, 'if (nCooldown > 0)', 'idle cooldown gate')
expect_contains(idle, 'SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown - 1);', 'idle cooldown gate')
expect_regex(
    idle,
    r'if \(nCooldown > 0\)\s*\{\s*SetLocalInt\(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown - 1\);\s*return;\s*\}',
    'idle cooldown gate',
)

# Case 3: Idle invalidation gate and cached fast-path are present.
expect_contains(idle, 'if (bInvalidate)', 'idle invalidation')
expect_contains(idle, 'NpcBhvrActivityRefreshProfileState(oNpc);', 'idle invalidation')
expect_contains(idle, 'sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);', 'idle cached slot')
expect_contains(idle, 'sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);', 'idle cached route')
expect_order(
    idle,
    [
        'if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_RESOLVED_HOUR) != nResolvedHour)',
        'else if (sSlotCached == "" || sSlotCached != sSlot)',
        'else if (sRouteConfiguredCached != sRouteConfigured)',
        'else if (sAreaCached != sAreaTag)',
    ],
    'idle invalidation conditions',
)

# Case 4: cooldown == 0 dispatch path follows slot/route branch order.
expect_contains(idle, 'nRouteHint = NpcBhvrActivityMapRouteHint(sRoute);', 'idle dispatch')
expect_order(
    idle,
    [
        'if (NpcBhvrActivityAdapterIsCriticalSafe(sSlot, nRouteHint))',
        'NpcBhvrActivityApplyCriticalSafeRoute(oNpc);',
        'if (NpcBhvrActivityAdapterIsPriority(sSlot, nRouteHint))',
        'NpcBhvrActivityApplyPriorityRoute(oNpc);',
        'NpcBhvrActivityApplyDefaultRoute(oNpc);',
    ],
    'idle dispatch',
)

# Case 5: route source transition fallback chain keeps configured route source and defaults.
expect_contains(resolve, 'GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE)', 'resolve fallback chain')
expect_contains(resolve, 'NpcBhvrActivitySlotRouteProfileKey(sSlot)', 'resolve fallback chain')
expect_contains(resolve, 'NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT', 'resolve fallback chain')
expect_contains(resolve, 'NpcBhvrActivityRouteCacheResolveForSlot(oArea, sSlot)', 'resolve fallback chain')
expect_contains(resolve, 'return NpcBhvrActivityAdapterNormalizeRoute("");', 'resolve fallback chain')

if errors:
    print('[FAIL] npc activity lifecycle smoke checks failed')
    for err in errors:
        print(f' - {err}')
    sys.exit(1)

print('[OK] npc activity lifecycle smoke checks passed')
PY
status=$?

if [[ $status -eq 0 ]]; then
  echo "[OK] scripts/test_npc_activity_lifecycle_smoke.sh"
else
  echo "[FAIL] scripts/test_npc_activity_lifecycle_smoke.sh"
fi

exit $status
