// NPC queue + pending/deferred internals.

void NpcBhvrRecordDegradationEvent(object oArea, int nReason);
int NpcBhvrAreaIsRunning(object oArea);
void NpcBhvrAreaActivate(object oArea);

int NpcBhvrPendingNow()
{
    int nYear;
    int nMonth;
    int nCalendarYear;
    int nCalendarDay;
    int nHour;
    int nMinute;
    int nSecond;
    int nDays;
    int bLeapYear;

    // Snapshot calendar/time components once to avoid rollover races while
    // building the pending timestamp (e.g. midnight/year transitions).
    nCalendarYear = GetCalendarYear();
    nMonth = GetCalendarMonth();
    nCalendarDay = GetCalendarDay();
    nHour = GetTimeHour();
    nMinute = GetTimeMinute();
    nSecond = GetTimeSecond();

    nYear = nCalendarYear - 2000;

    if (nYear < 0)
    {
        nYear = 0;
    }

    nDays = nYear * 365 + (nYear + 3) / 4 - (nYear + 99) / 100 + (nYear + 399) / 400;

    if (nMonth > 1)
    {
        nDays += 31;
    }
    if (nMonth > 2)
    {
        nDays += 28;
    }
    if (nMonth > 3)
    {
        nDays += 31;
    }
    if (nMonth > 4)
    {
        nDays += 30;
    }
    if (nMonth > 5)
    {
        nDays += 31;
    }
    if (nMonth > 6)
    {
        nDays += 30;
    }
    if (nMonth > 7)
    {
        nDays += 31;
    }
    if (nMonth > 8)
    {
        nDays += 31;
    }
    if (nMonth > 9)
    {
        nDays += 30;
    }
    if (nMonth > 10)
    {
        nDays += 31;
    }
    if (nMonth > 11)
    {
        nDays += 30;
    }

    bLeapYear = (nCalendarYear % 400 == 0) || (nCalendarYear % 4 == 0 && nCalendarYear % 100 != 0);
    if (bLeapYear && nMonth > 2)
    {
        nDays += 1;
    }

    nDays += nCalendarDay - 1;
    return nDays * 86400 + nHour * 3600 + nMinute * 60 + nSecond;
}

void NpcBhvrPendingNpcTouch(object oNpc)
{
    int nNow;
    int nPrev;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    nNow = NpcBhvrPendingNow();
    nPrev = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
    if (nNow <= nPrev)
    {
        nNow = nPrev + 1;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT, nNow);
}

void NpcBhvrPendingSetStatus(object oNpc, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // NPC-local pending status is authoritative for current NPC event-state and
    // must only be reset by explicit terminal clear-paths.
    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS, nStatus);
    NpcBhvrPendingNpcTouch(oNpc);
}

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

void NpcBhvrPendingSetStatusTracked(object oArea, object oNpc, int nStatus)
{
    int nPrevStatus;
    int nDeferredTotal;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    nPrevStatus = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    if (nPrevStatus == NPC_BHVR_PENDING_STATUS_DEFERRED && nStatus != NPC_BHVR_PENDING_STATUS_DEFERRED)
    {
        nDeferredTotal = NpcBhvrQueueGetDeferredTotal(oArea) - 1;
        NpcBhvrQueueSetDeferredTotal(oArea, nDeferredTotal);
    }
    else if (nPrevStatus != NPC_BHVR_PENDING_STATUS_DEFERRED && nStatus == NPC_BHVR_PENDING_STATUS_DEFERRED)
    {
        nDeferredTotal = NpcBhvrQueueGetDeferredTotal(oArea) + 1;
        NpcBhvrQueueSetDeferredTotal(oArea, nDeferredTotal);
    }

    NpcBhvrPendingSetStatus(oNpc, nStatus);
}

int NpcBhvrPendingIsActive(object oNpc)
{
    int nStatus;

    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    nStatus = GetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    return nStatus == NPC_BHVR_PENDING_STATUS_QUEUED
        || nStatus == NPC_BHVR_PENDING_STATUS_RUNNING
        || nStatus == NPC_BHVR_PENDING_STATUS_DEFERRED;
}

void NpcBhvrPendingSet(object oNpc, int nPriority, string sReason, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON, sReason);
    NpcBhvrPendingSetStatus(oNpc, nStatus);
}

void NpcBhvrPendingSetTracked(object oArea, object oNpc, int nPriority, string sReason, int nStatus)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON, sReason);
    NpcBhvrPendingSetStatusTracked(oArea, oNpc, nStatus);
}

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

string NpcBhvrQueueIndexKey(string sNpcKey)
{
    return "npc_q_idx_" + sNpcKey;
}

int NpcBhvrQueueIndexPriority(object oArea, object oSubject)
{
    string sNpcKey;
    int nPacked;

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return -1;
    }

    nPacked = GetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
    if (nPacked <= 0)
    {
        return -1;
    }

    return nPacked / 1000;
}

int NpcBhvrQueueIndexPosition(object oArea, object oSubject)
{
    string sNpcKey;
    int nPacked;

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return 0;
    }

    nPacked = GetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
    if (nPacked <= 0)
    {
        return 0;
    }

    return nPacked - (nPacked / 1000) * 1000;
}

void NpcBhvrQueueIndexClear(object oArea, object oSubject)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return;
    }

    DeleteLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey));
}

void NpcBhvrQueueIndexSet(object oArea, object oSubject, int nPriority, int nIndex)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject) || nIndex <= 0)
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    if (sNpcKey == "")
    {
        return;
    }

    SetLocalInt(oArea, NpcBhvrQueueIndexKey(sNpcKey), nPriority * 1000 + nIndex);
}

string NpcBhvrPendingPriorityKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pp_", sNpcKey);
}

string NpcBhvrPendingReasonCodeKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pr_", sNpcKey);
}

string NpcBhvrPendingStatusKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_ps_", sNpcKey);
}

string NpcBhvrPendingUpdatedAtKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pu_", sNpcKey);
}

string NpcBhvrPendingPriorityLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_priority_" + sNpcKey;
}

string NpcBhvrPendingReasonCodeLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_reason_" + sNpcKey;
}

string NpcBhvrPendingStatusLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_status_" + sNpcKey;
}

string NpcBhvrPendingUpdatedAtLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_updated_ts_" + sNpcKey;
}

string NpcBhvrPendingLegacySubjectTag(object oSubject)
{
    string sTag;

    sTag = GetTag(oSubject);
    if (sTag == "")
    {
        sTag = "npc_" + GetName(oSubject);
    }

    return sTag;
}

string NpcBhvrPendingSubjectTag(object oSubject)
{
    object oModule;
    int nCounter;
    string sUid;

    if (!GetIsObjectValid(oSubject))
    {
        return "";
    }

    sUid = GetLocalString(oSubject, NPC_BHVR_VAR_NPC_UID);
    if (sUid != "")
    {
        return sUid;
    }

    // Tag/Name aren't stable unique IDs: cloned NPCs in one area/module can share both values.
    oModule = GetModule();
    nCounter = GetLocalInt(oModule, NPC_BHVR_VAR_NPC_UID_COUNTER) + 1;
    SetLocalInt(oModule, NPC_BHVR_VAR_NPC_UID_COUNTER, nCounter);
    sUid = "npc_uid_" + IntToString(nCounter);
    SetLocalString(oSubject, NPC_BHVR_VAR_NPC_UID, sUid);
    return sUid;
}

void NpcBhvrPendingAreaMigrateLegacy(object oArea, object oSubject, string sNpcKey)
{
    string sLegacyKey;
    string sStatus;
    int nValue;

    sLegacyKey = NpcBhvrPendingLegacySubjectTag(oSubject);
    if (sLegacyKey == sNpcKey)
    {
        return;
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingPriorityLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingPriorityLegacyKey(sLegacyKey));
        }
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingReasonCodeLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingReasonCodeLegacyKey(sLegacyKey));
        }
    }

    sStatus = GetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey));
    if (sStatus == "")
    {
        sStatus = GetLocalString(oArea, NpcBhvrPendingStatusLegacyKey(sLegacyKey));
        if (sStatus != "")
        {
            SetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey), sStatus);
            DeleteLocalString(oArea, NpcBhvrPendingStatusLegacyKey(sLegacyKey));
        }
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingUpdatedAtLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingUpdatedAtLegacyKey(sLegacyKey));
        }
    }
}

void NpcBhvrPendingAreaTouch(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    // Area-local cache mirrors the last visible queue-state for diagnostics and
    // should stay consistent with NPC-local status transitions.
    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    NpcBhvrPendingAreaMigrateLegacy(oArea, oSubject, sNpcKey);
    SetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nPriority);
    SetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nReasonCode);
    SetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey), NpcBhvrPendingStatusToString(nStatus));
    SetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), NpcBhvrPendingNow());
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

int NpcBhvrQueueEnqueue(object oArea, object oSubject, int nPriority, int nReasonCode)
{
    int nDepth;
    int nTotal;
    int nIndex;
    int nExistingPriority;
    int nEscalatedPriority;
    int bWasPendingActive;
    int nIndexedPriority;
    int nIndexedPosition;
    object oIndexedSubject;
    object oTail;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nPriority = NPC_BHVR_PRIORITY_NORMAL;
    }

    bWasPendingActive = NpcBhvrPendingIsActive(oSubject);

    nIndexedPriority = NpcBhvrQueueIndexPriority(oArea, oSubject);
    nIndexedPosition = NpcBhvrQueueIndexPosition(oArea, oSubject);
    if (nIndexedPriority >= NPC_BHVR_PRIORITY_CRITICAL && nIndexedPriority <= NPC_BHVR_PRIORITY_LOW && nIndexedPosition > 0)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nIndexedPriority);
        if (nIndexedPosition <= nDepth)
        {
            oIndexedSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nIndexedPriority, nIndexedPosition));
            if (oIndexedSubject == oSubject)
            {
                NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_INDEX_HIT_TOTAL);
                nEscalatedPriority = NpcBhvrPriorityEscalate(nIndexedPriority, nPriority, nReasonCode);
                if (nEscalatedPriority != nIndexedPriority)
                {
                    oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nIndexedPriority, nDepth));
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nIndexedPriority, nIndexedPosition), oTail);
                    if (GetIsObjectValid(oTail))
                    {
                        NpcBhvrQueueIndexSet(oArea, oTail, nIndexedPriority, nIndexedPosition);
                    }
                    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nIndexedPriority, nDepth));
                    NpcBhvrQueueSetDepthForPriority(oArea, nIndexedPriority, nDepth - 1);

                    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                    NpcBhvrQueueIndexSet(oArea, oSubject, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSyncTotals(oArea);
                }

                NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
                if (bWasPendingActive)
                {
                    NpcBhvrPendingSetStatusTracked(oArea, oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
                }
                else
                {
                    NpcBhvrPendingSetTracked(oArea, oSubject, nEscalatedPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
                }
                NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT);
                return TRUE;
            }
        }

        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_INDEX_MISS_TOTAL);
        NpcBhvrQueueIndexClear(oArea, oSubject);
    }

    nIndex = 1;
    while (nIndex <= NpcBhvrQueueGetDepthForPriority(oArea, nPriority))
    {
        if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex)) == oSubject)
        {
            nEscalatedPriority = nPriority;
            nEscalatedPriority = NpcBhvrPriorityEscalate(nPriority, nPriority, nReasonCode);
            if (nEscalatedPriority != nPriority)
            {
                oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority)));
                SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), oTail);
                if (GetIsObjectValid(oTail))
                {
                    NpcBhvrQueueIndexSet(oArea, oTail, nPriority, nIndex);
                }
                DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority)));
                NpcBhvrQueueSetDepthForPriority(oArea, nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority) - 1);

                nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                NpcBhvrQueueIndexSet(oArea, oSubject, nEscalatedPriority, nDepth);
                NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                NpcBhvrQueueSyncTotals(oArea);
            }
            else
            {
                NpcBhvrQueueIndexSet(oArea, oSubject, nPriority, nIndex);
            }

            NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
            if (bWasPendingActive)
            {
                NpcBhvrPendingSetStatusTracked(oArea, oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
            }
            else
            {
                NpcBhvrPendingSetTracked(oArea, oSubject, nEscalatedPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
            }
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT);
            return TRUE;
        }
        nIndex = nIndex + 1;
    }

    nExistingPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nExistingPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nExistingPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nIndex)) == oSubject)
            {
                nEscalatedPriority = nExistingPriority;
                nEscalatedPriority = NpcBhvrPriorityEscalate(nExistingPriority, nPriority, nReasonCode);
                if (nEscalatedPriority != nExistingPriority)
                {
                    oTail = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth));
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nIndex), oTail);
                    if (GetIsObjectValid(oTail))
                    {
                        NpcBhvrQueueIndexSet(oArea, oTail, nExistingPriority, nIndex);
                    }
                    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth));
                    NpcBhvrQueueSetDepthForPriority(oArea, nExistingPriority, nDepth - 1);

                    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                    NpcBhvrQueueIndexSet(oArea, oSubject, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSyncTotals(oArea);
                }
                else
                {
                    NpcBhvrQueueIndexSet(oArea, oSubject, nExistingPriority, nIndex);
                }

                NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
                if (bWasPendingActive)
                {
                    NpcBhvrPendingSetStatusTracked(oArea, oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
                }
                else
                {
                    NpcBhvrPendingSetTracked(oArea, oSubject, nEscalatedPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
                }
                NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT);
                return TRUE;
            }
            nIndex = nIndex + 1;
        }

        nExistingPriority = nExistingPriority + 1;
    }

    nTotal = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotal >= NPC_BHVR_QUEUE_MAX)
    {
        if (!NpcBhvrQueueApplyOverflowGuardrail(oArea, nPriority, nReasonCode))
        {
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT);
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
            NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_OVERFLOW);
            NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED);
            NpcBhvrPendingSetTracked(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_DROPPED);
            NpcBhvrPendingNpcClear(oSubject);
            NpcBhvrPendingAreaClear(oArea, oSubject);
            NpcBhvrQueueIndexClear(oArea, oSubject);
            return FALSE;
        }
    }

    if (!NpcBhvrQueueEnqueueRaw(oArea, oSubject, nPriority))
    {
        NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingSetTracked(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingNpcClear(oSubject);
        NpcBhvrPendingAreaClear(oArea, oSubject);
        NpcBhvrQueueIndexClear(oArea, oSubject);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
        NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_OVERFLOW);
        return FALSE;
    }

    NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
    NpcBhvrPendingSetTracked(oArea, oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
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

int NpcBhvrQueueCountDeferred(object oArea)
{
    int nCount;
    int nPriority;
    int nDepth;
    int nIndex;
    object oSubject;

    nCount = 0;
    nPriority = NPC_BHVR_PRIORITY_CRITICAL;
    while (nPriority <= NPC_BHVR_PRIORITY_LOW)
    {
        nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
            if (GetIsObjectValid(oSubject) && GetLocalInt(oSubject, NPC_BHVR_VAR_PENDING_STATUS) == NPC_BHVR_PENDING_STATUS_DEFERRED)
            {
                nCount = nCount + 1;
            }

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
    int nIndex;
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
        nIndex = nDepth;
        while (nIndex >= 1 && nTrimmed < nTrimCount)
        {
            oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex));
            if (GetIsObjectValid(oSubject) && GetLocalInt(oSubject, NPC_BHVR_VAR_PENDING_STATUS) == NPC_BHVR_PENDING_STATUS_DEFERRED)
            {
                oSubject = NpcBhvrQueueRemoveSwapTail(oArea, nPriority, nIndex);
                NpcBhvrQueueSetDeferredTotal(oArea, NpcBhvrQueueGetDeferredTotal(oArea) - 1);
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

