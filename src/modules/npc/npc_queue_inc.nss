// NPC queue + pending/deferred internals.

void NpcBhvrRecordDegradationEvent(object oArea, int nReason);
int NpcBhvrAreaIsRunning(object oArea);
void NpcBhvrAreaActivate(object oArea);
void NpcBhvrPendingNpcTouchAt(object oNpc, int nNow);
void NpcBhvrPendingSetStatusAt(object oNpc, int nStatus, int nNow);
void NpcBhvrPendingSetStatusTrackedAt(object oArea, object oNpc, int nStatus, int nNow);
void NpcBhvrPendingSetAt(object oNpc, int nPriority, string sReason, int nStatus, int nNow);
void NpcBhvrPendingSetTrackedAt(object oArea, object oNpc, int nPriority, string sReason, int nStatus, int nNow);
void NpcBhvrPendingSetTrackedAtIntReason(object oArea, object oNpc, int nPriority, int nReasonCode, int nStatus, int nNow);
void NpcBhvrQueueApplyTotalsDelta(object oArea, int nDelta);
int NpcBhvrQueueGetDeferredTotal(object oArea);
void NpcBhvrQueueSetDeferredTotal(object oArea, int nDeferredTotal);
int NpcBhvrQueueGetDepthForPriority(object oArea, int nPriority);
void NpcBhvrQueueSetDepthForPriority(object oArea, int nPriority, int nDepth);
string NpcBhvrQueueSubjectKey(int nPriority, int nIndex);
object NpcBhvrQueueRemoveSwapTail(object oArea, int nPriority, int nIndex);
void NpcBhvrPendingAreaTouch(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus);
void NpcBhvrPendingNpcClear(object oNpc);
void NpcBhvrPendingAreaClear(object oArea, object oSubject);
object NpcBhvrQueuePeekFromPriority(object oArea, int nPriority);
int NpcBhvrQueueApplyOverflowGuardrail(object oArea, int nIncomingPriority, int nReasonCode);
void NpcBhvrQueuePurgeSubject(object oArea, object oSubject);

#include "npc_queue_pending_inc"
#include "npc_queue_index_inc"
#include "npc_queue_ring_inc"
#include "npc_queue_deferred_inc"
#include "npc_queue_legacy_inc"
void NpcBhvrPendingAreaTouchAt(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus, int nNow);


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
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_REASON_CODE);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
}

object NpcBhvrQueueRemoveSwapTail(object oArea, int nPriority, int nIndex)
{
    int nDepth;
    int nTail;
    int nRemovedStatus;
    object oRemoved;
    object oTail;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0 || nIndex < 1 || nIndex > NPC_BHVR_QUEUE_MAX)
    {
        return OBJECT_INVALID;
    }

    oRemoved = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
    nTail = GetLocalInt(oArea, NpcBhvrQueueTailKey(nPriority));
    if (nTail < 1 || nTail > NPC_BHVR_QUEUE_MAX)
    {
        nTail = 1;
    }

    if (nIndex != nTail)
    {
        oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nTail));
        SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), oTail);
        if (GetIsObjectValid(oTail))
        {
            NpcBhvrQueueIndexSet(oArea, oTail, nPriority, nIndex);
        }
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nTail));
    if (nDepth == 1)
    {
        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, 0);
    }
    else
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueTailKey(nPriority), NpcBhvrQueueRingPrevSlot(nTail));
        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    }

    NpcBhvrQueueApplyTotalsDelta(oArea, -1);

    if (GetIsObjectValid(oRemoved))
    {
        nRemovedStatus = GetLocalInt(oRemoved, NPC_BHVR_VAR_PENDING_STATUS);
        if (nRemovedStatus == NPC_BHVR_PENDING_STATUS_DEFERRED)
        {
            NpcBhvrQueueSetDeferredTotal(oArea, NpcBhvrQueueGetDeferredTotal(oArea) - 1);
        }
    }

    return oRemoved;
}

// Inserts into priority queue and guarantees totals refresh on successful insert.
int NpcBhvrQueueEnqueueRaw(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nHead;
    int nTail;
    int nTotal;

    nTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotal >= NPC_BHVR_QUEUE_MAX)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT);
        return FALSE;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        nHead = 1;
        nTail = 1;
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueHeadKey(nPriority), nHead);
    }
    else
    {
        nTail = NpcBhvrQueueRingNextSlot(GetLocalInt(oArea, NpcBhvrQueueTailKey(nPriority)));
    }

    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nTail), oSubject);
    NpcBhvrQueueIndexSet(oArea, oSubject, nPriority, nTail);
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueTailKey(nPriority), nTail);
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth + 1);
    NpcBhvrQueueApplyTotalsDelta(oArea, 1);
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

string NpcBhvrQueueHeadKey(int nPriority);
string NpcBhvrQueueTailKey(int nPriority);
string NpcBhvrQueueCountKey(int nPriority);


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
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nPriority);
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nReasonCode);
    NpcBhvrSetLocalStringIfChanged(oArea, NpcBhvrPendingStatusKey(sNpcKey), NpcBhvrPendingStatusToString(nStatus));
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), nNow);
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
    int nDepth;

    nDepth = GetLocalInt(oArea, NpcBhvrQueueCountKey(nPriority));
    if (nDepth <= 0)
    {
        nDepth = GetLocalInt(oArea, NpcBhvrQueueDepthKey(nPriority));
        if (nDepth > 0)
        {
            if (nDepth > NPC_BHVR_QUEUE_MAX)
            {
                nDepth = NPC_BHVR_QUEUE_MAX;
            }

            NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueCountKey(nPriority), nDepth);
            NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueHeadKey(nPriority), 1);
            NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueTailKey(nPriority), nDepth);
        }
    }

    return nDepth;
}

void NpcBhvrQueueSetDepthForPriority(object oArea, int nPriority, int nDepth)
{
    if (nDepth < 0)
    {
        nDepth = 0;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueDepthKey(nPriority), nDepth);
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueCountKey(nPriority), nDepth);
    if (nDepth == 0)
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueHeadKey(nPriority), 1);
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueTailKey(nPriority), 1);
    }
}

void NpcBhvrQueueApplyTotalsDelta(object oArea, int nDelta)
{
    int nTotal;

    // Hot-path optimization for enqueue/dequeue: avoid redundant local writes.
    nTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH) + nDelta;
    if (nTotal < 0)
    {
        nTotal = 0;
    }

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_DEPTH, nTotal);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL, nTotal);
}

void NpcBhvrQueueSyncTotals(object oArea)
{
    int nTotal;

    nTotal = NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_CRITICAL)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_HIGH)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_NORMAL)
        + NpcBhvrQueueGetDepthForPriority(oArea, NPC_BHVR_PRIORITY_LOW);

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_DEPTH, nTotal);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL, nTotal);
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
            oRegistered = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueRingLogicalToSlot(oArea, nPriority, nIndex)));
            if (GetIsObjectValid(oRegistered))
            {
                NpcBhvrQueueIndexClear(oArea, oRegistered);
            }

            DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueRingLogicalToSlot(oArea, nPriority, nIndex)));
            nIndex = nIndex + 1;
        }

        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, 0);
        DeleteLocalInt(oArea, NpcBhvrQueueHeadKey(nPriority));
        DeleteLocalInt(oArea, NpcBhvrQueueTailKey(nPriority));
        DeleteLocalInt(oArea, NpcBhvrQueueCountKey(nPriority));
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

    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_CURSOR, NPC_BHVR_PRIORITY_HIGH);
    SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEFERRED_TOTAL, 0);
    SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, 0);
    NpcBhvrRegistryResetIdleCursor(oArea);
    SetLocalInt(oArea, NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG, FALSE);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_DEPTH, 0);
    NpcBhvrSetLocalIntIfChanged(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL, 0);
}


int NpcBhvrQueueAppendSubject(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nTail;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueHeadKey(nPriority), 1);
        nTail = 1;
    }
    else
    {
        nTail = NpcBhvrQueueRingNextSlot(GetLocalInt(oArea, NpcBhvrQueueTailKey(nPriority)));
    }

    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nTail), oSubject);
    NpcBhvrQueueIndexSet(oArea, oSubject, nPriority, nTail);
    NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueTailKey(nPriority), nTail);
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth + 1);
    NpcBhvrQueueApplyTotalsDelta(oArea, 1);
    return TRUE;
}

object NpcBhvrQueueSwapTailSubject(object oArea, int nPriority, int nIndex, int bClearRemovedIndex)
{
    object oRemoved;

    oRemoved = NpcBhvrQueueRemoveSwapTail(oArea, nPriority, nIndex);
    if (bClearRemovedIndex && GetIsObjectValid(oRemoved))
    {
        NpcBhvrQueueIndexClear(oArea, oRemoved);
    }
    return oRemoved;
}

int NpcBhvrQueueFindSubjectByPointChecks(object oArea, object oSubject, int nPriorityHint, int nPositionHint)
{
    int nDepth;
    int nSlot;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return 0;
    }

    if (nPriorityHint < NPC_BHVR_PRIORITY_CRITICAL || nPriorityHint > NPC_BHVR_PRIORITY_LOW || nPositionHint <= 0 || nPositionHint > NPC_BHVR_QUEUE_MAX)
    {
        return 0;
    }

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriorityHint);
    if (nDepth <= 0)
    {
        return 0;
    }

    nSlot = nPositionHint;
    if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriorityHint, nSlot)) == oSubject)
    {
        return nPriorityHint * 1000 + nSlot;
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
            if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, NpcBhvrQueueRingLogicalToSlot(oArea, nExistingPriority, nIndex))) == oSubject)
            {
                return nExistingPriority * 1000 + NpcBhvrQueueRingLogicalToSlot(oArea, nExistingPriority, nIndex);
            }

            nIndex = nIndex + 1;
        }

        nExistingPriority = nExistingPriority + 1;
    }

    return 0;
}

void NpcBhvrQueuePurgeSubject(object oArea, object oSubject)
{
    int nFound;
    int nFoundPriority;
    int nFoundIndex;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oSubject);
    while (nFound == 0)
    {
        nFound = NpcBhvrQueueFindSubjectSlowPath(oArea, oSubject);
        if (nFound == 0)
        {
            break;
        }

        nFoundPriority = nFound / 1000;
        nFoundIndex = nFound - nFoundPriority * 1000;
        NpcBhvrQueueSwapTailSubject(oArea, nFoundPriority, nFoundIndex, TRUE);
        nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oSubject);
    }

    while (nFound != 0)
    {
        nFoundPriority = nFound / 1000;
        nFoundIndex = nFound - nFoundPriority * 1000;
        NpcBhvrQueueSwapTailSubject(oArea, nFoundPriority, nFoundIndex, TRUE);
        nFound = NpcBhvrQueueTryResolveIndexedSubject(oArea, oSubject);
    }
}

void NpcBhvrQueuePostUpdateQueuedAt(object oArea, object oSubject, int nPriority, int nReasonCode, int bStatusOnlyIfPending, int nNow)
{
    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    if (bStatusOnlyIfPending && NpcBhvrPendingIsActive(oSubject))
    {
        NpcBhvrPendingSetStatusTrackedAt(oArea, oSubject, NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    }
    else
    {
        NpcBhvrPendingSetTrackedAtIntReason(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    }
}

int NpcBhvrQueueCoalesceSubjectAt(object oArea, object oSubject, int nFoundPriority, int nFoundIndex, int nRequestedPriority, int nReasonCode, int bWasPendingActive, int nNow)
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

    NpcBhvrQueuePostUpdateQueuedAt(oArea, oSubject, nEscalatedPriority, nReasonCode, bWasPendingActive, nNow);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT);
    return TRUE;
}

void NpcBhvrQueueMarkDroppedOnEnqueueFailure(object oArea, object oSubject, int nPriority, int nReasonCode, int nNow)
{
    NpcBhvrPendingAreaTouchAt(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED, nNow);
    NpcBhvrPendingSetTrackedAtIntReason(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED, nNow);
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
        // Fallback: normalize out-of-range input priority to NORMAL.
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
        return NpcBhvrQueueCoalesceSubjectAt(oArea, oSubject, nFoundPriority, nFoundIndex, nPriority, nReasonCode, bWasPendingActive, nNow);
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
    NpcBhvrPendingSetTrackedAtIntReason(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED, nNow);
    NpcSqliteWriteBehindMarkDirty();
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_ENQUEUED_COUNT);
    return TRUE;
}

object NpcBhvrQueueDequeueFromPriority(object oArea, int nPriority)
{
    int nDepth;
    int nHead;
    object oSubject;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return OBJECT_INVALID;
    }

    nHead = GetLocalInt(oArea, NpcBhvrQueueHeadKey(nPriority));
    if (nHead < 1 || nHead > NPC_BHVR_QUEUE_MAX)
    {
        nHead = 1;
    }

    oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nHead));
    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nHead));
    if (GetIsObjectValid(oSubject))
    {
        NpcBhvrQueueIndexClear(oArea, oSubject);
    }

    if (nDepth == 1)
    {
        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, 0);
    }
    else
    {
        NpcBhvrSetLocalIntIfChanged(oArea, NpcBhvrQueueHeadKey(nPriority), NpcBhvrQueueRingNextSlot(nHead));
        NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    }

    NpcBhvrQueueApplyTotalsDelta(oArea, -1);
    return oSubject;
}

object NpcBhvrQueuePeekFromPriority(object oArea, int nPriority)
{
    if (NpcBhvrQueueGetDepthForPriority(oArea, nPriority) <= 0)
    {
        return OBJECT_INVALID;
    }

    return GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueRingLogicalToSlot(oArea, nPriority, 1)));
}

int NpcBhvrQueueDropTailFromPriorityAt(object oArea, int nPriority, int nNow)
{
    int nDepth;
    object oDropped;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return FALSE;
    }

    oDropped = NpcBhvrQueueRemoveSwapTail(oArea, nPriority, GetLocalInt(oArea, NpcBhvrQueueTailKey(nPriority)));

    if (GetIsObjectValid(oDropped))
    {
        NpcBhvrPendingAreaTouchAt(oArea, oDropped, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DROPPED, nNow);
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
    int nNow;

    if (nIncomingPriority <= NPC_BHVR_PRIORITY_CRITICAL || nReasonCode == NPC_BHVR_REASON_DAMAGE)
    {
        return FALSE;
    }

    nNow = NpcBhvrPendingNow();

    nPriority = NPC_BHVR_PRIORITY_LOW;
    while (nPriority >= nIncomingPriority)
    {
        if (NpcBhvrQueueDropTailFromPriorityAt(oArea, nPriority, nNow))
        {
            return TRUE;
        }

        nPriority = nPriority - 1;
    }

    return FALSE;
}
