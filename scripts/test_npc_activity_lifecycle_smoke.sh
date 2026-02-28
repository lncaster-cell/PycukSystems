#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVITY_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"
ROUTE_FILE="$ROOT_DIR/src/modules/npc/npc_activity_route_resolution_inc.nss"

if [[ ! -f "$ACTIVITY_FILE" || ! -f "$ROUTE_FILE" ]]; then
  echo "[FAIL] target file not found"
  exit 1
fi

python3 - "$ACTIVITY_FILE" "$ROUTE_FILE" <<'PY'
import re
import sys
from pathlib import Path

activity = Path(sys.argv[1]).read_text(encoding="utf-8")
route = Path(sys.argv[2]).read_text(encoding="utf-8")
errors = []


def body(text: str, func_name: str) -> str:
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

spawn = body(activity, "NpcBhvrActivityOnSpawn")
idle = body(activity, "NpcBhvrActivityOnIdleTick")
resolve_m = re.search(r"string\s+NpcBhvrActivityResolveRouteProfile\s*\([^)]*\)\s*\{(.*?)\n\}", route, re.S)
resolve = resolve_m.group(1) if resolve_m else ""
if not resolve_m:
    errors.append("missing function body: NpcBhvrActivityResolveRouteProfile")

expect_order(
    spawn,
    [
        'NpcBhvrLegacyBridgeMigrateNpc(oNpc);',
        'NpcBhvrActivityRefreshProfileState(oNpc);',
        'NpcBhvrActivityInitRuntimeState(oNpc);',
        'NpcBhvrActivityAdapterStampTransition(oNpc, "spawn_ready");',
    ],
    'spawn order',
)

expect_contains(idle, 'if (NpcBhvrActivityIsCooldownActive(oNpc, nNow))', 'idle cooldown gate')
expect_contains(idle, 'NpcBhvrActivityRunHeavyRefreshForIdle(oNpc, nResolvedHour, oArea, sAreaTag);', 'idle refresh path')
expect_order(
    idle,
    [
        'sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);',
        'NpcBhvrActivityApplyRouteState(oNpc, sRoute, "idle_route", 1);',
    ],
    'idle canonical dispatch',
)
expect_not_contains(idle, 'NpcBhvrActivityApplyCriticalSafeRoute(oNpc);', 'idle canonical dispatch')
expect_not_contains(idle, 'NpcBhvrActivityApplyPriorityRoute(oNpc);', 'idle canonical dispatch')

expect_contains(resolve, 'NpcBhvrActivitySlotRouteProfileKey(sSlot)', 'resolve fallback chain')
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
