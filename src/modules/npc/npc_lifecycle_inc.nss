// NPC lifecycle internals (area state + loop orchestration).

// Forward declarations for lifecycle-local/public helpers used before definition.
void NpcBhvrScheduleAreaMaintenance(object oArea, float fDelaySec);
void NpcBhvrOnAreaMaintenance(object oArea);
void NpcBhvrOnAreaMaintenanceImpl(object oArea);
void NpcBhvrBootstrapModuleAreas();
void NpcBhvrQueuePurgeSubject(object oArea, object oSubject);
void NpcBhvrAreaEnsureRegistryCoverageOnActivate(object oArea);

int NpcBhvrAreaGetState(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_AREA_STATE_STOPPED;
    }

    return GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE);
}

int NpcBhvrAreaIsRunning(object oArea)
{
    return NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_RUNNING;
}

void NpcBhvrAreaSetStateInternal(object oArea, int nState)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_AREA_STATE, nState);
}


int NpcBhvrCountPlayersInAreaInternal(object oArea, object oExclude)
{
    object oIter;
    int nPlayers;

    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    oIter = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oIter))
    {
        if (oIter != oExclude && GetIsPC(oIter) && !GetIsDM(oIter))
        {
            nPlayers = nPlayers + 1;
        }
        oIter = GetNextObjectInArea(oArea);
    }

    return nPlayers;
}

int NpcBhvrCountPlayersInAreaInternalApi(object oArea)
{
    return NpcBhvrCountPlayersInAreaInternal(oArea, OBJECT_INVALID);
}

int NpcBhvrCountPlayersInAreaExcludingInternalApi(object oArea, object oExclude)
{
    return NpcBhvrCountPlayersInAreaInternal(oArea, oExclude);
}

int NpcBhvrGetCachedPlayerCountInternal(object oArea)
{
    int nPlayers;

    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    nPlayers = GetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT);
    if (nPlayers < 0)
    {
        nPlayers = 0;
    }

    // Self-heal only: rebuild cache on first use (cold areas/module boot) or when value is suspicious.
    if (!GetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED) || nPlayers > 1024)
    {
        nPlayers = NpcBhvrCountPlayersInAreaInternalApi(oArea);
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);
    }

    return nPlayers;
}

void NpcBhvrAreaActivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrAuthoringApplyAreaFacade(oArea);

    // Единый источник применения runtime-budget (area -> module -> defaults + normalisation):
    // только NpcBhvrApplyTickRuntimeConfig.
    NpcBhvrApplyTickRuntimeConfig(oArea);
    // Activation/resume safety: ensure registry contains currently live NPCs
    // so idle/LOD/runtime paths do not depend on historical queue state.
    NpcBhvrAreaEnsureRegistryCoverageOnActivate(oArea);
    NpcBhvrAreaSetStateInternal(oArea, NPC_BHVR_AREA_STATE_RUNNING);
    NpcBhvrActivityOnAreaActivate(oArea);
    NpcBhvrLodApplyAreaState(oArea, NPC_BHVR_AREA_STATE_RUNNING);
    // Contract: один area-loop на область.
    if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING) != TRUE)
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, TRUE);
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC, ExecuteScript("npc_area_tick", oArea));
    }

    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrAreaEnsureRegistryCoverageOnActivate(object oArea)
{
    object oIter;
    int nRegistryCountBefore;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Keep activate-path deterministic: compact stale entries first and only
    // do a full area scan when registry is empty (cold boot/legacy stop-path).
    NpcBhvrRegistryCompactInvalidEntries(oArea, NPC_BHVR_REGISTRY_COMPACTION_BATCH_CAP_DEFAULT);

    nRegistryCountBefore = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nRegistryCountBefore > 0)
    {
        return;
    }

    oIter = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oIter))
    {
        NpcBhvrRegistryInsert(oArea, oIter);
        oIter = GetNextObjectInArea(oArea);
    }
}

void NpcBhvrAreaPause(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Pause only toggles lifecycle state; queue/pending counters remain untouched.
    NpcBhvrAreaSetStateInternal(oArea, NPC_BHVR_AREA_STATE_PAUSED);
    NpcBhvrLodApplyAreaState(oArea, NPC_BHVR_AREA_STATE_PAUSED);
    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrAreaStop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrAreaSetStateInternal(oArea, NPC_BHVR_AREA_STATE_STOPPED);
    NpcBhvrLodApplyAreaState(oArea, NPC_BHVR_AREA_STATE_STOPPED);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS, FALSE);
    NpcBhvrRegistryResetIdleCursor(oArea);
    NpcBhvrQueueClear(oArea);
}

void NpcBhvrOnAreaTickImpl(object oArea)
{
    int nAreaState;
    int nPendingBefore;
    int nPendingAfter;
    int nMaxEvents;
    int nSoftBudgetMs;
    int nCarryoverEvents;
    int nTickState;
    int nPendingCarryoverState;
    int nProcessedThisTick;
    int nBudgetFlags;
    int nBudgetExceeded;
    int nEventBudgetReached;
    int nSoftBudgetReached;
    int nDegradedStreak;
    int nBudgetExceededTotal;
    int nDegradedTotal;
    int nLastDegradationReason;
    int nNextDegradedStreak;
    int nNextBudgetExceededTotal;
    int nNextDegradedTotal;
    int nTickProcessedPrev;
    int nTickDegradedModePrev;
    int nLastDegradationReasonPrev;
    int nCarryoverEventsPrev;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nAreaState = NpcBhvrAreaGetState(oArea);

    if (nAreaState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS, FALSE);
        return;
    }

    if (nAreaState == NPC_BHVR_AREA_STATE_RUNNING)
    {
        // Tick orchestration split into staged helpers:
        // 1) budgeted queue processing,
        // 2) degradation/carryover policy,
        // 3) deferred trim/reconcile.
        // Это удерживает OnAreaTick тонким и выносит тяжёлую логику в малые функции.
        nPendingBefore = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);

        // Ambient dispatch is first-class and independent from reactive queue processing.
        if (NpcBhvrAreaAllowsAmbientDispatch(oArea))
        {
            NpcBhvrRegistryBroadcastIdleTickBudgeted(oArea, NpcBhvrTickResolveIdleBudget(oArea, nPendingBefore));
        }
        else
        {
            NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_PROCESSED_PER_TICK, 0);
            NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_REMAINING, 0);
        }

        if (NpcBhvrAreaAllowsReactiveDispatch(oArea))
        {
            NpcBhvrTickPrepareBudgets(oArea);
            nMaxEvents = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_MAX_EVENTS);
            nSoftBudgetMs = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS);
            nCarryoverEvents = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS);
            nDegradedStreak = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK);
            nBudgetExceededTotal = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL);
            nDegradedTotal = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL);
            nTickProcessedPrev = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_PROCESSED);
            nTickDegradedModePrev = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_MODE);
            nLastDegradationReasonPrev = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON);
            nCarryoverEventsPrev = nCarryoverEvents;

            // Reactive tick pipeline: ProcessBudgetedWork -> ApplyDegradationAndCarryover -> ReconcileDeferredAndTrim.
            nTickState = NpcBhvrTickProcessBudgetedWork(oArea, nPendingBefore, nMaxEvents, nSoftBudgetMs, nCarryoverEvents);
            nCarryoverEvents = NpcBhvrTickApplyDegradationAndCarryover(oArea, nTickState);
            nPendingCarryoverState = NpcBhvrTickReconcileDeferredAndTrim(oArea, nTickState, nCarryoverEvents);

            nProcessedThisTick = NpcBhvrTickStateProcessed(nTickState);
            nBudgetFlags = NpcBhvrTickStateBudgetFlags(nTickState);
            nPendingAfter = NpcBhvrTickPendingCarryoverPendingAfter(nPendingCarryoverState);
            nCarryoverEvents = NpcBhvrTickPendingCarryoverCarryoverEvents(nPendingCarryoverState);
            if (nCarryoverEvents < 0)
            {
                nCarryoverEvents = 0;
            }
            if (nCarryoverEvents > NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS)
            {
                nCarryoverEvents = NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS;
            }

            nEventBudgetReached = (nBudgetFlags & NPC_BHVR_TICK_FLAG_EVENT_BUDGET_REACHED) != 0;
            nSoftBudgetReached = (nBudgetFlags & NPC_BHVR_TICK_FLAG_SOFT_BUDGET_REACHED) != 0;
            nBudgetExceeded = (nBudgetFlags & NPC_BHVR_TICK_FLAG_BUDGET_EXCEEDED) != 0;

            nNextDegradedStreak = nDegradedStreak;
            nNextBudgetExceededTotal = nBudgetExceededTotal;
            nNextDegradedTotal = nDegradedTotal;
            nLastDegradationReason = NPC_BHVR_DEGRADATION_REASON_NONE;

            if (nBudgetExceeded)
            {
                nNextDegradedStreak = nDegradedStreak + 1;
                nNextBudgetExceededTotal = nBudgetExceededTotal + 1;
                nNextDegradedTotal = nDegradedTotal + 1;

                nLastDegradationReason = NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE;
                if (nEventBudgetReached)
                {
                    nLastDegradationReason = NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET;
                }
                else if (nSoftBudgetReached)
                {
                    nLastDegradationReason = NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET;
                }
            }
            else
            {
                nNextDegradedStreak = 0;
            }

            // Batched tick-state commit: read-normalize-write-if-changed on hot-path locals.
            if (nTickProcessedPrev != nProcessedThisTick)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_PROCESSED, nProcessedThisTick);
            }
            if (nTickDegradedModePrev != nBudgetExceeded)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_DEGRADED_MODE, nBudgetExceeded);
            }
            if (nDegradedStreak != nNextDegradedStreak)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, nNextDegradedStreak);
            }
            if (nBudgetExceededTotal != nNextBudgetExceededTotal)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL, nNextBudgetExceededTotal);
            }
            if (nDegradedTotal != nNextDegradedTotal)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL, nNextDegradedTotal);
            }
            if (nLastDegradationReasonPrev != nLastDegradationReason)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, nLastDegradationReason);
            }
            if (nCarryoverEventsPrev != nCarryoverEvents)
            {
                NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS, nCarryoverEvents);
            }

            // Metrics must stay incremental: process-count is added once per tick snapshot.
            NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_PROCESSED_TOTAL, nProcessedThisTick);
        }
        else
        {
            nPendingAfter = nPendingBefore;
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_PROCESSED, 0);
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_DEGRADED_MODE, FALSE);
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, 0);
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, NPC_BHVR_DEGRADATION_REASON_NONE);
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS, 0);
        }

        NpcBhvrTickHandleBacklogTelemetry(oArea, nPendingAfter);

        NpcBhvrTickFlushWriteBehind();
        NpcBhvrTickHandleIdleStop(oArea, nPendingAfter);
    }

    NpcBhvrTickScheduleNext(oArea);
}

void NpcBhvrScheduleAreaMaintenance(object oArea, float fDelaySec)
{
    if (!GetIsObjectValid(oArea) || fDelaySec <= 0.0)
    {
        return;
    }

    if (GetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING) == TRUE
        || GetLocalInt(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS) == TRUE)
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, TRUE);
    DelayCommand(fDelaySec, ExecuteScript("npc_area_maintenance", oArea));
}

void NpcBhvrOnAreaMaintenanceImpl(object oArea)
{
    int nAreaState;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
    if (GetLocalInt(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS) == TRUE)
    {
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS, TRUE);
    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG, FALSE);

    NpcBhvrQueueReconcileDeferredTotal(oArea, TRUE);
    NpcBhvrRegistryCompactInvalidEntries(oArea, NPC_BHVR_REGISTRY_COMPACTION_BATCH_CAP_DEFAULT);

    NpcBhvrClusterOrchestrateArea(oArea);
    nAreaState = NpcBhvrAreaGetState(oArea);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_MAINT_IN_PROGRESS, FALSE);
    if (nAreaState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        return;
    }

    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrBootstrapModuleAreasImpl()
{
    object oArea;

    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        NpcBhvrAuthoringApplyAreaFacade(oArea);
        NpcBhvrApplyTickRuntimeConfig(oArea);

        if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE) == NPC_BHVR_AREA_STATE_RUNNING)
        {
            NpcBhvrAreaActivate(oArea);
        }
        else if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE) == NPC_BHVR_AREA_STATE_PAUSED)
        {
            NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
        }

        NpcBhvrClusterOrchestrateArea(oArea);
        oArea = GetNextArea();
    }
}


void NpcBhvrOnSpawnImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_SPAWN_COUNT);
    NpcBhvrAuthoringApplyNpcFacade(oNpc);
    NpcBhvrResolveNpcLayer(oNpc);
    NpcBhvrActivityOnSpawn(oNpc);
    NpcBhvrLodApplyForAreaStateToNpc(oNpc, NpcBhvrAreaGetState(GetArea(oNpc)), NpcBhvrPendingNow());

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        NpcBhvrRegistryInsert(oArea, oNpc);
        if (!NpcBhvrAreaIsRunning(oArea))
        {
            NpcBhvrAreaActivate(oArea);
        }
    }
}


void NpcBhvrCleanupNpcFromAreaState(object oArea, object oNpc, int bRemoveRegistry)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    if (bRemoveRegistry)
    {
        NpcBhvrRegistryRemove(oArea, oNpc);
    }

    // Canonical queue/pending cleanup path: purge does indexed fast-path with
    // slow-path fallback when index is stale/missing; area mirror clear is run
    // unconditionally to remove any ghost pending state.
    NpcBhvrQueuePurgeSubject(oArea, oNpc);
    NpcBhvrPendingAreaClear(oArea, oNpc);
}

void NpcBhvrOnPerceptionImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (!NpcBhvrNpcUsesReactivePath(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_PERCEPTION_COUNT);
    oArea = GetArea(oNpc);
    if (!NpcBhvrAreaAllowsReactiveDispatch(oArea))
    {
        return;
    }
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_HIGH, NPC_BHVR_REASON_PERCEPTION);
}

void NpcBhvrOnDamagedImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (!NpcBhvrNpcUsesReactivePath(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DAMAGED_COUNT);
    oArea = GetArea(oNpc);
    if (!NpcBhvrAreaAllowsReactiveDispatch(oArea))
    {
        return;
    }
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_CRITICAL, NPC_BHVR_REASON_DAMAGE);
}

void NpcBhvrOnDeathImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DEATH_COUNT);

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        NpcBhvrCleanupNpcFromAreaState(oArea, oNpc, TRUE);
        NpcBhvrPendingNpcClear(oNpc);
        return;
    }

    // Fallback cleanup for invalid/stale area reference: sweep all areas so
    // death never leaves queue/pending ghosts behind.
    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        NpcBhvrCleanupNpcFromAreaState(oArea, oNpc, TRUE);
        oArea = GetNextArea();
    }

    NpcBhvrPendingNpcClear(oNpc);
}

void NpcBhvrOnDialogueImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DIALOGUE_COUNT);
    oArea = GetArea(oNpc);
    if (NpcBhvrNpcUsesReactivePath(oNpc) && NpcBhvrAreaAllowsReactiveDispatch(oArea))
    {
        NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_NORMAL, NPC_BHVR_REASON_UNSPECIFIED);
    }
}

void NpcBhvrOnAreaEnterImpl(object oArea, object oEntering)
{
    int nPlayers;
    int nEnteringType;
    int nNow;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEntering))
    {
        return;
    }

    NpcBhvrAuthoringApplyAreaFacade(oArea);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_ENTER_COUNT);
    if (!GetIsPC(oEntering))
    {
        nEnteringType = GetObjectType(oEntering);
        if (nEnteringType != OBJECT_TYPE_CREATURE)
        {
            return;
        }

        NpcBhvrRegistryInsert(oArea, oEntering);
        return;
    }

    if (GetIsDM(oEntering))
    {
        return;
    }

    nPlayers = NpcBhvrGetCachedPlayerCountInternal(oArea) + 1;
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    nNow = NpcBhvrPendingNow();
    NpcBhvrClusterOnPlayerAreaEnter(oArea, nNow);
}

void NpcBhvrOnAreaExitImpl(object oArea, object oExiting)
{
    int nPlayers;
    int nExitingType;
    int nNow;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oExiting))
    {
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_EXIT_COUNT);

    if (!GetIsPC(oExiting))
    {
        nExitingType = GetObjectType(oExiting);
        if (nExitingType != OBJECT_TYPE_CREATURE)
        {
            return;
        }

        NpcBhvrCleanupNpcFromAreaState(oArea, oExiting, TRUE);
        NpcBhvrPendingNpcClear(oExiting);
        return;
    }

    if (GetIsDM(oExiting))
    {
        return;
    }

    nPlayers = NpcBhvrGetCachedPlayerCountInternal(oArea) - 1;
    if (nPlayers < 0)
    {
        nPlayers = NpcBhvrCountPlayersInAreaExcludingInternalApi(oArea, oExiting);
        if (nPlayers < 0)
        {
            nPlayers = 0;
        }
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    nNow = NpcBhvrPendingNow();
    if (nPlayers <= 0)
    {
        NpcBhvrClusterOnPlayerAreaExit(oArea, nNow);
    }
    else
    {
        NpcBhvrClusterOnPlayerAreaEnter(oArea, nNow);
    }
}

void NpcBhvrOnModuleLoadImpl()
{
    NpcSqliteInit();
    NpcSqliteHealthcheck();
    NpcBhvrMetricInc(GetModule(), NPC_BHVR_METRIC_MODULE_LOAD_COUNT);
    NpcBhvrBootstrapModuleAreas();
}
