// NPC lifecycle internals (area state + loop orchestration).

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

void NpcBhvrAreaSetState(object oArea, int nState)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE, nState);
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

int NpcBhvrCountPlayersInArea(object oArea)
{
    return NpcBhvrCountPlayersInAreaInternal(oArea, OBJECT_INVALID);
}

int NpcBhvrCountPlayersInAreaExcluding(object oArea, object oExclude)
{
    return NpcBhvrCountPlayersInAreaInternal(oArea, oExclude);
}

int NpcBhvrGetCachedPlayerCount(object oArea)
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
        nPlayers = NpcBhvrCountPlayersInArea(oArea);
        SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
        SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);
    }

    return nPlayers;
}

void NpcBhvrAreaActivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Единый источник применения runtime-budget (area -> module -> defaults + normalisation):
    // только NpcBhvrApplyTickRuntimeConfig.
    NpcBhvrApplyTickRuntimeConfig(oArea);
    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_RUNNING);
    NpcBhvrAreaRouteCacheWarmup(oArea);
    NpcBhvrActivityOnAreaActivate(oArea);
    // Contract: один area-loop на область.
    if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING) != TRUE)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, TRUE);
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC, ExecuteScript("npc_area_tick", oArea));
    }

    NpcBhvrOnAreaMaintenance(oArea);
    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrAreaPause(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Pause only toggles lifecycle state; queue/pending counters remain untouched.
    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_PAUSED);
    NpcBhvrOnAreaMaintenance(oArea);
    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrAreaStop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrOnAreaMaintenance(oArea);
    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_STOPPED);
    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
    NpcBhvrAreaRouteCacheInvalidate(oArea);
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
        SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
        SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
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
        if (nPendingBefore <= 0)
        {
            // Idle broadcast runs only when queue is empty: keeps ambient NPC activity alive
            // without competing with queued event processing budget.
            NpcBhvrRegistryBroadcastIdleTickBudgeted(oArea, NPC_BHVR_IDLE_MAX_NPC_PER_TICK_DEFAULT);
        }

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

        // Tick pipeline: ProcessBudgetedWork -> ApplyDegradationAndCarryover -> ReconcileDeferredAndTrim.
        nTickState = NpcBhvrTickProcessBudgetedWork(oArea, nPendingBefore, nMaxEvents, nSoftBudgetMs, nCarryoverEvents);
        nCarryoverEvents = NpcBhvrTickApplyDegradationAndCarryover(oArea, nTickState);
        nPendingCarryoverState = NpcBhvrTickReconcileDeferredAndTrim(oArea, nTickState, nCarryoverEvents);

        nProcessedThisTick = NpcBhvrTickStateProcessed(nTickState);
        nBudgetFlags = NpcBhvrTickStateBudgetFlags(nTickState);
        nPendingAfter = NpcBhvrTickPendingCarryoverPendingAfter(nPendingCarryoverState);
        nCarryoverEvents = NpcBhvrTickPendingCarryoverCarryoverEvents(nPendingCarryoverState);

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

        // Batched tick-state commit: write only locals whose values actually changed.
        if (nTickProcessedPrev != nProcessedThisTick)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_PROCESSED, nProcessedThisTick);
        }
        if (nTickDegradedModePrev != nBudgetExceeded)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_MODE, nBudgetExceeded);
        }
        if (nDegradedStreak != nNextDegradedStreak)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, nNextDegradedStreak);
        }
        if (nBudgetExceededTotal != nNextBudgetExceededTotal)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL, nNextBudgetExceededTotal);
        }
        if (nDegradedTotal != nNextDegradedTotal)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL, nNextDegradedTotal);
        }
        if (nLastDegradationReasonPrev != nLastDegradationReason)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, nLastDegradationReason);
        }
        if (nCarryoverEventsPrev != nCarryoverEvents)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS, nCarryoverEvents);
        }

        // Metrics must stay incremental: process-count is added once per tick snapshot.
        NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_PROCESSED_TOTAL, nProcessedThisTick);

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

    if (GetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING) == TRUE)
    {
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, TRUE);
    DelayCommand(fDelaySec, ExecuteScript("npc_area_maintenance", oArea));
}

void NpcBhvrOnAreaMaintenanceImpl(object oArea)
{
    int nAreaState;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_TIMER_RUNNING, FALSE);
    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG, FALSE);

    nAreaState = NpcBhvrAreaGetState(oArea);
    if (nAreaState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        return;
    }

    NpcBhvrQueueReconcileDeferredTotal(oArea, TRUE);
    NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
}

void NpcBhvrBootstrapModuleAreasImpl()
{
    object oArea;

    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        NpcBhvrApplyTickRuntimeConfig(oArea);

        if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE) == NPC_BHVR_AREA_STATE_RUNNING)
        {
            NpcBhvrAreaActivate(oArea);
        }
        else if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE) == NPC_BHVR_AREA_STATE_PAUSED)
        {
            NpcBhvrScheduleAreaMaintenance(oArea, NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC);
        }
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
    NpcBhvrActivityOnSpawn(oNpc);

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

void NpcBhvrOnPerceptionImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_PERCEPTION_COUNT);
    oArea = GetArea(oNpc);
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_HIGH, NPC_BHVR_REASON_PERCEPTION);
}

void NpcBhvrOnAreaEnterImpl(object oArea, object oEntering)
{
    int nPlayers;
    int nEnteringType;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEntering))
    {
        return;
    }

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

    nPlayers = NpcBhvrGetCachedPlayerCount(oArea) + 1;
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    if (!NpcBhvrAreaIsRunning(oArea))
    {
        NpcBhvrAreaActivate(oArea);
    }
}

void NpcBhvrOnAreaExitImpl(object oArea, object oExiting)
{
    int nPlayers;
    int nExitingType;

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

        NpcBhvrRegistryRemove(oArea, oExiting);
        NpcBhvrAreaRouteCacheInvalidate(oArea);
        return;
    }

    if (GetIsDM(oExiting))
    {
        return;
    }

    nPlayers = NpcBhvrGetCachedPlayerCount(oArea) - 1;
    if (nPlayers < 0)
    {
        nPlayers = NpcBhvrCountPlayersInAreaExcluding(oArea, oExiting);
        if (nPlayers < 0)
        {
            nPlayers = 0;
        }
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    if (nPlayers <= 0)
    {
        NpcBhvrAreaPause(oArea);
    }
}

void NpcBhvrOnModuleLoadImpl()
{
    NpcSqliteInit();
    NpcSqliteHealthcheck();
    NpcBhvrMetricInc(GetModule(), NPC_BHVR_METRIC_MODULE_LOAD_COUNT);
    NpcBhvrBootstrapModuleAreas();
}
