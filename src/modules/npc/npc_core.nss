// NPC Bhvr runtime core (preparation contour).
// Обязательные контракты:
// 1) lifecycle area-controller,
// 2) bounded queue + priority buckets,
// 3) единый вход в метрики через helper API.

#include "npc_metrics_inc"
#include "npc_activity_inc"
#include "npc_sqlite_api_inc"
#include "npc_writebehind_inc"

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
const int NPC_BHVR_DEGRADATION_REASON_OVERFLOW = 4;
const int NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE = 5;
const int NPC_BHVR_DEGRADATION_REASON_ROUTE_MISS = 6;
const int NPC_BHVR_DEGRADATION_REASON_DISABLED = 7;

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
const int NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS = 4;
const int NPC_BHVR_TICK_DEFERRED_CAP = 16;
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
const string NPC_BHVR_CFG_TICK_MAX_EVENTS = "npc_cfg_tick_max_events";
const string NPC_BHVR_CFG_TICK_SOFT_BUDGET_MS = "npc_cfg_tick_soft_budget_ms";
const string NPC_BHVR_VAR_TICK_DEGRADED_MODE = "npc_tick_degraded_mode";
const string NPC_BHVR_VAR_TICK_DEGRADED_STREAK = "npc_tick_degraded_streak";
const string NPC_BHVR_VAR_TICK_DEGRADED_TOTAL = "npc_tick_degraded_total";
const string NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL = "npc_tick_budget_exceeded_total";
const string NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON = "npc_tick_last_degradation_reason";
const string NPC_BHVR_VAR_TICK_PROCESSED = "npc_tick_processed";
const string NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS = "npc_queue_backlog_age_ticks";
const string NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS = "npc_tick_carryover_events";
const string NPC_BHVR_VAR_REGISTRY_COUNT = "npc_registry_count";
const string NPC_BHVR_VAR_REGISTRY_PREFIX = "npc_registry_";
const string NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX = "npc_registry_index_";
const string NPC_BHVR_VAR_NPC_UID = "npc_uid";
const string NPC_BHVR_VAR_NPC_UID_COUNTER = "npc_uid_counter";
const int NPC_BHVR_PENDING_STATUS_QUEUED = 1;
const int NPC_BHVR_PENDING_STATUS_RUNNING = 2;
const int NPC_BHVR_PENDING_STATUS_PROCESSED = 3;
const int NPC_BHVR_PENDING_STATUS_DEFERRED = 4;
const int NPC_BHVR_PENDING_STATUS_DROPPED = 5;

const string NPC_BHVR_VAR_PENDING_PRIORITY = "npc_pending_priority";
const string NPC_BHVR_VAR_PENDING_REASON = "npc_pending_reason";
const string NPC_BHVR_VAR_PENDING_STATUS = "npc_pending_status";
const string NPC_BHVR_VAR_PENDING_UPDATED_AT = "npc_pending_updated_at";

// Internal helper API (forward declarations).
// Актуальный публичный набор внутренних helper-функций деградации/очереди:
// NpcBhvrRecordDegradationEvent, NpcBhvrQueueDropTailFromPriority,
// NpcBhvrQueueApplyOverflowGuardrail, NpcBhvrQueueCountDeferred,
// NpcBhvrQueueTrimDeferredOverflow.
string NpcBhvrQueueDepthKey(int nPriority);
string NpcBhvrQueueSubjectKey(int nPriority, int nIndex);
int NpcBhvrQueueGetDepthForPriority(object oArea, int nPriority);
void NpcBhvrQueueSetDepthForPriority(object oArea, int nPriority, int nDepth);
void NpcBhvrQueueSyncTotals(object oArea);
string NpcBhvrRegistrySlotKey(int nIndex);
string NpcBhvrRegistryIndexKey(object oNpc);
string NpcBhvrRegistryLegacyIndexKey(object oNpc);
int NpcBhvrRegistryGetIndex(object oArea, object oNpc);
string NpcBhvrPendingLegacySubjectTag(object oSubject);
string NpcBhvrPendingPriorityLegacyKey(string sNpcKey);
string NpcBhvrPendingReasonCodeLegacyKey(string sNpcKey);
string NpcBhvrPendingStatusLegacyKey(string sNpcKey);
string NpcBhvrPendingUpdatedAtLegacyKey(string sNpcKey);
void NpcBhvrPendingAreaMigrateLegacy(object oArea, object oSubject, string sNpcKey);
int NpcBhvrRegistryInsert(object oArea, object oNpc);
int NpcBhvrRegistryRemove(object oArea, object oNpc);
void NpcBhvrRegistryBroadcastIdleTick(object oArea);
void NpcBhvrRecordDegradationEvent(object oArea, int nReason);
int NpcBhvrQueueDropTailFromPriority(object oArea, int nPriority);
int NpcBhvrQueueApplyOverflowGuardrail(object oArea, int nIncomingPriority, int nReasonCode);
int NpcBhvrQueueCountDeferred(object oArea);
int NpcBhvrQueueTrimDeferredOverflow(object oArea, int nTrimCount);

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
    // never as part of non-terminal deferred transitions.
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_PRIORITY);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_PENDING_REASON);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_STATUS);
    DeleteLocalInt(oNpc, NPC_BHVR_VAR_PENDING_UPDATED_AT);
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

string NpcBhvrRegistrySlotKey(int nIndex)
{
    return NPC_BHVR_VAR_REGISTRY_PREFIX + IntToString(nIndex);
}

string NpcBhvrRegistryIndexKey(object oNpc)
{
    return NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX + NpcBhvrPendingSubjectTag(oNpc);
}

string NpcBhvrRegistryLegacyIndexKey(object oNpc)
{
    return NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX + NpcBhvrPendingLegacySubjectTag(oNpc);
}

int NpcBhvrRegistryGetIndex(object oArea, object oNpc)
{
    int nIndex;

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    if (nIndex > 0)
    {
        return nIndex;
    }

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryLegacyIndexKey(oNpc));
    if (nIndex > 0)
    {
        SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc), nIndex);
        DeleteLocalInt(oArea, NpcBhvrRegistryLegacyIndexKey(oNpc));
    }

    return nIndex;
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

    nIndex = NpcBhvrRegistryGetIndex(oArea, oNpc);
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

    nIndex = NpcBhvrRegistryGetIndex(oArea, oNpc);
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
    object oTail;
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
            // NpcBhvrRegistryRemove requires valid oNpc and cannot be used with OBJECT_INVALID.
            if (GetIsObjectValid(oNpc))
            {
                NpcBhvrRegistryRemove(oArea, oNpc);
            }
            else
            {
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
                SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount - 1);
            }

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
    // deferred state implicitly.
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
    NpcBhvrAreaRouteCacheInvalidate(oArea);
    NpcBhvrQueueClear(oArea);
}

int NpcBhvrQueueEnqueue(object oArea, object oSubject, int nPriority, int nReasonCode)
{
    int nDepth;
    int nTotal;
    int nIndex;
    int nExistingPriority;
    int nEscalatedPriority;
    int bWasPendingActive;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    if (nPriority < NPC_BHVR_PRIORITY_CRITICAL || nPriority > NPC_BHVR_PRIORITY_LOW)
    {
        nPriority = NPC_BHVR_PRIORITY_NORMAL;
    }

    bWasPendingActive = NpcBhvrPendingIsActive(oSubject);

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
            if (bWasPendingActive)
            {
                NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
            }
            else
            {
                NpcBhvrPendingSet(oSubject, nEscalatedPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
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
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nIndex), GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth)));
                    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nExistingPriority, nDepth));
                    NpcBhvrQueueSetDepthForPriority(oArea, nExistingPriority, nDepth - 1);

                    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                    SetLocalObject(oArea, NpcBhvrQueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                    NpcBhvrQueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                    NpcBhvrQueueSyncTotals(oArea);
                }

                NpcBhvrPendingAreaTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
                if (bWasPendingActive)
                {
                    NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_QUEUED);
                }
                else
                {
                    NpcBhvrPendingSet(oSubject, nEscalatedPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
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
            NpcBhvrPendingSet(oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_DROPPED);
            NpcBhvrPendingNpcClear(oSubject);
            NpcBhvrPendingAreaClear(oArea, oSubject);
            return FALSE;
        }
    }

    if (!NpcBhvrQueueEnqueueRaw(oArea, oSubject, nPriority))
    {
        NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingSet(oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_DROPPED);
        NpcBhvrPendingNpcClear(oSubject);
        NpcBhvrPendingAreaClear(oArea, oSubject);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
        NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_OVERFLOW);
        return FALSE;
    }

    NpcBhvrQueueSyncTotals(oArea);
    NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, nReasonCode, NPC_BHVR_PENDING_STATUS_QUEUED);
    NpcBhvrPendingSet(oSubject, nPriority, IntToString(nReasonCode), NPC_BHVR_PENDING_STATUS_QUEUED);
    NpcSqliteWriteBehindMarkDirty();
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

int NpcBhvrQueueDropTailFromPriority(object oArea, int nPriority)
{
    int nDepth;
    object oDropped;

    nDepth = NpcBhvrQueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return FALSE;
    }

    oDropped = GetLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    DeleteLocalObject(oArea, NpcBhvrQueueSubjectKey(nPriority, nDepth));
    NpcBhvrQueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    NpcBhvrQueueSyncTotals(oArea);

    if (GetIsObjectValid(oDropped))
    {
        NpcBhvrPendingAreaTouch(oArea, oDropped, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DROPPED);
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
                NpcBhvrQueueRemoveAt(oArea, nPriority, nIndex);
                NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DROPPED);
                NpcBhvrPendingAreaClear(oArea, oSubject);
                NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT);
                NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE);
                nTrimmed = nTrimmed + 1;
            }

            nIndex = nIndex - 1;
        }

        nPriority = nPriority - 1;
    }

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

int NpcBhvrQueueProcessOne(object oArea)
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
        NpcBhvrRecordDegradationEvent(oArea, NPC_BHVR_DEGRADATION_REASON_ROUTE_MISS);
        return TRUE;
    }

    NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_RUNNING);

    if (GetArea(oSubject) != oArea)
    {
        NpcBhvrPendingSetStatus(oSubject, NPC_BHVR_PENDING_STATUS_DEFERRED);
        NpcBhvrPendingAreaTouch(oArea, oSubject, nPriority, NPC_BHVR_REASON_UNSPECIFIED, NPC_BHVR_PENDING_STATUS_DEFERRED);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT);
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



void NpcBhvrRecordDegradationEvent(object oArea, int nReason)
{
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_DEGRADATION_EVENTS_TOTAL);
    SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, nReason);
}

void NpcBhvrOnAreaTick(object oArea)
{
    int nAreaState;
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
    int nCarryoverEvents;
    int nDeferredCount;
    int nDeferredOverflow;
    int nDegradationReason;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nAreaState = NpcBhvrAreaGetState(oArea);

    if (nAreaState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_AREA_TIMER_RUNNING, FALSE);
        return;
    }

    if (nAreaState == NPC_BHVR_AREA_STATE_RUNNING)
    {
        nPendingBefore = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);
        if (nPendingBefore <= 0)
        {
            // Idle broadcast runs only when queue is empty: keeps ambient NPC activity alive
            // without competing with queued event processing budget.
            NpcBhvrRegistryBroadcastIdleTick(oArea);
        }

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

        nSpentEvents = 0;
        nSpentBudgetMs = 0;
        while (TRUE)
        {
            nEventsBudgetLeft = (nMaxEvents + nCarryoverEvents) - nSpentEvents;
            if (nEventsBudgetLeft <= 0)
            {
                nEventBudgetReached = TRUE;
                break;
            }

            if (nSpentBudgetMs + NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS > nSoftBudgetMs)
            {
                nSoftBudgetReached = TRUE;
                break;
            }

            if (!NpcBhvrQueueProcessOne(oArea))
            {
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
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK) + 1);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL) + 1);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL, GetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_TOTAL) + 1);
        }
        else
        {
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_DEGRADED_STREAK, 0);
            SetLocalInt(oArea, NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON, NPC_BHVR_DEGRADATION_REASON_NONE);
        }

        nDeferredCount = NpcBhvrQueueCountDeferred(oArea);
        if (nDeferredCount > NPC_BHVR_TICK_DEFERRED_CAP)
        {
            nDeferredOverflow = nDeferredCount - NPC_BHVR_TICK_DEFERRED_CAP;
            if (nDeferredOverflow > 0)
            {
                nDeferredOverflow = NpcBhvrQueueTrimDeferredOverflow(oArea, nDeferredOverflow);
                nPendingAfter = GetLocalInt(oArea, NPC_BHVR_VAR_QUEUE_PENDING_TOTAL);
                nCarryoverEvents = nCarryoverEvents - nDeferredOverflow;
                if (nCarryoverEvents < 0)
                {
                    nCarryoverEvents = 0;
                }
            }
        }

        SetLocalInt(oArea, NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS, nCarryoverEvents);

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

        if (NpcSqliteWriteBehindShouldFlush(NpcBhvrPendingNow(), NPC_SQLITE_WB_BATCH_SIZE_DEFAULT, NPC_SQLITE_WB_FLUSH_INTERVAL_SEC_DEFAULT))
        {
            NpcSqliteWriteBehindFlush(NpcBhvrPendingNow(), NPC_SQLITE_WB_BATCH_SIZE_DEFAULT);
        }

        // Auto-idle-stop: если в области нет игроков и нет pending, останавливаем loop.
        nPlayers = NpcBhvrCountPlayersInArea(oArea);
        if (nPlayers <= 0 && nPendingAfter <= 0)
        {
            NpcBhvrAreaStop(oArea);
        }
    }

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

void NpcBhvrBootstrapModuleAreas()
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
        NpcBhvrAreaRouteCacheInvalidate(oArea);
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
    NpcSqliteInit();
    NpcSqliteHealthcheck();
    NpcBhvrMetricInc(GetModule(), NPC_BHVR_METRIC_MODULE_LOAD_COUNT);
    NpcBhvrBootstrapModuleAreas();
}
