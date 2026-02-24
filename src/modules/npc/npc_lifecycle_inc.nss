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

        // Tick pipeline: ProcessBudgetedWork -> ApplyDegradationAndCarryover -> ReconcileDeferredAndTrim.
        nTickState = NpcBhvrTickProcessBudgetedWork(oArea, nPendingBefore, nMaxEvents, nSoftBudgetMs, nCarryoverEvents);
        nCarryoverEvents = NpcBhvrTickApplyDegradationAndCarryover(oArea, nTickState);
        nPendingAfter = NpcBhvrTickReconcileDeferredAndTrim(oArea, nTickState, nCarryoverEvents);

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

void NpcBhvrOnDamagedImpl(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DAMAGED_COUNT);
    oArea = GetArea(oNpc);
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_CRITICAL, NPC_BHVR_REASON_DAMAGE);
}

void NpcBhvrOnDeathImpl(object oNpc)
{
    object oArea;
    int nFound;
    int nFoundPriority;
    int nFoundIndex;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DEATH_COUNT);

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        NpcBhvrPendingNpcClear(oNpc);
        return;
    }

    NpcBhvrRegistryRemove(oArea, oNpc);
    nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oNpc);
    while (nFound != 0)
    {
        nFoundPriority = nFound / 1000;
        nFoundIndex = nFound - nFoundPriority * 1000;
        NpcBhvrQueueSwapTailSubject(oArea, nFoundPriority, nFoundIndex, TRUE);
        nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oNpc);
    }

    NpcBhvrPendingNpcClear(oNpc);
    NpcBhvrPendingAreaClear(oArea, oNpc);
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
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_NORMAL, NPC_BHVR_REASON_UNSPECIFIED);
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
