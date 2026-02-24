// NPC queue + pending/deferred internals.

void NpcBhvrRecordDegradationEvent(object oArea, int nReason);
int NpcBhvrAreaIsRunning(object oArea);
void NpcBhvrAreaActivate(object oArea);
void NpcBhvrPendingNpcTouchAt(object oNpc, int nNow);
void NpcBhvrPendingSetStatusAt(object oNpc, int nStatus, int nNow);
void NpcBhvrPendingSetStatusTrackedAt(object oArea, object oNpc, int nStatus, int nNow);
void NpcBhvrPendingSetAt(object oNpc, int nPriority, string sReason, int nStatus, int nNow);
void NpcBhvrPendingSetTrackedAt(object oArea, object oNpc, int nPriority, string sReason, int nStatus, int nNow);

#include "npc_queue_pending_inc"
#include "npc_queue_index_inc"
#include "npc_queue_deferred_inc"
#include "npc_queue_legacy_inc"
void NpcBhvrPendingAreaTouchAt(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus, int nNow);


void NpcBhvrAreaRouteCacheWarmup(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, "npc_route_cache_warm", TRUE);
}

void NpcBhvrAreaRouteCacheInvalidate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    DeleteLocalInt(oArea, "npc_route_cache_warm");
}

string NpcBhvrPendingStatusToString(int nStatus)
{
    if (nStatus == NPC_BHVR_PENDING_STATUS_QUEUED)
    {
        return NPC_BHVR_PENDING_STATUS_STR_QUEUED;
    }

    if (nStatus == NPC_BHVR_PENDING_STATUS_RUNNING)
    {
        return NPC_BHVR_PENDING_STATUS_STR_RUNNING;
    }

    if (nStatus == NPC_BHVR_PENDING_STATUS_PROCESSED)
    {
        return NPC_BHVR_PENDING_STATUS_STR_PROCESSED;
    }

    if (nStatus == NPC_BHVR_PENDING_STATUS_DEFERRED)
    {
        return NPC_BHVR_PENDING_STATUS_STR_DEFERRED;
    }

    if (nStatus == NPC_BHVR_PENDING_STATUS_DROPPED)
    {
        return NPC_BHVR_PENDING_STATUS_STR_DROPPED;
    }

    return "";
}

void NpcBhvrPendingNpcClear(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Clear only on explicit terminal transitions (processed/dropped/death),
    // never as part of non-terminal deferred transitions. Terminal drop-paths
    // must clear both area-local and NPC-local pending state.
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
}

object NpcBhvrQueueRemoveSwapTail(object oArea, int nPriority, int nIndex)
{
    int nDepth;
    object oRemoved;
    object oTail;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nIndex < 1 || nIndex > nDepth)
    {
        return OBJECT_INVALID;
    }

    oRemoved = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
    if (nIndex != nDepth)
    {
        oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
        SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), oTail);
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    NpcBhvrQueueSyncTotals(oArea);

    return oRemoved;
}

// Inserts into priority queue and guarantees totals refresh on successful insert.
int NpcBhvrQueueEnqueueRaw(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nTotal;

    nTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotal >= NPC_BHVR_QUEUE_MAX)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT);
        return FALSE;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority) + 1;
    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth), oSubject);
    NpcBhvrQueueIndexSet(oArea, oSubject, nPriority, nDepth);
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth);
    NpcBhvrQueueSyncTotals(oArea);
    return TRUE;
}

string NpcBhvrQueueDepthKey(int nPriority)
{
    return "npc_queue_depth_" + IntToString(nPriority);
}

string NpcBhvrQueueSubjectKey(int nPriority, int nIndex)
{
    return "npc_queue_subject_" + IntToString(nPriority) + "_" + IntToString(nIndex);
}


void NpcBhvrPendingAreaTouch(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus)
{
    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, nReasonCode, nStatus, NpcBhvrPendingNow());
}

void NpcBhvrPendingAreaTouchAt(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus, int nNow)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    // Contract: area-local cache mirrors the last visible queue-state for
    // diagnostics and should stay consistent with NPC-local status transitions.
    // Callers updating both mirrors in one logical step should pass the same
    // nNow to NpcBhvrPendingAreaTouchAt(...) and NPC-local *At update.
    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    NpcBhvrPendingAreaMigrateLegacy(oArea, oSubject, sNpcKey);
    SetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nPriority);
    SetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nReasonCode);
    SetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey), NpcBhvrPendingStatusToString(nStatus));
    SetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), nNow);
}

void NpcBhvrPendingAreaClear(object oArea, object oSubject)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    // Area-local clear is explicit/terminal and must not be used to drop
    // deferred state implicitly. Terminal drop-paths must pair this with
    // NpcBhvrPendingNpcClear(...) to preserve pending lifecycle invariants.
    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    NpcBhvrPendingAreaMigrateLegacy(oArea, oSubject, sNpcKey);
    DeleteLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey));
    DeleteLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey));

    sNpcKey = NpcBhvrPendingLegacySubjectTag(oSubject);
    DeleteLocalInt(oArea, NpcBhvrPendingPriorityLegacyKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingReasonCodeLegacyKey(sNpcKey));
    DeleteLocalString(oArea, NpcBhvrPendingStatusLegacyKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingUpdatedAtLegacyKey(sNpcKey));
}

int NpcBhvrPriorityEscalate(int nCurrentPriority, int nIncomingPriority, int nReasonCode)
{
    int nEscalated;

    if (nCurrentPriority < NPC_BHVR_PRIORITY_CRITICAL || nCurrentPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nCurrentPriority = NPC_BHVR_PRIORITY_NORMAL;
    }

    if (nIncomingPriority < NPC_BHVR_PRIORITY_CRITICAL || nIncomingPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nIncomingPriority = NPC_BHVR_PRIORITY_NORMAL;
    }

    nEscalated = nCurrentPriority;
    if (nIncomingPriority < nEscalated)
    {
        nEscalated = nIncomingPriority;
    }

    // Damage reason promotes pending work to CRITICAL (HIGH -> CRITICAL rule included).
    if (nReasonCode == NPC_BHVR_REASON_DAMAGE && nEscalated > NPC_BHVR_PRIORITY_CRITICAL)
    {
        nEscalated = NPC_BHVR_PRIORITY_CRITICAL;
    }

    return nEscalated;
}

int NpcBhvrQueueGetDepthForPriority(object oArea, int nPriority)
{
    return GetLocalInt(oArea, NpcBhvrQueueDepthKey(nPriority));
}

void NpcBhvrQueueSetDepthForPriority(object oArea, int nPriority, int nDepth)
{
    SetLocalInt(oArea, NpcBhvrQueueDepthKey(nPriority), nDepth);
}

void NpcBhvrQueueSyncTotals(object oArea)
{
    int nTotal;

    nTotal = NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_CRITICAL)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_HIGH)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_NORMAL)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_LOW);

    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH, nTotal);
    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL, nTotal);
}

void NpcBhvrQueueClear(object oArea)
{
    int nPriority;
    int nDepth;
    int nIndex;
    object oRegistered;

    nPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            oRegistered = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
            if (GetIsObjectValid(oRegistered))
            {
                NpcBhvrQueueIndexClear(oArea, oRegistered);
            }

            DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
            nIndex = nIndex + 1;
        }

        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, 0);
        nPriority = nPriority + 1;
    }

    nDepth = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    nIndex = 1;
    while (nIndex <= nDepth)
    {
        oRegistered = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        if (GetIsObjectValid(oRegistered))
        {
            DeleteLocalInt(oArea, NpcBhvrRegistryIndexKey(oRegistered));
        }

        DeleteLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        nIndex = nIndex + 1;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_CURSOR, NPC_BHVR_PRIORITY_HIGH);
    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEFERRED_TOTAL, 0);
    SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, 0);
    NpcBhvrRegistryResetIdleCursor(oArea);
    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG, FALSE);
    NpcBhvrQueueSyncTotals(oArea);
}


void NpcBhvrQueueApplyDepthAndTotals(object oArea, int nPriority, int nDepth)
{
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth);
    NpcBhvrQueueSyncTotals(oArea);
}

int NpcBhvrQueueAppendSubject(object oArea, object oSubject, int nPriority)
{
    int nDepth;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority) + 1;
    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth), oSubject);
    NpcBhvrQueueIndexSet(oArea, oSubject, nPriority, nDepth);
    NpcBhvrQueueApplyDepthAndTotals(oArea, nPriority, nDepth);
    return TRUE;
}

object NpcBhvrQueueSwapTailSubject(object oArea, int nPriority, int nIndex, int bClearRemovedIndex)
{
    int nDepth;
    object oRemoved;
    object oTail;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nIndex < 1 || nIndex > nDepth)
    {
        return OBJECT_INVALID;
    }

    oRemoved = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));

    if (nIndex != nDepth)
    {
        oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
        SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), oTail);
        if (GetIsObjectValid(oTail))
        {
            NpcBhvrQueueIndexSet(oArea, oTail, nPriority, nIndex);
        }
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    if (bClearRemovedIndex && GetIsObjectValid(oRemoved))
    {
        NpcBhvrQueueIndexClear(oArea, oRemoved);
    }

    NpcBhvrQueueApplyDepthAndTotals(oArea, nPriority, nDepth - 1);
    return oRemoved;
}

int NpcBhvrQueueFindSubjectByPointChecks(object oArea, object oSubject, int nPriorityHint, int nPositionHint)
{
    int nDepth;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return 0;
    }

    if (nPriorityHint < NPC_BHVR_PRIORITY_CRITICAL || nPriorityHint > NPC_BHVR_PRIORITY_LOW || nPositionHint <= 0)
    {
        return 0;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriorityHint);
    if (nPositionHint > nDepth)
    {
        return 0;
    }

    if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriorityHint, nPositionHint)) == oSubject)
    {
        return nPriorityHint * 1000 + nPositionHint;
    }

    return 0;
}

int NpcBhvrQueueTryResolveIndexedSubject(object oArea, object oSubject)
{
    int nIndexedPriority;
    int nIndexedPosition;
    int nFound;

    nIndexedPriority = NpcBhvrQueueIndexPriority(oArea, oSubject);
    nIndexedPosition = NpcBhvrQueueIndexPosition(oArea, oSubject);
    if (nIndexedPriority < NPC_BHVR_PRIORITY_CRITICAL || nIndexedPriority > NPC_BHVR_PRIORITY_LOW || nIndexedPosition <= 0)
    {
        return 0;
    }

    nFound = NpcBhvrQueueFindSubjectByPointChecks(oArea, oSubject, nIndexedPriority, nIndexedPosition);
    if (nFound != 0)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_INDEX_HIT_TOTAL);
        return nFound;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_INDEX_MISS_TOTAL);
    NpcBhvrQueueIndexClear(oArea, oSubject);
    return 0;
}

int NpcBhvrQueueFindSubjectSlowPath(object oArea, object oSubject)
{
    int nExistingPriority;
    int nDepth;
    int nIndex;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return 0;
    }

    // Slow-path: one full scan across all buckets (at most once per enqueue).
    nExistingPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nExistingPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nExistingPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nIndex)) == oSubject)
            {
                return nExistingPriority * 1000 + nIndex;
            }

            nIndex = nIndex + 1;
        }

        nExistingPriority = nExistingPriority + 1;
    }

    return 0;
}

void NpcBhvrQueuePostUpdateQueued(object oArea, object oSubject, int nPriority, int nReasonCode, int bStatusOnlyIfPending)
{
    NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
    if (bStatusOnlyIfPending && NpcBhvrPendingIsActive(oSubject))
    {
        NpcBhvrPendingSetStatusTracked(oArea, oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
    }
    else
    {
        NpcBhvrPendingSetTracked(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
    }
}

int NpcBhvrQueueCoalesceSubject(object oArea, object oSubject, int nFoundPriority, int nFoundIndex, int nRequestedPriority, int nReasonCode, int bWasPendingActive)
{
    int nEscalatedPriority;

    nEscalatedPriority = NpcBhvrPriorityEscalate(nFoundPriority, nRequestedPriority, nReasonCode);
    if (nEscalatedPriority != nFoundPriority)
    {
        NpcBhvrQueueSwapTailSubject(oArea, nFoundPriority, nFoundIndex, FALSE);
        if (!NpcBhvrQueueAppendSubject(oArea, oSubject, nEscalatedPriority))
        {
            return FALSE;
        }
    }
    else
    {
        NpcBhvrQueueIndexSet(oArea, oSubject, nFoundPriority, nFoundIndex);
    }

    NpcBhvrQueuePostUpdateQueued(oArea, oSubject, nEscalatedPriority, nReasonCode, bWasPendingActive);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT);
    return TRUE;
}

void NpcBhvrQueueMarkDroppedOnEnqueueFailure(object oArea, object oSubject, int nPriority, int nReasonCode, int nNow)
{
    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED, nNow);
    NpcBhvrPendingSetTrackedAt(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_DROPPED, nNow);
    NpcBhvrPendingNpcClear(oSubject);
    NpcBhvrPendingAreaClear(oArea, oSubject);
    NpcBhvrQueueIndexClear(oArea, oSubject);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
    NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_OVERFLOW);
}

int NpcBhvrQueueEnqueue(object oArea, object oSubject, int nPriority, int nReasonCode)
{
    int nTotal;
    int nFound;
    int nFoundPriority;
    int nFoundIndex;
    int bWasPendingActive;
    int nNow;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nPriority = NPC_BHVR_PRIORITY_NORMAL;
    }

    nNow = NpcBhvrPendingNow();

    bWasPendingActive = NpcBhvrPendingIsActive(oSubject);

    // Hot-path: index hint + point-check; no full scan here.
    nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oSubject);

    // Slow-path: single full scan fallback (at most once per enqueue).
    if (nFound == 0)
    {
        nFound = NpcBhvrQueueFindSubjectSlowPath(oArea, oSubject);
    }

    if (nFound != 0)
    {
        nFoundPriority = nFound / 1000;
        nFoundIndex = nFound - nFoundPriority * 1000;
        return NpcBhvrQueueCoalesceSubject(oArea, oSubject, nFoundPriority, nFoundIndex, nPriority, nReasonCode, bWasPendingActive);
    }

    nTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotal >= NPC_BHVR_QUEUE_MAX)
    {
        if (!NpcBhvrQueueApplyOverflowGuardrail(oArea, nPriority, nReasonCode))
        {
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT);
            NpcBhvrQueueMarkDroppedOnEnqueueFailure(oArea, oSubject, nPriority, nReasonCode, nNow);
            return FALSE;
        }
    }

    if (!NpcBhvrQueueEnqueueRaw(oArea, oSubject, nPriority))
    {
        NpcBhvrQueueMarkDroppedOnEnqueueFailure(oArea, oSubject, nPriority, nReasonCode, nNow);
        return FALSE;
    }

    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    NpcBhvrPendingSetTrackedAt(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    NpcSqliteWriteBehindMarkDirty();
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_ENQUEUED_COUNT);
    return TRUE;
}

object NpcBhvrQueueDequeueFromPriority(object oArea, int nPriority)
{
    int nDepth;
    int nIndex;
    object oSubject;
    object oShifted;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return OBJECT_INVALID;
    }

    oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, 1));

    nIndex = 1;
    while (nIndex < nDepth)
    {
        oShifted = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex + 1));
        SetLocalObject(
            oArea,
            NpcBhvrQueueSubjectKey(nPriority, nIndex),
            oShifted
        );
        if (GetIsObjectValid(oShifted))
        {
            NpcBhvrQueueIndexSet(oArea, oShifted, nPriority, nIndex);
        }
        nIndex = nIndex + 1;
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    if (GetIsObjectValid(oSubject))
    {
        NpcBhvrQueueIndexClear(oArea, oSubject);
    }
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    NpcBhvrQueueSyncTotals(oArea);
    return oSubject;
}

object NpcBhvrQueuePeekFromPriority(object oArea, int nPriority)
{
    if (NpcBhvrQueueGetDepthForPriority(oArea, nPriority) <= 0)
    {
        return OBJECT_INVALID;
    }

    return GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, 1));
}

int NpcBhvrQueueDropTailFromPriority(object oArea, int nPriority)
{
    int nDepth;
    object oDropped;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return FALSE;
    }

    oDropped = NpcBhvrQueueRemoveSwapTail(oArea, nPriority, nDepth);

    if (GetIsObjectValid(oDropped))
    {
        if (GetLocalInt(oDropped, NPC_BHVR_VAR_PENDING_STATUS) == NPC_BHVR_PENDING_STATUS_DEFERRED)
        {
            NpcBhvrQueueSetDeferredTotal(oArea, NpcBhvrQueueGetDeferredTotal(oArea) - 1);
        }

        NpcBhvrPendingAreaTouch(oArea, oDropped, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingNpcClear(oDropped);
        NpcBhvrPendingAreaClear(oArea, oDropped);
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
    NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_OVERFLOW);
    return TRUE;
}

int NpcBhvrQueueApplyOverflowGuardrail(object oArea, int nIncomingPriority, int nReasonCode)
{
    int nPriority;

    if (nIncomingPriority <= NPC_BHVR_PRIORITY_CRITICAL || nReasonCode == NPC_BHVR_REASON_DAMAGE)
    {
        return FALSE;
    }

    nPriority = NPC_BHVR_PRIORITY_LOW;
    while (nPriority >= nIncomingPriority)
    {
        if (NpcBhvrQueueDropTailFromPriority(oArea, nPriority))
        {
            return TRUE;
        }

        nPriority = nPriority - 1;
    }

    return FALSE;
}
