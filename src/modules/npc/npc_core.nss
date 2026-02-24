// NPC Bhvr runtime core (preparation contour).
// Обязательные контракты:
// 1) lifecycle area-controller,
// 2) bounded queue + priority buckets,
// 3) единый вход в метрики через helper API.

#include "npc_activity_inc"
#include "npc_metrics_inc"

const int NPC_BHVR_AREA_STATE_STOPPED = 0;
const int NPC_BHVR_AREA_STATE_RUNNING = 1;
const int NPC_BHVR_AREA_STATE_PAUSED = 2;

const int NPC_BHVR_PRIORITY_CRITICAL = 0;
const int NPC_BHVR_PRIORITY_HIGH = 1;
const int NPC_BHVR_PRIORITY_NORMAL = 2;
const int NPC_BHVR_PRIORITY_LOW = 3;

const int NPC_BHVR_REASON_UNSPECIFIED = 0;
const int NPC_BHVR_REASON_PERCEPTION = 1;
const int NPC_BHVR_REASON_DAMAGE = 2;

const int NPC_BHVR_DEGRADATION_REASON_NONE = 0;
const int NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET = 1;
const int NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET = 2;
const int NPC_BHVR_DEGRADATION_REASON_EMPTY_QUEUE = 3;

const string NPC_BHVR_PENDING_STATUS_STR_QUEUED = "queued";
const string NPC_BHVR_PENDING_STATUS_STR_RUNNING = "running";
const string NPC_BHVR_PENDING_STATUS_STR_PROCESSED = "processed";
const string NPC_BHVR_PENDING_STATUS_STR_DEFERRED = "deferred";
const string NPC_BHVR_PENDING_STATUS_STR_DROPPED = "dropped";


const int NPC_BHVR_QUEUE_MAX = 64;
const int NPC_BHVR_REGISTRY_MAX = 100;
const int NPC_BHVR_STARVATION_STREAK_LIMIT = 3;
const int NPC_BHVR_TICK_MAX_EVENTS_DEFAULT = 4;
const int NPC_BHVR_TICK_SOFT_BUDGET_MS_DEFAULT = 25;
const int NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS = 8;
const int NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP = 64;
const int NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP = 1000;
const float NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC = 1.0;
const float NPC_BHVR_AREA_TICK_INTERVAL_PAUSED_WATCHDOG_SEC = 30.0;

const string NPC_BHVR_VAR_AREA_STATE = "npc_area_state";
const string NPC_BHVR_VAR_AREA_TIMER_RUNNING = "npc_area_timer_running";
const string NPC_BHVR_VAR_QUEUE_DEPTH = "npc_queue_depth";
const string NPC_BHVR_VAR_QUEUE_PENDING_TOTAL = "npc_queue_pending_total";
const string NPC_BHVR_VAR_QUEUE_CURSOR = "npc_queue_cursor";
const string NPC_BHVR_VAR_FAIRNESS_STREAK = "npc_fairness_streak";
const string NPC_BHVR_VAR_TICK_MAX_EVENTS = "npc_tick_max_events";
const string NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS = "npc_tick_soft_budget_ms";
const string NPC_BHVR_VAR_TICK_DEGRADED_MODE = "npc_tick_degraded_mode";
const string NPC_BHVR_VAR_TICK_DEGRADED_STREAK = "npc_tick_degraded_streak";
const string NPC_BHVR_VAR_TICK_DEGRADED_TOTAL = "npc_tick_degraded_total";
const string NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL = "npc_tick_budget_exceeded_total";
const string NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON = "npc_tick_last_degradation_reason";
const string NPC_BHVR_VAR_TICK_PROCESSED = "npc_tick_processed";
const string NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS = "npc_queue_backlog_age_ticks";
const string NPC_BHVR_VAR_REGISTRY_COUNT = "npc_registry_count";
const string NPC_BHVR_VAR_REGISTRY_PREFIX = "npc_registry_";
const string NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX = "npc_registry_index_";

const int NPC_BHVR_PENDING_STATUS_NONE = 0;
const int NPC_BHVR_PENDING_STATUS_QUEUED = 1;
const int NPC_BHVR_PENDING_STATUS_RUNNING = 2;
const int NPC_BHVR_PENDING_STATUS_PROCESSED = 3;
const int NPC_BHVR_PENDING_STATUS_DEFERRED = 4;
const int NPC_BHVR_PENDING_STATUS_DROPPED = 5;

const string NPC_BHVR_VAR_PENDING_PRIORITY = "npc_pending_priority";
const string NPC_BHVR_VAR_PENDING_REASON = "npc_pending_reason";
const string NPC_BHVR_VAR_PENDING_STATUS = "npc_pending_status";
const string NPC_BHVR_VAR_PENDING_UPDATED_AT = "npc_pending_updated_at";

string NpcBhvrQueueDepthKey(int nPriority);
string NpcBhvrQueueSubjectKey(int nPriority, int nIndex);
int NpcBhvrQueueGetDepthForPriority(object oArea, int nPriority);
void NpcBhvrQueueSetDepthForPriority(object oArea, int nPriority, int nDepth);
void NpcBhvrQueueSyncTotals(object oArea);
string NpcBhvrRegistrySlotKey(int nIndex);
string NpcBhvrRegistryIndexKey(object oNpc);
int NpcBhvrRegistryInsert(object oArea, object oNpc);
int NpcBhvrRegistryRemove(object oArea, object oNpc);
void NpcBhvrRegistryBroadcastIdleTick(object oArea);

int NpcBhvrPendingNow()
{
    return GetCalendarYear() * 1000000 + GetCalendarMonth() * 10000 + GetCalendarDay() * 100 + GetTimeHour();
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

void NpcBhvrPendingNpcTouch(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT, NpcBhvrPendingNow());
}

void NpcBhvrPendingSet(object oNpc, int nPriority, string sReason, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON, sReason);
    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS, nStatus);
    NpcBhvrPendingNpcTouch(oNpc);
}

void NpcBhvrPendingSetStatus(object oNpc, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS, nStatus);
    NpcBhvrPendingNpcTouch(oNpc);
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

    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
}

int NpcBhvrQueueFindSubjectIndex(object oArea, int nPriority, object oSubject)
{
    int nDepth;
    int nIndex;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    nIndex = 1;
    while (nIndex <= nDepth)
    {
        if (GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex)) == oSubject)
        {
            return nIndex;
        }
        nIndex = nIndex + 1;
    }

    return -1;
}

void NpcBhvrQueueRemoveAt(object oArea, int nPriority, int nIndex)
{
    int nDepth;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nIndex < 1 || nIndex > nDepth)
    {
        return;
    }

    while (nIndex < nDepth)
    {
        SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex + 1)));
        nIndex = nIndex + 1;
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
}

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
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth);
    NpcBhvrQueueSyncTotals(oArea);
    return TRUE;
}

int NpcBhvrQueueCoalescePriority(int nExistingPriority, int nIncomingPriority, string sReason)
{
    int nPriority;

    nPriority = nExistingPriority;
    if (nIncomingPriority < nPriority)
    {
        nPriority = nIncomingPriority;
    }

    if (sReason == "damage")
    {
        nPriority = NPC_BHVR_PRIORITY_CRITICAL;
    }

    return nPriority;
}

string NpcBhvrRegistrySlotKey(int nIndex)
{
    return NPC_BHVR_VAR_REGISTRY_PREFIX + IntToString(nIndex);
}

string NpcBhvrRegistryIndexKey(object oNpc)
{
    return NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX + NpcBhvrPendingSubjectTag(oNpc);
}

int NpcBhvrRegistryInsert(object oArea, object oNpc)
{
    int nCount;
    int nIndex;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc) || GetIsPC(oNpc) || GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    if (GetArea(oNpc) != oArea)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    if (nIndex > 0 && GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex)) == oNpc)
    {
        return TRUE;
    }

    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nCount >= NPC_BHVR_REGISTRY_MAX)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_OVERFLOW_TOTAL);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nCount = nCount + 1;
    SetLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount), oNpc);
    SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc), nCount);
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount);
    return TRUE;
}

int NpcBhvrRegistryRemove(object oArea, object oNpc)
{
    int nCount;
    int nIndex;
    object oTail;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nIndex <= 0 || nIndex > nCount)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    oTail = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
    if (nIndex != nCount)
    {
        SetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex), oTail);
        if (GetIsObjectValid(oTail))
        {
            SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oTail), nIndex);
        }
    }

    DeleteLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
    DeleteLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount - 1);
    return TRUE;
}

void NpcBhvrRegistryBroadcastIdleTick(object oArea)
{
    int nIndex;
    int nCount;
    object oNpc;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nIndex = 1;
    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    while (nIndex <= nCount)
    {
        oNpc = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        if (!GetIsObjectValid(oNpc) || GetArea(oNpc) != oArea)
        {
            NpcBhvrRegistryRemove(oArea, oNpc);
            nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
            continue;
        }

        NpcBhvrActivityOnIdleTick(oNpc);
        nIndex = nIndex + 1;
    }
}

string NpcBhvrQueueDepthKey(int nPriority)
{
    return "npc_queue_depth_" + IntToString(nPriority);
}

string NpcBhvrQueueSubjectKey(int nPriority, int nIndex)
{
    return "npc_queue_subject_" + IntToString(nPriority) + "_" + IntToString(nIndex);
}

string NpcBhvrPendingPriorityKey(string sNpcKey)
{
    return "npc_queue_pending_priority_" + sNpcKey;
}

string NpcBhvrPendingReasonCodeKey(string sNpcKey)
{
    return "npc_queue_pending_reason_" + sNpcKey;
}

string NpcBhvrPendingStatusKey(string sNpcKey)
{
    return "npc_queue_pending_status_" + sNpcKey;
}

string NpcBhvrPendingUpdatedAtKey(string sNpcKey)
{
    return "npc_queue_pending_updated_ts_" + sNpcKey;
}

string NpcBhvrPendingSubjectTag(object oSubject)
{
    string sTag;

    sTag = GetTag(oSubject);
    if (sTag == "")
    {
        sTag = "npc_" + GetName(oSubject);
    }

    return sTag;
}

int NpcBhvrPendingNowTs()
{
    return GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond();
}

void NpcBhvrPendingAreaTouch(object oArea, object oSubject, int nPriority, int nReasonCode, int nStatus)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    SetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nPriority);
    SetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nReasonCode);
    SetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey), NpcBhvrPendingStatusToString(nStatus));
    SetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), NpcBhvrPendingNowTs());
}

void NpcBhvrPendingAreaClear(object oArea, object oSubject)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = NpcBhvrPendingSubjectTag(oSubject);
    DeleteLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey));
    DeleteLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey));
    DeleteLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey));
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
    SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, 0);
    NpcBhvrQueueSyncTotals(oArea);
}

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

    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_RUNNING);

    // Contract: один area-loop на область.
    if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING) != TRUE)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, TRUE);
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC, ExecuteScript("npc_area_tick", oArea));
    }
}

void NpcBhvrAreaPause(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Pause only toggles lifecycle state; queue/pending counters remain untouched.
    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_PAUSED);
}

void NpcBhvrAreaStop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrAreaSetState(oArea, NPC_BHVR_AREA_STATE_STOPPED);
    NpcBhvrQueueClear(oArea);
}

int NpcBhvrQueueEnqueue(object oArea, object oSubject, int nPriority, int nReasonCode)
{
    int nDepth;
    int nTotal;
    int nIndex;
    int nExistingPriority;
    int nEscalatedPriority;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nPriority = NPC_BHVR_PRIORITY_NORMAL;
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
                SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex), GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority))));
                DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority)));
                NpcBhvrQueueSetDepthForPriority(oArea, nPriority, NpcBhvrQueueGetDepthForPriority(oArea, nPriority) - 1);

                nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                NpcBhvrQueueSyncTotals(oArea);
            }

            NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
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
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nIndex), GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth)));
                    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth));
                    NpcBhvrQueueSetDepthForPriority(oArea, nExistingPriority, nDepth - 1);

                    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                    NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSyncTotals(oArea);
                }

                NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
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
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
        NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingAreaClear(oArea, oSubject);
        return FALSE;
    }

    if (!NpcBhvrQueueEnqueueRaw(oArea, oSubject, nPriority))
    {
        NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingAreaClear(oArea, oSubject);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
        return FALSE;
    }

    NpcBhvrQueueSyncTotals(oArea);
    NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_ENQUEUED_COUNT);
    return TRUE;
}

object NpcBhvrQueueDequeueFromPriority(object oArea, int nPriority)
{
    int nDepth;
    int nIndex;
    object oSubject;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return OBJECT_INVALID;
    }

    oSubject = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, 1));

    nIndex = 1;
    while (nIndex < nDepth)
    {
        SetLocalObject(
            oArea,
            NpcBhvrQueueSubjectKey(nPriority, nIndex),
            GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nIndex + 1))
        );
        nIndex = nIndex + 1;
    }

    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
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
            NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DEFERRED);
            return;
        }

        nPriority = nPriority + 1;
    }
}

int NpcBhvrCountPlayersInArea(object oArea)
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
        if (GetIsPC(oIter) && !GetIsDM(oIter))
        {
            nPlayers = nPlayers + 1;
        }
        oIter = GetNextObjectInArea(oArea);
    }

    return nPlayers;
}

int NpcBhvrCountPlayersInAreaExcluding(object oArea, object oExclude)
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
        SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
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
            SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_CURSOR, nPriority);
            SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, nStreak + 1);
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

int NpcBhvrQueueProcessOne(object oArea)
{
    int nTotalDepth;
    int nPriority;
    object oSubject;

    if (!GetIsObjectValid(oArea) || !NpcBhvrAreaIsRunning(oArea))
    {
        return FALSE;
    }

    nTotalDepth = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_DEPTH);
    if (nTotalDepth <= 0)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_FAIRNESS_STREAK, 0);
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
        return TRUE;
    }

    NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_RUNNING);

    if (GetArea(oSubject) != oArea)
    {
        NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_DEFERRED);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT);
        NpcBhvrPendingNpcClear(oSubject);
        return TRUE;
    }

    NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_RUNNING);
    NpcBhvrActivityOnIdleTick(oSubject);
    if (GetIsObjectValid(oSubject))
    {
        NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_PROCESSED);
        NpcBhvrPendingNpcClear(oSubject);
        return TRUE;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
    return TRUE;
}


void NpcBhvrRecordDegradationReason(object oArea, int nReason)
{
    SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, nReason);

    if (nReason == NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_BY_REASON_EVENT_BUDGET_TOTAL);
        return;
    }

    if (nReason == NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_BY_REASON_SOFT_BUDGET_TOTAL);
        return;
    }

    if (nReason == NPC_BHVR_DEGRADATION_REASON_EMPTY_QUEUE)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_BY_REASON_EMPTY_QUEUE_TOTAL);
        return;
    }

    if (nReason != NPC_BHVR_DEGRADATION_REASON_NONE)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DIAGNOSTIC_DROPPED_TOTAL);
    }
}

void NpcBhvrOnAreaTick(object oArea)
{
    int nPlayers;
    int nProcessedThisTick;
    int nPendingAfter;
    int nSoftBudgetMs;
    int nBudgetExceeded;
    int nMaxEvents;
    int nEventsBudgetLeft;
    int nSpentBudgetMs;
    int nSpentEvents;
    int nEventBudgetReached;
    int nSoftBudgetReached;
    int nBacklogAgeTicks;
    int nPendingBefore;
    int nDegradationReason;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_STOPPED)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
        return;
    }

    if (NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_RUNNING)
    {
        nPendingBefore = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);
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

        nSpentEvents = 0;
        nSpentBudgetMs = 0;
        nDegradationReason = NPC_BHVR_DEGRADATION_REASON_NONE;
        while (TRUE)
        {
            nEventsBudgetLeft = nMaxEvents - nSpentEvents;
            if (nEventsBudgetLeft <= 0)
            {
                nEventBudgetReached = TRUE;
                nDegradationReason = NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET;
                break;
            }

            if (nSpentBudgetMs + NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS > nSoftBudgetMs)
            {
                nSoftBudgetReached = TRUE;
                nDegradationReason = NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET;
                break;
            }

            if (!NpcBhvrQueueProcessOne(oArea))
            {
                if (GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL) > 0)
                {
                    nDegradationReason = NPC_BHVR_DEGRADATION_REASON_EMPTY_QUEUE;
                }
                break;
            }

            nSpentEvents = nSpentEvents + 1;
            nSpentBudgetMs = nSpentBudgetMs + NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS;
        }

        nProcessedThisTick = nSpentEvents;

        SetLocalInt(oArea, NPC_BHVR_VAR_TICK_PROCESSED, nProcessedThisTick);
        NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_PROCESSED_TOTAL, nProcessedThisTick);
        nPendingAfter = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);

        // Deterministic tail-carryover: unprocessed queue head remains in-order and is drained on next ticks.
        nBudgetExceeded = (nSoftBudgetReached || nEventBudgetReached) && nPendingBefore > nProcessedThisTick && nPendingAfter > 0;
        SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_MODE, nBudgetExceeded);

        if (nBudgetExceeded)
        {
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_TICK_BUDGET_EXCEEDED_TOTAL);
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADED_MODE_TOTAL);
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_EVENTS_TOTAL);
            NpcBhvrRecordDegradationReason(oArea, nDegradationReason);
            NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT);
            NpcBhvrQueueMarkDeferredHead(oArea);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK) + 1);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL) + 1);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL) + 1);
        }
        else
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, 0);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, NPC_BHVR_DEGRADATION_REASON_NONE);
        }

        if (nPendingAfter > 0)
        {
            nBacklogAgeTicks = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS) + 1;
            SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS, nBacklogAgeTicks);
            NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_PENDING_AGE_MS, nPendingAfter * 1000);
        }
        else
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS, 0);
        }

        // Auto-idle-stop: если в области нет игроков и нет pending, останавливаем loop.
        nPlayers = NpcBhvrCountPlayersInArea(oArea);
        if (nPlayers <= 0 && nPendingAfter <= 0)
        {
            NpcBhvrAreaStop(oArea);
        }
    }

    if (NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_RUNNING)
    {
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC, ExecuteScript("npc_area_tick", oArea));
        return;
    }

    if (NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_PAUSED)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_PAUSED_WATCHDOG_TICK_COUNT);
        DelayCommand(NPC_BHVR_AREA_TICK_INTERVAL_PAUSED_WATCHDOG_SEC, ExecuteScript("npc_area_tick", oArea));
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
}

void NpcBhvrBootstrapModuleAreas()
{
    object oArea;

    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        if (GetLocalInt(oArea, NPC_BHVR_VAR_AREA_STATE) == NPC_BHVR_AREA_STATE_RUNNING)
        {
            NpcBhvrAreaActivate(oArea);
        }
        oArea = GetNextArea();
    }
}

void NpcBhvrOnSpawn(object oNpc)
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

void NpcBhvrOnPerception(object oNpc)
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

void NpcBhvrOnDamaged(object oNpc)
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

void NpcBhvrOnDeath(object oNpc)
{
    object oArea;

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DEATH_COUNT);
    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        NpcBhvrRegistryRemove(oArea, oNpc);
    }
}

void NpcBhvrOnDialogue(object oNpc)
{
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DIALOGUE_COUNT);
}

void NpcBhvrOnAreaEnter(object oArea, object oEntering)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEntering))
    {
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_ENTER_COUNT);
    if (!GetIsPC(oEntering))
    {
        NpcBhvrRegistryInsert(oArea, oEntering);
        return;
    }

    if (!NpcBhvrAreaIsRunning(oArea))
    {
        NpcBhvrAreaActivate(oArea);
    }
}

void NpcBhvrOnAreaExit(object oArea, object oExiting)
{
    int nPlayers;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oExiting))
    {
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_EXIT_COUNT);

    if (!GetIsPC(oExiting))
    {
        NpcBhvrRegistryRemove(oArea, oExiting);
        return;
    }

    // Порядок событий движка: OnExit может сработать до фактического удаления oExiting
    // из area-итерации, поэтому при подсчёте исключаем выходящий объект явно.
    nPlayers = NpcBhvrCountPlayersInAreaExcluding(oArea, oExiting);
    if (nPlayers <= 0)
    {
        NpcBhvrAreaPause(oArea);
    }
}

void NpcBhvrOnModuleLoad()
{
    NpcBhvrMetricInc(GetModule(), NPC_BHVR_METRIC_MODULE_LOAD_COUNT);
    NpcBhvrBootstrapModuleAreas();
}
