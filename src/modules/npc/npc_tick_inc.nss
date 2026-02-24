// NPC tick/budget/degradation internals.

int NpcBhvrTickPackState(int nProcessed, int nPendingAfter, int nBudgetFlags)
{
    if (nProcessed < 0)
    {
        nProcessed = 0;
    }
    if (nPendingAfter < 0)
    {
        nPendingAfter = 0;
    }

    return nProcessed + nPendingAfter * 128 + nBudgetFlags * 16384;
}

int NpcBhvrTickStateProcessed(int nTickState)
{
    return nTickState % 128;
}

int NpcBhvrTickStatePendingAfter(int nTickState)
{
    return (nTickState / 128) % 128;
}

int NpcBhvrTickStateBudgetFlags(int nTickState)
{
    return nTickState / 16384;
}

int NpcBhvrTickPackPendingCarryover(int nPendingAfter, int nCarryoverEvents)
{
    if (nPendingAfter < 0)
    {
        nPendingAfter = 0;
    }
    if (nCarryoverEvents < 0)
    {
        nCarryoverEvents = 0;
    }

    return nPendingAfter * 8 + nCarryoverEvents;
}

int NpcBhvrTickPendingCarryoverPendingAfter(int nPackedState)
{
    return nPackedState / 8;
}

int NpcBhvrTickPendingCarryoverCarryoverEvents(int nPackedState)
{
    return nPackedState % 8;
}

int NpcBhvrQueuePickPriority(object oArea)
{
    int nCriticalDepth;
    int nCursor;
    int nStreak;
    int nPriority;
    int nAttempts;

    nCriticalDepth = NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_CRITICAL);
    if (nCriticalDepth > 0)
    {
        // CRITICAL bypasses fairness budget.
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
        return NPC_BHVR_PRIORITY_CRITICAL;
    }

    nCursor = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_CURSOR);
    if (nCursor < NPC_BHVR_PRIORITY_HIGH || nCursor > NPC_BHVR_PRIORITY_LOW)
    {
        nCursor = NPC_BHVR_PRIORITY_HIGH;
    }

    nStreak = GetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK);

    if (nStreak >= NPC_BHVR_STARVATION_STREAK_LIMIT)
    {
        nCursor = nCursor + 1;
        if (nCursor > NPC_BHVR_PRIORITY_LOW)
        {
            nCursor = NPC_BHVR_PRIORITY_HIGH;
        }
        nStreak = 0;
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_STARVATION_GUARD_TRIPS);
    }

    nPriority = nCursor;
    nAttempts = 0;
    while (nAttempts < 3)
    {
        if (NpcBhvrQueueGetDepthForPriority(oArea, nPriority) > 0)
        {
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_CURSOR, nPriority);
            NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, nStreak + 1);
            return nPriority;
        }

        nPriority = nPriority + 1;
        if (nPriority > NPC_BHVR_PRIORITY_LOW)
        {
            nPriority = NPC_BHVR_PRIORITY_HIGH;
        }
        nAttempts = nAttempts + 1;
    }

    return -1;
}

int NpcBhvrGetTickMaxEvents(object oArea)
{
    int nValue;

    nValue = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_MAX_EVENTS);
    if (nValue <= 0)
    {
        nValue = NPC_BHVR_TICK_MAX_EVENTS_DEFAULT;
    }

    return nValue;
}

void NpcBhvrSetTickMaxEvents(object oArea, int nValue)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nValue <= 0)
    {
        nValue = NPC_BHVR_TICK_MAX_EVENTS_DEFAULT;
    }

    if (nValue > NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP)
    {
        nValue = NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_TICK_MAX_EVENTS, nValue);
}

int NpcBhvrGetTickSoftBudgetMs(object oArea)
{
    int nValue;

    nValue = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS);
    if (nValue <= 0)
    {
        nValue = NPC_BHVR_TICK_SOFT_BUDGET_MS_DEFAULT;
    }

    return nValue;
}

void NpcBhvrSetTickSoftBudgetMs(object oArea, int nValue)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nValue <= 0)
    {
        nValue = NPC_BHVR_TICK_SOFT_BUDGET_MS_DEFAULT;
    }

    if (nValue > NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP)
    {
        nValue = NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS, nValue);
}

void NpcBhvrApplyTickRuntimeConfig(object oArea)
{
    object oModule;
    int nConfigured;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    oModule = GetModule();

    nConfigured = GetLocalInt(oArea, NPC_BHVR_CFG_TICK_MAX_EVENTS);
    if (nConfigured <= 0)
    {
        nConfigured = GetLocalInt(oModule, NPC_BHVR_CFG_TICK_MAX_EVENTS);
    }
    if (nConfigured > 0 || GetLocalInt(oArea, NPC_BHVR_VAR_TICK_MAX_EVENTS) <= 0)
    {
        NpcBhvrSetTickMaxEvents(oArea, nConfigured);
    }

    nConfigured = GetLocalInt(oArea, NPC_BHVR_CFG_TICK_SOFT_BUDGET_MS);
    if (nConfigured <= 0)
    {
        nConfigured = GetLocalInt(oModule, NPC_BHVR_CFG_TICK_SOFT_BUDGET_MS);
    }
    if (nConfigured > 0 || GetLocalInt(oArea, NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS) <= 0)
    {
        NpcBhvrSetTickSoftBudgetMs(oArea, nConfigured);
    }
}

int NpcBhvrQueueProcessOne(object oArea, int nNow)
{
    int nTotalDepth;
    int nPriority;
    object oSubject;

    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    if (!NpcBhvrAreaIsRunning(oArea))
    {
        NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_DISABLED);
        return FALSE;
    }

    nTotalDepth = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotalDepth <= 0)
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
        return FALSE;
    }

    nPriority = NpcBhvrQueuePickPriority(oArea);
    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL)
    {
        return FALSE;
    }

    oSubject = NpcBhvrQueueDequeueFromPriority(oArea, nPriority);
    if (!GetIsObjectValid(oSubject))
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
        NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_ROUTE_MISS);
        return TRUE;
    }

    NpcBhvrPendingSetStatusTrackedAt(oArea, oSubject, NPC_BHVR_PENDING_STATUS_RUNNING, nNow);

    if (GetArea(oSubject) != oArea)
    {
        NpcBhvrPendingSetStatusTrackedAt(oArea, oSubject, NPC_BHVR_PENDING_STATUS_DEFERRED, nNow);
        NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DEFERRED, nNow);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT);
        return TRUE;
    }

    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_RUNNING, nNow);
    NpcBhvrActivityOnIdleTick(oSubject);
    if (GetIsObjectValid(oSubject))
    {
        NpcBhvrPendingSetStatusTrackedAt(oArea, oSubject, NPC_BHVR_PENDING_STATUS_PROCESSED, nNow);
        NpcBhvrPendingNpcClear(oSubject);
        return TRUE;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
    return TRUE;
}



void NpcBhvrRecordDegradationEvent(object oArea, int nReason)
{
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_EVENTS_TOTAL);
    SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, nReason);
}

int NpcBhvrTickProcessBudgetedWork(object oArea, int nPendingBefore, int nMaxEvents, int nSoftBudgetMs, int nCarryoverEvents)
{
    int nSpentEvents;
    int nSpentBudgetMs;
    int nEventsBudgetLeft;
    int nBudgetFlags;
    int nPendingAfter;
    int nNow;

    nSpentEvents = 0;
    nSpentBudgetMs = 0;
    // Tick-stage timestamp snapshot: reused across this budgeted loop to avoid
    // per-iteration clock reads and keep queue status transitions aligned.
    nNow = NpcBhvrPendingNow();

    while (TRUE)
    {
        nEventsBudgetLeft = (nMaxEvents + nCarryoverEvents) - nSpentEvents;
        if (nEventsBudgetLeft <= 0)
        {
            nBudgetFlags = nBudgetFlags | NPC_BHVR_TICK_FLAG_EVENT_BUDGET_REACHED;
            break;
        }

        if (nSpentBudgetMs + NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS > nSoftBudgetMs)
        {
            nBudgetFlags = nBudgetFlags | NPC_BHVR_TICK_FLAG_SOFT_BUDGET_REACHED;
            break;
        }

        if (!NpcBhvrQueueProcessOne(oArea, nNow))
        {
            break;
        }

        nSpentEvents = nSpentEvents + 1;
        nSpentBudgetMs = nSpentBudgetMs + NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS;
    }

    nPendingAfter = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);

    // Invariant at stage boundary: processed/pending snapshot is captured once and
    // reused by downstream stages instead of re-reading queue locals.
    if ((nBudgetFlags & (NPC_BHVR_TICK_FLAG_EVENT_BUDGET_REACHED | NPC_BHVR_TICK_FLAG_SOFT_BUDGET_REACHED)) &&
        nPendingBefore > nSpentEvents &&
        nPendingAfter > 0)
    {
        nBudgetFlags = nBudgetFlags | NPC_BHVR_TICK_FLAG_BUDGET_EXCEEDED;
    }

    return NpcBhvrTickPackState(nSpentEvents, nPendingAfter, nBudgetFlags);
}

int NpcBhvrTickApplyDegradationAndCarryover(object oArea, int nTickState)
{
    int nPendingAfter;
    int nBudgetFlags;
    int nBudgetExceeded;
    int nEventBudgetReached;
    int nSoftBudgetReached;
    int nCarryoverEvents;
    int nDegradationReason;

    nPendingAfter = NpcBhvrTickStatePendingAfter(nTickState);
    nBudgetFlags = NpcBhvrTickStateBudgetFlags(nTickState);

    nEventBudgetReached = (nBudgetFlags & NPC_BHVR_TICK_FLAG_EVENT_BUDGET_REACHED) != 0;
    nSoftBudgetReached = (nBudgetFlags & NPC_BHVR_TICK_FLAG_SOFT_BUDGET_REACHED) != 0;
    nBudgetExceeded = (nBudgetFlags & NPC_BHVR_TICK_FLAG_BUDGET_EXCEEDED) != 0;

    nCarryoverEvents = 0;

    if (nBudgetExceeded)
    {
        nDegradationReason = NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE;
        if (nEventBudgetReached)
        {
            nDegradationReason = NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET;
        }
        else if (nSoftBudgetReached)
        {
            nDegradationReason = NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET;
        }

        nCarryoverEvents = nPendingAfter;
        if (nCarryoverEvents > NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS)
        {
            nCarryoverEvents = NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS;
        }

        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_TICK_BUDGET_EXCEEDED_TOTAL);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADED_MODE_TOTAL);
        NpcBhvrRecordDegradationEvent(oArea, nDegradationReason);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT);
        NpcBhvrQueueMarkDeferredHead(oArea);
    }

    return nCarryoverEvents;
}

int NpcBhvrTickReconcileDeferredAndTrim(object oArea, int nTickState, int nCarryoverEvents)
{
    int nPendingAfter;
    int nDeferredCount;
    int nDeferredOverflow;
    int bQueueMutated;

    nPendingAfter = NpcBhvrTickStatePendingAfter(nTickState);
    bQueueMutated = FALSE;

    // Hot-path guard only: expensive full walk выполняется только если счётчик
    // deferred выглядит рассинхронизированным.
    nDeferredCount = NpcBhvrQueueGetDeferredTotalReconciledOnDemand(oArea);
    if (nDeferredCount < 0)
    {
        nDeferredCount = 0;
        NpcBhvrQueueSetDeferredTotal(oArea, 0);
        bQueueMutated = TRUE;
    }

    if (nDeferredCount > NPC_BHVR_TICK_DEFERRED_CAP)
    {
        nDeferredOverflow = nDeferredCount - NPC_BHVR_TICK_DEFERRED_CAP;
        if (nDeferredOverflow > 0)
        {
            nDeferredOverflow = NpcBhvrQueueTrimDeferredOverflow(oArea, nDeferredOverflow);
            if (nDeferredOverflow > 0)
            {
                bQueueMutated = TRUE;
            }
            nCarryoverEvents = nCarryoverEvents - nDeferredOverflow;
            if (nCarryoverEvents < 0)
            {
                nCarryoverEvents = 0;
            }
        }
    }

    if (nCarryoverEvents > NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS)
    {
        nCarryoverEvents = NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS;
    }

    // Invariants: deferred-total must be non-negative and pending totals must be
    // synchronized with per-priority depths before final carryover commit only
    // when queue data was mutated in this reconcile pass.
    if (bQueueMutated)
    {
        NpcBhvrQueueSyncTotals(oArea);
        nPendingAfter = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);
    }

    return NpcBhvrTickPackPendingCarryover(nPendingAfter, nCarryoverEvents);
}

void NpcBhvrTickFlushWriteBehind()
{
    int nNow;

    // write-behind: фиксируем timestamp один раз на тик для консистентности
    // (ShouldFlush/Flush работают с одним и тем же временем) и снижения накладных расходов.
    nNow = NpcBhvrPendingNow();
    if (NpcSqliteWriteBehindShouldFlush(nNow, NPC_SQLITE_WB_BATCH_SIZE_DEFAULT, NPC_SQLITE_WB_FLUSH_INTERVAL_SEC_DEFAULT))
    {
        NpcSqliteWriteBehindFlush(nNow, NPC_SQLITE_WB_BATCH_SIZE_DEFAULT);
    }
}

void NpcBhvrTickPrepareBudgets(object oArea)
{
    int nMaxEvents;
    int nSoftBudgetMs;
    int nCarryoverEvents;

    // Hot-path optimization: normalize first, then write only changed values to reduce area-tick write-amplification.
    // Budget normalization boundary: держим все тик-лимиты в валидных диапазонах.
    nMaxEvents = NpcBhvrGetTickMaxEvents(oArea);
    if (nMaxEvents > NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP)
    {
        nMaxEvents = NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP;
    }

    nSoftBudgetMs = NpcBhvrGetTickSoftBudgetMs(oArea);
    if (nSoftBudgetMs > NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP)
    {
        nSoftBudgetMs = NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP;
    }

    nCarryoverEvents = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS);
    if (nCarryoverEvents < 0)
    {
        nCarryoverEvents = 0;
    }
    if (nCarryoverEvents > NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS)
    {
        nCarryoverEvents = NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_MAX_EVENTS, nMaxEvents);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS, nSoftBudgetMs);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS, nCarryoverEvents);
}

void NpcBhvrTickHandleBacklogTelemetry(object oArea, int nPendingAfter)
{
    int nBacklogAgeTicks;

    // Backlog telemetry boundary: учитываем возраст backlog и pending-age метрику.
    // read-normalize-write-if-changed: в тиковом hot-path избегаем лишних одинаковых записей.
    if (nPendingAfter > 0)
    {
        nBacklogAgeTicks = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS) + 1;
        if (nBacklogAgeTicks < 0)
        {
            nBacklogAgeTicks = 0;
        }
        NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS, nBacklogAgeTicks);
        NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_PENDING_AGE_MS, nPendingAfter * 1000);
        return;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS, 0);
}

int NpcBhvrTickResolveIdleBudget(object oArea, int nPendingTotal)
{
    int nBaseBudget;
    int nMaxEvents;
    int nSoftBudgetMs;
    int nCarryoverEvents;
    int nThreshold;
    int nBudget;

    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_IDLE_MAX_NPC_PER_TICK_DEFAULT;
    }

    nBaseBudget = NPC_BHVR_IDLE_MAX_NPC_PER_TICK_DEFAULT;
    nMaxEvents = NpcBhvrGetTickMaxEvents(oArea);
    nSoftBudgetMs = NpcBhvrGetTickSoftBudgetMs(oArea);
    nCarryoverEvents = GetLocalInt(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS);

    if (nCarryoverEvents < 0)
    {
        nCarryoverEvents = 0;
    }

    // Adaptive threshold ties idle throttling to runtime tick limits and current carryover pressure.
    nThreshold = nMaxEvents + (nSoftBudgetMs / NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS) +
        (nCarryoverEvents * NPC_BHVR_IDLE_ADAPTIVE_CARRYOVER_WEIGHT);

    if (nThreshold < nBaseBudget)
    {
        nThreshold = nBaseBudget;
    }

    if (nPendingTotal > nThreshold)
    {
        nBudget = nBaseBudget - ((nPendingTotal - nThreshold) / NPC_BHVR_IDLE_ADAPTIVE_THRESHOLD_DIVISOR);
        if (nBudget < NPC_BHVR_IDLE_MAX_NPC_PER_TICK_MIN)
        {
            nBudget = NPC_BHVR_IDLE_MAX_NPC_PER_TICK_MIN;
        }

        if (nBudget < nBaseBudget)
        {
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_IDLE_BUDGET_THROTTLED_TOTAL);
        }

        return nBudget;
    }

    // Queue normalized: idle budget automatically returns to baseline.
    return nBaseBudget;
}

void NpcBhvrTickHandleIdleStop(object oArea, int nPendingAfter)
{
    int nPlayers;

    // Area stop policy boundary: cached player-count + empty-queue predicate.
    nPlayers = NpcBhvrGetCachedPlayerCountInternal(oArea);
    if (nPlayers <= 0 && nPendingAfter <= 0)
    {
        NpcBhvrAreaStop(oArea);
    }
}

void NpcBhvrTickScheduleNext(object oArea)
{
    int nAreaState;

    nAreaState = NpcBhvrAreaGetState(oArea);

    if (nAreaState == NPC_BHVR_AREA_STATE_RUNNING)
    {
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC, ExecuteScript("npc_area_tick", oArea));
        return;
    }

    if (nAreaState == NPC_BHVR_AREA_STATE_PAUSED)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_PAUSED_WATCHDOG_TICK_COUNT);
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_PAUSED_WATCHDOG_SEC, ExecuteScript("npc_area_tick", oArea));
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
}
