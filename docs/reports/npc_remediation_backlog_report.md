# Ambient Life V3 Manual Remediation Backlog

- Total unresolved cases: **3**
- Open cases: **0**
- Exception-tracked cases: **3**

## By category
- **HOOK-WIRING**: 3

## By priority
- **P1**: 3
- **P2**: 0
- **P3**: 0

## Cases
- `src/modules/module_skeleton/module_skeleton_area_tick.nss` → **HOOK-WIRING** / **P1** / EXCEPTION (tier=MANUAL; noncanonical hook-like script naming or wiring; exception=EXC-HOOK-WIRING-MODULE-SKELETON-TEMPLATES)
- `src/modules/module_skeleton/module_skeleton_module_load.nss` → **HOOK-WIRING** / **P1** / EXCEPTION (tier=MANUAL; noncanonical hook-like script naming or wiring; exception=EXC-HOOK-WIRING-MODULE-SKELETON-TEMPLATES)
- `src/modules/module_skeleton/module_skeleton_spawn.nss` → **HOOK-WIRING** / **P1** / EXCEPTION (tier=MANUAL; noncanonical hook-like script naming or wiring; exception=EXC-HOOK-WIRING-MODULE-SKELETON-TEMPLATES)

## Recommended actions
- **HOOK-WIRING**: Align hook script naming/wiring to canonical npc_* contract and verify include/entrypoint mapping.
- **LEGACY-UNSUPPORTED**: Rewrite unsupported al_* keys to canonical npc_* keys; bridge extension only with approved case + tests.
- **AMBIGUOUS-ROUTE**: Resolve route/tag naming ambiguity manually and set explicit canonical npc_route_* mapping.
- **RUNTIME-PROTECTED**: Review protected runtime/content boundary; if content-owned, migrate manually; if runtime-owned, track as governed exception.
- **CONFLICTED-CONFIG**: Split conflicting old/new patterns and converge on canonical contract before rollout.
- **DOC/CONTRACT-DRIFT**: Fix drift between content wiring and docs/npc_toolset_authoring_contract.md, then rerun readiness audit.

