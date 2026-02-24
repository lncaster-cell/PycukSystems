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

void NpcBhvrAreaActivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrApplyTickRuntimeConfig(oArea);
    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_RUNNING);
    NpcBhvrAreaRouteCacheWarmup(oArea);
    NpcBhvrSetTickMaxEvents(oArea, NpcBhvrGetTickMaxEvents(oArea));
    NpcBhvrSetTickSoftBudgetMs(oArea, NpcBhvrGetTickSoftBudgetMs(oArea));

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
            NpcBhvrRegistryBroadcastIdleTick(oArea);
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
