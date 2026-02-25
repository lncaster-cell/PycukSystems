# Ambient Life V3 Rollout Readiness Report

Scanned files: **46**

## Readiness tiers
- **READY**: 42
- **BRIDGEABLE**: 1
- **FALLBACK-RISK**: 0
- **MANUAL**: 3
- **CONFLICTED**: 0

## Legacy bridge coverage
- Supported `al_*` usages: 15
- Ambiguous `al_*` usages: 0
- Unsupported `al_*` usages: 0

## Hook wiring vs canonical contract
- Canonical contract exists: **True** (`docs/npc_toolset_authoring_contract.md`)
- Canonical hooks present: **10/10**
- Hook drift count: **0**

## Top files requiring attention
- `src/modules/module_skeleton/module_skeleton_area_tick.nss` → **MANUAL** (noncanonical hook-like script naming or wiring)
- `src/modules/module_skeleton/module_skeleton_module_load.nss` → **MANUAL** (noncanonical hook-like script naming or wiring)
- `src/modules/module_skeleton/module_skeleton_spawn.nss` → **MANUAL** (noncanonical hook-like script naming or wiring)

## Controlled fallback expectations
- Files with fallback risk: 0

