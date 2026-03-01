// Deferred/overflow reconciliation internals.

int NpcBhvrQueueGetDeferredTotal(object oArea)
{
    int nDeferredTotal;

    nDeferredTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEFERRED_TOTAL);
    if (nDeferredTotal < 0)
    {
        nDeferredTotal = 0;
    }

    return nDeferredTotal;
}

void NpcBhvrQueueSetDeferredTotal(object oArea, int nDeferredTotal)
{
    if (nDeferredTotal < 0)
    {
        nDeferredTotal = 0;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEFERRED_TOTAL, nDeferredTotal);
}

// Hot-path-safe linear walk: read head/depth once per priority, then advance
// by ring-next slot while counting valid deferred subjects.
int NpcBhvrQueueCountDeferred(object oArea)
{
    int nCount;
    int nPriority;
    int nHead;
    int nDepth;
    int nIndex;
    int nSlot;
    object oSubject;

    nCount = 0;
    nPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        nHead = GetLocalInt(oArea, NpcBhvrQueueHeadKey(nPriority));
        if (nHead < 1 || nHead > NPC_BHVR_QUEUE_MAX)
        {
            nHead = 1;
        }

        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
        nSlot = nHead;
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nSlot));
            if (GetIsObjectValid(oSubject) && GetLocalInt(oSubject, NPC_BHVR_VAR_PENDING_STATUS) == NPC_BHVR_PENDING_STATUS_DEFERRED)
            {
                nCount = nCount + 1;
            }

            nSlot = NpcBhvrQueueRingNextSlot(nSlot);
            nIndex = nIndex + 1;
        }

        nPriority = nPriority + 1;
    }

    return nCount;
}

int NpcBhvrQueueDeferredLooksDesynced(object oArea)
{
    int nDeferredCount;
    int nPendingTotal;

    nDeferredCount = NpcBhvrQueueGetDeferredTotal(oArea);
    nPendingTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);

    return nDeferredCount < 0 || nDeferredCount > nPendingTotal;
}

int NpcBhvrQueueReconcileDeferredTotal(object oArea, int bMarkSelfHeal)
{
    int nDeferredActual;
    int nDeferredBefore;

    nDeferredBefore = NpcBhvrQueueGetDeferredTotal(oArea);
    nDeferredActual = NpcBhvrQueueCountDeferred(oArea);
    if (nDeferredActual != nDeferredBefore)
    {
        if (bMarkSelfHeal)
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG, TRUE);
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_MAINT_SELF_HEAL_COUNT);
        }

        NpcBhvrQueueSetDeferredTotal(oArea, nDeferredActual);
    }

    return nDeferredActual;
}

int NpcBhvrQueueGetDeferredTotalReconciledOnDemand(object oArea)
{
    if (NpcBhvrQueueDeferredLooksDesynced(oArea))
    {
        return NpcBhvrQueueReconcileDeferredTotal(oArea, FALSE);
    }

    return NpcBhvrQueueGetDeferredTotal(oArea);
}

int NpcBhvrQueueTrimDeferredOverflow(object oArea, int nTrimCount)
{
    int nTrimmed;
    int nPriority;
    int nDepth;
    int nHead;
    int nIndex;
    int nSlot;
    object oSubject;

    if (nTrimCount <= 0)
    {
        return 0;
    }

    // Deferred trim is pressure-relief only; it intentionally permits swap-tail
    // removal (non-FIFO) because relative deferred order is not semantically
    // significant, unlike dequeue paths that must preserve FIFO ordering.

    nTrimmed = 0;
    nPriority = NPC_BHVR_PRIORITY_LOW;
    while (nPriority >= NPC_BHVR_PRIORITY_CRITICAL && nTrimmed < nTrimCount)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
        nHead = GetLocalInt(oArea, NpcBhvrQueueHeadKey(nPriority));
        if (nHead < 1 || nHead > NPC_BHVR_QUEUE_MAX)
        {
            nHead = 1;
        }

        nIndex = nDepth;
        while (nIndex >= 1 && nTrimmed < nTrimCount)
        {
            nSlot = nHead + nIndex - 1;
            while (nSlot > NPC_BHVR_QUEUE_MAX)
            {
                nSlot = nSlot - NPC_BHVR_QUEUE_MAX;
            }

            oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nSlot));
            if (GetIsObjectValid(oSubject) && GetLocalInt(oSubject, NPC_BHVR_VAR_PENDING_STATUS) == NPC_BHVR_PENDING_STATUS_DEFERRED)
            {
                oSubject = NpcBhvrQueueRemoveSwapTail(oArea, nPriority, nSlot);
                NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DROPPED);
                NpcBhvrPendingNpcClear(oSubject);
                NpcBhvrPendingAreaClear(oArea, oSubject);
                NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
                NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE);
                nTrimmed = nTrimmed + 1;
            }

            nIndex = nIndex - 1;
        }

        nPriority = nPriority - 1;
    }

    NpcBhvrQueueSetDeferredTotal(oArea, NpcBhvrQueueGetDeferredTotal(oArea));

    return nTrimmed;
}

void NpcBhvrQueueMarkDeferredHead(object oArea)
{
    int nPriority;
    object oSubject;

    nPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        oSubject = NpcBhvrQueuePeekFromPriority(oArea, nPriority);
        if (GetIsObjectValid(oSubject))
        {
            // Deferred must be mirrored both in area queue metadata and NPC-local state.
            NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DEFERRED);
            NpcBhvrPendingSetStatusTracked(oArea, oSubject, NPC_BHVR_PENDING_STATUS_DEFERRED);
            return;
        }

        nPriority = nPriority + 1;
    }
}
