# Post-refactor runtime audit (pass 4) — Daily Life

## Scope and method

- Scope: only `daily_life/` runtime paths (worker, lifecycle ingress, resync, directive pipeline, transition/movement, caches).
- Method: static code-path audit of actual entry points and include-decomposed call chains.
- Goal: detect behavior drift, hot-path overhead, duplicate orchestration, and invariant violations after include decomposition.

## 1) Hot-path map

### Primary hot paths

1. `dl_a_hb.nss -> DL_RunAreaWorkerTick(oArea)`.
2. `DL_RunAreaWorkerTick -> DL_RunAreaEnterResyncTick` (when HOT area + pending area-enter resync).
3. `DL_RunAreaWorkerTick -> DL_RunAreaNpcRoundRobinPass(..., WORKER)`.
4. `DL_WorkerTouchNpc -> DL_ResolveNpcDirective -> DL_ApplyDirectiveSkeleton -> directive-specific execution`.

### Frequent ingress paths (non-heartbeat)

- Spawn: `dl_spawn.nss -> DL_RequestNpcLifecycleSignal(SPAWN) -> dl_userdef.nss -> DL_HandleNpcUserDefined -> Register + RequestResync + ProcessResync`.
- Death: `dl_death.nss -> DL_RequestNpcLifecycleSignal(DEATH) -> dl_userdef.nss -> DL_HandleNpcUserDefined -> DL_CleanupNpcRuntimeState`.
- Blocked: `dl_blocked.nss -> DL_RequestNpcBlockedSignal -> dl_userdef.nss -> DL_HandleNpcBlocked -> delayed reissue`.
- Area enter: `dl_a_enter.nss -> DL_OnAreaEnterBootstrap` sets HOT + area-enter resync pending for player ingress.

## 2) Confirmed safe areas

1. **Budget/cursor semantics are preserved** in worker pass:
   - worker clamps budget >= `DL_WORKER_BUDGET_MIN`, tracks `nNpcSeen`, persists cursor, and round-robin wraps once.
2. **Resync and worker pass separation is explicit** via `DL_AREA_PASS_MODE_RESYNC` / `DL_AREA_PASS_MODE_WORKER`; orchestration is not hidden in include side-effects.
3. **Lifecycle ordering is stable**:
   - spawn: register -> request resync -> process resync.
   - death: cleanup is unconditional for death event even if runtime disabled.
4. **Movement reissue guards exist**:
   - sleep/work/focus transitions check status/phase before issuing `ClearAllActions + Move/Jump`, preventing raw spam every tick.
5. **Cache layer is still present and used**:
   - waypoint and area lookups go through cache helpers; transition exit/driver resolution also caches local objects.
6. **Include decomposition did not introduce include-order runtime side effects**:
   - `dl_core_inc` is composition-only; no top-level mutating code in includes.

## 3) Found risks

### R1 — Double orchestration in one logical heartbeat when area-enter resync is pending

- **Location:** `DL_RunAreaWorkerTick`, `DL_RunAreaEnterResyncTick`, `DL_RunAreaNpcRoundRobinPass`, `DL_ProcessAreaNpcByPassMode`.
- **Type:** hot-path duplicate processing / potential overhead.
- **Why risk:** in HOT area with `DL_L_AREA_ENTER_RESYNC_PENDING=TRUE`, one heartbeat can run:
  1) resync round-robin pass (budget N), then
  2) worker round-robin pass (budget N),
  with independent cursors.
  Same NPC can receive `Resolve + Apply` twice in same heartbeat.
- **Runtime impact:** extra directive resolution and apply work; extra clear/set churn; potential command churn if directive execution path has side effects.
- **Classification:** **potential degradation** (and can become behavior jitter for tight movement/transition states).

### R2 — Blocked reissue path performs redundant clear before skeleton clear

- **Location:** `DL_ReissueNpcDirectiveAfterBlocked` + `DL_ApplyDirectiveSkeleton`.
- **Type:** state-churn duplication.
- **Why risk:** blocked handler clears sleep/work execution state, then immediately calls skeleton which clears the same state family again for those directives.
- **Runtime impact:** minor but frequent local var delete/set churn when blocked events happen repeatedly in door-dense areas.
- **Classification:** **architectural brittleness / minor overhead**, not a correctness bug.

### R3 — SOCIAL partner lookup incurs uncached tag scan on every social execution pass

- **Location:** `DL_ExecuteSocialDirective` (`GetObjectByTag(sPartnerTag)`).
- **Type:** lookup churn in hot path.
- **Why risk:** for NPCs in SOCIAL window, every worker touch does tag-based lookup of partner object (global tag search), regardless of whether partner object is stable.
- **Runtime impact:** avoidable repeated lookup cost in crowded modules.
- **Classification:** **potential degradation**.

### R4 — Directive skeleton always runs full clear/set/execute even when directive unchanged

- **Location:** `DL_WorkerTouchNpc -> DL_ApplyDirectiveSkeleton`.
- **Type:** orchestration churn.
- **Why risk:** no fast-path for "same directive + stable execution state"; each touch re-enters full skeleton branch, includes repeated clear calls for non-target execution states.
- **Runtime impact:** mostly small local var churn; can amplify with R1 when resync+worker both touch same NPC in one heartbeat.
- **Classification:** **can leave as-is for correctness**, but **performance fragility** under load.

## 4) Invariants check (explicit)

### Worker/runtime invariants

- ✅ Area worker is budget-bound, not unbounded.
- ✅ Cursor semantics preserved (including wrap-around).
- ⚠️ "One logical tick should not re-apply same orchestration path to same NPC without reason" is **not strictly preserved** during area-enter resync window (R1).

### Lifecycle invariants

- ✅ Spawn path avoids double register via `DL_RegisterNpc` guard on `DL_L_NPC_REG_ON`.
- ✅ Death cleanup is idempotent enough via unregister guards and local deletes.
- ✅ Blocked path has busy gate + cooldown, avoids recursive flood.

### Directive orchestration invariants

- ✅ Directive is resolved once per pass call.
- ⚠️ Clear/set cycles are intentionally repeated on every pass; functionally safe but heavier than necessary under high frequency.

### Performance invariants

- ✅ Cache usage exists for area anchors and transition resolution.
- ⚠️ Global lookups still remain in hot social partner resolution (R3).
- ⚠️ During area-enter resync, one cheap pass effectively becomes two coupled passes (R1).

## 5) Priorities

### Critical to fix

1. **R1** (double processing during pending area-enter resync) — highest impact on hot-path cost and churn.

### Should fix

1. **R3** (uncached social partner lookup each pass).
2. **R2** (blocked reissue duplicate clear operations).

### Can leave as-is

1. **R4** if load is currently acceptable; keep for behavioral conservatism.

## 6) Minimal safe fixes (no model rewrite)

1. **Mitigate R1 with per-heartbeat dedupe marker (minimal):**
   - Set local marker on NPC during resync pass (`dl_npc_touched_tick = module worker seq/tick`),
   - In same `DL_RunAreaWorkerTick`, skip worker touch if NPC already processed by resync in current heartbeat.
   - This keeps architecture and entry points intact; only avoids duplicate same-tick orchestration.

2. **Mitigate R3 with optional partner-object cache (safe invalidation):**
   - Cache partner object on NPC (`dl_cache_social_partner_obj`), validate by tag + validity + active pipeline before reuse.
   - Fallback to `GetObjectByTag` only on cache miss/stale.

3. **Mitigate R2 by removing one redundant clear in blocked reissue helper:**
   - Call only `DL_ApplyDirectiveSkeleton(oNpc, nDirective)`; let skeleton own canonical clear behavior.
   - No behavior change expected because skeleton already performs required clears.

4. **Keep include facade unchanged** (`dl_core_inc`) to preserve current script entry contracts.

## Conclusion

Post-refactor structure is generally runtime-safe and preserves core Daily Life orchestration model. Main regression vector is not correctness but **same-heartbeat duplicate orchestration during area-enter resync**, amplified by unavoidable per-pass clear/set patterns. Addressing R1 (and then R3) gives highest performance-risk reduction with minimal code delta and no architectural rewrite.
