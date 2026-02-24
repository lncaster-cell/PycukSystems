// Module 3 runtime core (preparation contour).
// Обязательные контракты:
// 1) lifecycle area-controller,
// 2) bounded queue + priority buckets,
// 3) единый вход в метрики через helper API.

#include "module3_activity_inc"
#include "module3_metrics_inc"

const int MODULE3_AREA_STATE_STOPPED = 0;
const int MODULE3_AREA_STATE_RUNNING = 1;
const int MODULE3_AREA_STATE_PAUSED = 2;

const int MODULE3_PRIORITY_CRITICAL = 0;
const int MODULE3_PRIORITY_HIGH = 1;
const int MODULE3_PRIORITY_NORMAL = 2;
const int MODULE3_PRIORITY_LOW = 3;

const int MODULE3_REASON_UNSPECIFIED = 0;
const int MODULE3_REASON_PERCEPTION = 1;
const int MODULE3_REASON_DAMAGE = 2;

const string MODULE3_PENDING_STATUS_QUEUED = "queued";
const string MODULE3_PENDING_STATUS_RUNNING = "running";
const string MODULE3_PENDING_STATUS_PROCESSED = "processed";
const string MODULE3_PENDING_STATUS_DEFERRED = "deferred";
const string MODULE3_PENDING_STATUS_DROPPED = "dropped";


const int MODULE3_QUEUE_MAX = 64;
const int MODULE3_STARVATION_STREAK_LIMIT = 3;
const int MODULE3_TICK_MAX_EVENTS_DEFAULT = 4;
const int MODULE3_TICK_SOFT_BUDGET_MS_DEFAULT = 25;
const int MODULE3_TICK_SIMULATED_EVENT_COST_MS = 8;
const int MODULE3_TICK_MAX_EVENTS_HARD_CAP = 64;
const int MODULE3_TICK_SOFT_BUDGET_MS_HARD_CAP = 1000;

const string MODULE3_VAR_AREA_STATE = "module3_area_state";
const string MODULE3_VAR_AREA_TIMER_RUNNING = "module3_area_timer_running";
const string MODULE3_VAR_QUEUE_DEPTH = "module3_queue_depth";
const string MODULE3_VAR_QUEUE_PENDING_TOTAL = "module3_queue_pending_total";
const string MODULE3_VAR_QUEUE_CURSOR = "module3_queue_cursor";
const string MODULE3_VAR_FAIRNESS_STREAK = "module3_fairness_streak";
const string MODULE3_VAR_TICK_MAX_EVENTS = "module3_tick_max_events";
const string MODULE3_VAR_TICK_SOFT_BUDGET_MS = "module3_tick_soft_budget_ms";
const string MODULE3_VAR_TICK_DEGRADED_MODE = "module3_tick_degraded_mode";
const string MODULE3_VAR_TICK_DEGRADED_STREAK = "module3_tick_degraded_streak";
const string MODULE3_VAR_TICK_PROCESSED = "module3_tick_processed";
const string MODULE3_VAR_QUEUE_BACKLOG_AGE_TICKS = "module3_queue_backlog_age_ticks";

const int MODULE3_PENDING_STATUS_NONE = 0;
const int MODULE3_PENDING_STATUS_QUEUED = 1;
const int MODULE3_PENDING_STATUS_RUNNING = 2;
const int MODULE3_PENDING_STATUS_PROCESSED = 3;
const int MODULE3_PENDING_STATUS_DEFERRED = 4;
const int MODULE3_PENDING_STATUS_DROPPED = 5;

const string MODULE3_VAR_PENDING_PRIORITY = "module3_pending_priority";
const string MODULE3_VAR_PENDING_REASON = "module3_pending_reason";
const string MODULE3_VAR_PENDING_STATUS = "module3_pending_status";
const string MODULE3_VAR_PENDING_UPDATED_AT = "module3_pending_updated_at";

string Module3QueueDepthKey(int nPriority);
string Module3QueueSubjectKey(int nPriority, int nIndex);
int Module3QueueGetDepthForPriority(object oArea, int nPriority);
void Module3QueueSetDepthForPriority(object oArea, int nPriority, int nDepth);
void Module3QueueSyncTotals(object oArea);

int Module3PendingNow()
{
    return GetCalendarYear() * 1000000 + GetCalendarMonth() * 10000 + GetCalendarDay() * 100 + GetTimeHour();
}

int Module3PendingIsActive(object oNpc)
{
    int nStatus;

    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    nStatus = GetLocalInt(oNpc, MODULE3_VAR_PENDING_STATUS);
    return nStatus == MODULE3_PENDING_STATUS_QUEUED
        || nStatus == MODULE3_PENDING_STATUS_RUNNING
        || nStatus == MODULE3_PENDING_STATUS_DEFERRED;
}

void Module3PendingTouch(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, MODULE3_VAR_PENDING_UPDATED_AT, Module3PendingNow());
}

void Module3PendingSet(object oNpc, int nPriority, string sReason, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, MODULE3_VAR_PENDING_PRIORITY, nPriority);
    SetLocalString(oNpc, MODULE3_VAR_PENDING_REASON, sReason);
    SetLocalInt(oNpc, MODULE3_VAR_PENDING_STATUS, nStatus);
    Module3PendingTouch(oNpc);
}

void Module3PendingSetStatus(object oNpc, int nStatus)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, MODULE3_VAR_PENDING_STATUS, nStatus);
    Module3PendingTouch(oNpc);
}

void Module3PendingClear(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    DeleteLocalInt(oNpc, MODULE3_VAR_PENDING_PRIORITY);
    DeleteLocalString(oNpc, MODULE3_VAR_PENDING_REASON);
    DeleteLocalInt(oNpc, MODULE3_VAR_PENDING_STATUS);
    DeleteLocalInt(oNpc, MODULE3_VAR_PENDING_UPDATED_AT);
}

int Module3QueueFindSubjectIndex(object oArea, int nPriority, object oSubject)
{
    int nDepth;
    int nIndex;

    nDepth = Module3QueueGetDepthForPriority(oArea, nPriority);
    nIndex = 1;
    while (nIndex <= nDepth)
    {
        if (GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex)) == oSubject)
        {
            return nIndex;
        }
        nIndex = nIndex + 1;
    }

    return -1;
}

void Module3QueueRemoveAt(object oArea, int nPriority, int nIndex)
{
    int nDepth;

    nDepth = Module3QueueGetDepthForPriority(oArea, nPriority);
    if (nIndex < 1 || nIndex > nDepth)
    {
        return;
    }

    while (nIndex < nDepth)
    {
        SetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex), GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex + 1)));
        nIndex = nIndex + 1;
    }

    DeleteLocalObject(oArea, Module3QueueSubjectKey(nPriority, nDepth));
    Module3QueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
}

int Module3QueueEnqueueRaw(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nTotal;

    nTotal = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nTotal >= MODULE3_QUEUE_MAX)
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_OVERFLOW_COUNT);
        return FALSE;
    }

    nDepth = Module3QueueGetDepthForPriority(oArea, nPriority) + 1;
    SetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nDepth), oSubject);
    Module3QueueSetDepthForPriority(oArea, nPriority, nDepth);
    Module3QueueSyncTotals(oArea);
    return TRUE;
}

int Module3QueueCoalescePriority(int nExistingPriority, int nIncomingPriority, string sReason)
{
    int nPriority;

    nPriority = nExistingPriority;
    if (nIncomingPriority < nPriority)
    {
        nPriority = nIncomingPriority;
    }

    if (sReason == "damage")
    {
        nPriority = MODULE3_PRIORITY_CRITICAL;
    }

    return nPriority;
}

string Module3QueueDepthKey(int nPriority)
{
    return "module3_queue_depth_" + IntToString(nPriority);
}

string Module3QueueSubjectKey(int nPriority, int nIndex)
{
    return "module3_queue_subject_" + IntToString(nPriority) + "_" + IntToString(nIndex);
}

string Module3PendingPriorityKey(string sNpcKey)
{
    return "module3_queue_pending_priority_" + sNpcKey;
}

string Module3PendingReasonCodeKey(string sNpcKey)
{
    return "module3_queue_pending_reason_" + sNpcKey;
}

string Module3PendingStatusKey(string sNpcKey)
{
    return "module3_queue_pending_status_" + sNpcKey;
}

string Module3PendingUpdatedAtKey(string sNpcKey)
{
    return "module3_queue_pending_updated_ts_" + sNpcKey;
}

string Module3PendingSubjectTag(object oSubject)
{
    string sTag;

    sTag = GetTag(oSubject);
    if (sTag == "")
    {
        sTag = "npc_" + GetName(oSubject);
    }

    return sTag;
}

int Module3PendingNowTs()
{
    return GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond();
}

void Module3PendingTouch(object oArea, object oSubject, int nPriority, int nReasonCode, string sStatus)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = Module3PendingSubjectTag(oSubject);
    SetLocalInt(oArea, Module3PendingPriorityKey(sNpcKey), nPriority);
    SetLocalInt(oArea, Module3PendingReasonCodeKey(sNpcKey), nReasonCode);
    SetLocalString(oArea, Module3PendingStatusKey(sNpcKey), sStatus);
    SetLocalInt(oArea, Module3PendingUpdatedAtKey(sNpcKey), Module3PendingNowTs());
}

void Module3PendingClear(object oArea, object oSubject)
{
    string sNpcKey;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return;
    }

    sNpcKey = Module3PendingSubjectTag(oSubject);
    DeleteLocalInt(oArea, Module3PendingPriorityKey(sNpcKey));
    DeleteLocalInt(oArea, Module3PendingReasonCodeKey(sNpcKey));
    DeleteLocalString(oArea, Module3PendingStatusKey(sNpcKey));
    DeleteLocalInt(oArea, Module3PendingUpdatedAtKey(sNpcKey));
}

int Module3PriorityEscalate(int nCurrentPriority, int nIncomingPriority, int nReasonCode)
{
    int nEscalated;

    if (nCurrentPriority < MODULE3_PRIORITY_CRITICAL || nCurrentPriority > MODULE3_PRIORITY_LOW)
    {
        nCurrentPriority = MODULE3_PRIORITY_NORMAL;
    }

    if (nIncomingPriority < MODULE3_PRIORITY_CRITICAL || nIncomingPriority > MODULE3_PRIORITY_LOW)
    {
        nIncomingPriority = MODULE3_PRIORITY_NORMAL;
    }

    nEscalated = nCurrentPriority;
    if (nIncomingPriority < nEscalated)
    {
        nEscalated = nIncomingPriority;
    }

    // Damage reason promotes pending work to CRITICAL (HIGH -> CRITICAL rule included).
    if (nReasonCode == MODULE3_REASON_DAMAGE && nEscalated > MODULE3_PRIORITY_CRITICAL)
    {
        nEscalated = MODULE3_PRIORITY_CRITICAL;
    }

    return nEscalated;
}

int Module3QueueGetDepthForPriority(object oArea, int nPriority)
{
    return GetLocalInt(oArea, Module3QueueDepthKey(nPriority));
}

void Module3QueueSetDepthForPriority(object oArea, int nPriority, int nDepth)
{
    SetLocalInt(oArea, Module3QueueDepthKey(nPriority), nDepth);
}

void Module3QueueSyncTotals(object oArea)
{
    int nTotal;

    nTotal = Module3QueueGetDepthForPriority(oArea, MODULE3_PRIORITY_CRITICAL)
        + Module3QueueGetDepthForPriority(oArea, MODULE3_PRIORITY_HIGH)
        + Module3QueueGetDepthForPriority(oArea, MODULE3_PRIORITY_NORMAL)
        + Module3QueueGetDepthForPriority(oArea, MODULE3_PRIORITY_LOW);

    SetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH, nTotal);
    SetLocalInt(oArea, MODULE3_VAR_QUEUE_PENDING_TOTAL, nTotal);
}

void Module3QueueClear(object oArea)
{
    int nPriority;
    int nDepth;
    int nIndex;

    nPriority = MODULE3_PRIORITY_CRITICAL;
    while (nPriority <= MODULE3_PRIORITY_LOW)
    {
        nDepth = Module3QueueGetDepthForPriority(oArea, nPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            DeleteLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex));
            nIndex = nIndex + 1;
        }

        Module3QueueSetDepthForPriority(oArea, nPriority, 0);
        nPriority = nPriority + 1;
    }

    SetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR, MODULE3_PRIORITY_HIGH);
    SetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK, 0);
    Module3QueueSyncTotals(oArea);
}

int Module3AreaGetState(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return MODULE3_AREA_STATE_STOPPED;
    }

    return GetLocalInt(oArea, MODULE3_VAR_AREA_STATE);
}

int Module3AreaIsRunning(object oArea)
{
    return Module3AreaGetState(oArea) == MODULE3_AREA_STATE_RUNNING;
}

void Module3AreaSetState(object oArea, int nState)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, MODULE3_VAR_AREA_STATE, nState);
}

void Module3AreaActivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    Module3AreaSetState(oArea, MODULE3_AREA_STATE_RUNNING);

    // Contract: один area-loop на область.
    if (GetLocalInt(oArea, MODULE3_VAR_AREA_TIMER_RUNNING) != TRUE)
    {
        SetLocalInt(oArea, MODULE3_VAR_AREA_TIMER_RUNNING, TRUE);
        DelayCommand(1.0, ExecuteScript("module3_behavior_area_tick", oArea));
    }
}

void Module3AreaPause(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // Pause only toggles lifecycle state; queue/pending counters remain untouched.
    Module3AreaSetState(oArea, MODULE3_AREA_STATE_PAUSED);
}

void Module3AreaStop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    Module3AreaSetState(oArea, MODULE3_AREA_STATE_STOPPED);
    Module3QueueClear(oArea);
}

int Module3QueueEnqueue(object oArea, object oSubject, int nPriority, int nReasonCode)
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

    if (nPriority < MODULE3_PRIORITY_CRITICAL || nPriority > MODULE3_PRIORITY_LOW)
    {
        nPriority = MODULE3_PRIORITY_NORMAL;
    }

    nIndex = 1;
    while (nIndex <= Module3QueueGetDepthForPriority(oArea, nPriority))
    {
        if (GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex)) == oSubject)
        {
            nEscalatedPriority = Module3PriorityEscalate(nPriority, nPriority, nReasonCode);
            if (nEscalatedPriority != nPriority)
            {
                SetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex), GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, Module3QueueGetDepthForPriority(oArea, nPriority))));
                DeleteLocalObject(oArea, Module3QueueSubjectKey(nPriority, Module3QueueGetDepthForPriority(oArea, nPriority)));
                Module3QueueSetDepthForPriority(oArea, nPriority, Module3QueueGetDepthForPriority(oArea, nPriority) - 1);

                nDepth = Module3QueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                SetLocalObject(oArea, Module3QueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                Module3QueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                Module3QueueSyncTotals(oArea);
            }

            Module3PendingTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, MODULE3_PENDING_STATUS_QUEUED);
            Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_COALESCED_COUNT);
            return TRUE;
        }
        nIndex = nIndex + 1;
    }

    nExistingPriority = MODULE3_PRIORITY_CRITICAL;
    while (nExistingPriority <= MODULE3_PRIORITY_LOW)
    {
        nDepth = Module3QueueGetDepthForPriority(oArea, nExistingPriority);
        nIndex = 1;
        while (nIndex <= nDepth)
        {
            if (GetLocalObject(oArea, Module3QueueSubjectKey(nExistingPriority, nIndex)) == oSubject)
            {
                nEscalatedPriority = Module3PriorityEscalate(nExistingPriority, nPriority, nReasonCode);
                if (nEscalatedPriority != nExistingPriority)
                {
                    SetLocalObject(oArea, Module3QueueSubjectKey(nExistingPriority, nIndex), GetLocalObject(oArea, Module3QueueSubjectKey(nExistingPriority, nDepth)));
                    DeleteLocalObject(oArea, Module3QueueSubjectKey(nExistingPriority, nDepth));
                    Module3QueueSetDepthForPriority(oArea, nExistingPriority, nDepth - 1);

                    nDepth = Module3QueueGetDepthForPriority(oArea, nEscalatedPriority) + 1;
                    SetLocalObject(oArea, Module3QueueSubjectKey(nEscalatedPriority, nDepth), oSubject);
                    Module3QueueSetDepthForPriority(oArea, nEscalatedPriority, nDepth);
                    Module3QueueSyncTotals(oArea);
                }

                Module3PendingTouch(oArea, oSubject, nEscalatedPriority, nReasonCode, MODULE3_PENDING_STATUS_QUEUED);
                Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_COALESCED_COUNT);
                return TRUE;
            }
            nIndex = nIndex + 1;
        }

        nExistingPriority = nExistingPriority + 1;
    }

    nTotal = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nTotal >= MODULE3_QUEUE_MAX)
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_OVERFLOW_COUNT);
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DROPPED_COUNT);
        Module3PendingTouch(oArea, oSubject, nPriority, nReasonCode, MODULE3_PENDING_STATUS_DROPPED);
        Module3PendingClear(oArea, oSubject);
        return FALSE;
    }

    if (!Module3QueueEnqueueRaw(oArea, oSubject, nPriority))
    {
        Module3PendingSet(oSubject, nPriority, sReason, MODULE3_PENDING_STATUS_DROPPED);
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DROPPED_COUNT);
        return FALSE;
    }

    Module3QueueSyncTotals(oArea);
    Module3PendingTouch(oArea, oSubject, nPriority, nReasonCode, MODULE3_PENDING_STATUS_QUEUED);
    Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_ENQUEUED_COUNT);
    return TRUE;
}

object Module3QueueDequeueFromPriority(object oArea, int nPriority)
{
    int nDepth;
    int nIndex;
    object oSubject;

    nDepth = Module3QueueGetDepthForPriority(oArea, nPriority);
    if (nDepth <= 0)
    {
        return OBJECT_INVALID;
    }

    oSubject = GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, 1));

    nIndex = 1;
    while (nIndex < nDepth)
    {
        SetLocalObject(
            oArea,
            Module3QueueSubjectKey(nPriority, nIndex),
            GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, nIndex + 1))
        );
        nIndex = nIndex + 1;
    }

    DeleteLocalObject(oArea, Module3QueueSubjectKey(nPriority, nDepth));
    Module3QueueSetDepthForPriority(oArea, nPriority, nDepth - 1);
    Module3QueueSyncTotals(oArea);
    return oSubject;
}

object Module3QueuePeekFromPriority(object oArea, int nPriority)
{
    if (Module3QueueGetDepthForPriority(oArea, nPriority) <= 0)
    {
        return OBJECT_INVALID;
    }

    return GetLocalObject(oArea, Module3QueueSubjectKey(nPriority, 1));
}

void Module3QueueMarkDeferredHead(object oArea)
{
    int nPriority;
    object oSubject;

    nPriority = MODULE3_PRIORITY_CRITICAL;
    while (nPriority <= MODULE3_PRIORITY_LOW)
    {
        oSubject = Module3QueuePeekFromPriority(oArea, nPriority);
        if (GetIsObjectValid(oSubject))
        {
            Module3PendingTouch(oArea, oSubject, nPriority, MODULE3_REASON_UNSPECIFIED, MODULE3_PENDING_STATUS_DEFERRED);
            return;
        }

        nPriority = nPriority + 1;
    }
}

int Module3CountPlayersInArea(object oArea)
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

int Module3QueuePickPriority(object oArea)
{
    int nCriticalDepth;
    int nCursor;
    int nStreak;
    int nPriority;
    int nAttempts;

    nCriticalDepth = Module3QueueGetDepthForPriority(oArea, MODULE3_PRIORITY_CRITICAL);
    if (nCriticalDepth > 0)
    {
        // CRITICAL bypasses fairness budget.
        SetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK, 0);
        return MODULE3_PRIORITY_CRITICAL;
    }

    nCursor = GetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR);
    if (nCursor < MODULE3_PRIORITY_HIGH || nCursor > MODULE3_PRIORITY_LOW)
    {
        nCursor = MODULE3_PRIORITY_HIGH;
    }

    nStreak = GetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK);

    if (nStreak >= MODULE3_STARVATION_STREAK_LIMIT)
    {
        nCursor = nCursor + 1;
        if (nCursor > MODULE3_PRIORITY_LOW)
        {
            nCursor = MODULE3_PRIORITY_HIGH;
        }
        nStreak = 0;
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_STARVATION_GUARD_TRIPS);
    }

    nPriority = nCursor;
    nAttempts = 0;
    while (nAttempts < 3)
    {
        if (Module3QueueGetDepthForPriority(oArea, nPriority) > 0)
        {
            SetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR, nPriority);
            SetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK, nStreak + 1);
            return nPriority;
        }

        nPriority = nPriority + 1;
        if (nPriority > MODULE3_PRIORITY_LOW)
        {
            nPriority = MODULE3_PRIORITY_HIGH;
        }
        nAttempts = nAttempts + 1;
    }

    return -1;
}

int Module3GetTickMaxEvents(object oArea)
{
    int nValue;

    nValue = GetLocalInt(oArea, MODULE3_VAR_TICK_MAX_EVENTS);
    if (nValue <= 0)
    {
        nValue = MODULE3_TICK_MAX_EVENTS_DEFAULT;
    }

    return nValue;
}

void Module3SetTickMaxEvents(object oArea, int nValue)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nValue <= 0)
    {
        nValue = MODULE3_TICK_MAX_EVENTS_DEFAULT;
    }

    if (nValue > MODULE3_TICK_MAX_EVENTS_HARD_CAP)
    {
        nValue = MODULE3_TICK_MAX_EVENTS_HARD_CAP;
    }

    SetLocalInt(oArea, MODULE3_VAR_TICK_MAX_EVENTS, nValue);
}

int Module3GetTickSoftBudgetMs(object oArea)
{
    int nValue;

    nValue = GetLocalInt(oArea, MODULE3_VAR_TICK_SOFT_BUDGET_MS);
    if (nValue <= 0)
    {
        nValue = MODULE3_TICK_SOFT_BUDGET_MS_DEFAULT;
    }

    return nValue;
}

void Module3SetTickSoftBudgetMs(object oArea, int nValue)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nValue <= 0)
    {
        nValue = MODULE3_TICK_SOFT_BUDGET_MS_DEFAULT;
    }

    if (nValue > MODULE3_TICK_SOFT_BUDGET_MS_HARD_CAP)
    {
        nValue = MODULE3_TICK_SOFT_BUDGET_MS_HARD_CAP;
    }

    SetLocalInt(oArea, MODULE3_VAR_TICK_SOFT_BUDGET_MS, nValue);
}

int Module3QueueProcessOne(object oArea)
{
    int nTotalDepth;
    int nPriority;
    object oSubject;

    if (!GetIsObjectValid(oArea) || !Module3AreaIsRunning(oArea))
    {
        return FALSE;
    }

    nTotalDepth = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nTotalDepth <= 0)
    {
        SetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK, 0);
        return FALSE;
    }

    nPriority = Module3QueuePickPriority(oArea);
    if (nPriority < MODULE3_PRIORITY_CRITICAL)
    {
        return FALSE;
    }

    oSubject = Module3QueueDequeueFromPriority(oArea, nPriority);
    if (!GetIsObjectValid(oSubject))
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DROPPED_COUNT);
        return TRUE;
    }

    Module3PendingSetStatus(oSubject, MODULE3_PENDING_STATUS_RUNNING);

    if (GetArea(oSubject) != oArea)
    {
        Module3PendingSetStatus(oSubject, MODULE3_PENDING_STATUS_DEFERRED);
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DEFERRED_COUNT);
        Module3PendingClear(oSubject);
        return TRUE;
    }

    Module3PendingTouch(oArea, oSubject, nPriority, MODULE3_REASON_UNSPECIFIED, MODULE3_PENDING_STATUS_RUNNING);
    Module3ActivityOnIdleTick(oSubject);
    if (GetIsObjectValid(oSubject))
    {
        Module3PendingSetStatus(oSubject, MODULE3_PENDING_STATUS_PROCESSED);
        Module3PendingClear(oSubject);
        Module3MetricInc(oArea, MODULE3_METRIC_PROCESSED_TOTAL);
        return TRUE;
    }

    Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DROPPED_COUNT);
    return TRUE;
}

void Module3OnAreaTick(object oArea)
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

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (Module3AreaGetState(oArea) == MODULE3_AREA_STATE_STOPPED)
    {
        SetLocalInt(oArea, MODULE3_VAR_AREA_TIMER_RUNNING, FALSE);
        return;
    }

    if (Module3AreaGetState(oArea) == MODULE3_AREA_STATE_RUNNING)
    {
        nMaxEvents = Module3GetTickMaxEvents(oArea);
        if (nMaxEvents > MODULE3_TICK_MAX_EVENTS_HARD_CAP)
        {
            nMaxEvents = MODULE3_TICK_MAX_EVENTS_HARD_CAP;
        }

        nSoftBudgetMs = Module3GetTickSoftBudgetMs(oArea);
        if (nSoftBudgetMs > MODULE3_TICK_SOFT_BUDGET_MS_HARD_CAP)
        {
            nSoftBudgetMs = MODULE3_TICK_SOFT_BUDGET_MS_HARD_CAP;
        }

        nSpentEvents = 0;
        nSpentBudgetMs = 0;
        while (TRUE)
        {
            nEventsBudgetLeft = nMaxEvents - nSpentEvents;
            if (nEventsBudgetLeft <= 0)
            {
                nEventBudgetReached = TRUE;
                break;
            }

            if (nSpentBudgetMs + MODULE3_TICK_SIMULATED_EVENT_COST_MS > nSoftBudgetMs)
            {
                nSoftBudgetReached = TRUE;
                break;
            }

            if (!Module3QueueProcessOne(oArea))
            {
                break;
            }

            nSpentEvents = nSpentEvents + 1;
            nSpentBudgetMs = nSpentBudgetMs + MODULE3_TICK_SIMULATED_EVENT_COST_MS;
        }

        nProcessedThisTick = nSpentEvents;

        SetLocalInt(oArea, MODULE3_VAR_TICK_PROCESSED, nProcessedThisTick);
        nPendingAfter = GetLocalInt(oArea, MODULE3_VAR_QUEUE_PENDING_TOTAL);

        nBudgetExceeded = (nSoftBudgetReached || nEventBudgetReached) && nPendingAfter > 0;
        SetLocalInt(oArea, MODULE3_VAR_TICK_DEGRADED_MODE, nBudgetExceeded);

        if (nBudgetExceeded)
        {
            // Очередь FIFO по приоритетам уже детерминирована: хвост переносится на следующий тик без reordering.
            Module3MetricInc(oArea, MODULE3_METRIC_TICK_BUDGET_EXCEEDED_TOTAL);
            Module3MetricInc(oArea, MODULE3_METRIC_DEGRADED_MODE_TOTAL);
            Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DEFERRED_COUNT);
            Module3QueueMarkDeferredHead(oArea);
            SetLocalInt(oArea, MODULE3_VAR_TICK_DEGRADED_STREAK, GetLocalInt(oArea, MODULE3_VAR_TICK_DEGRADED_STREAK) + 1);
        }
        else
        {
            SetLocalInt(oArea, MODULE3_VAR_TICK_DEGRADED_STREAK, 0);
        }

        if (nPendingAfter > 0)
        {
            nBacklogAgeTicks = GetLocalInt(oArea, MODULE3_VAR_QUEUE_BACKLOG_AGE_TICKS) + 1;
            SetLocalInt(oArea, MODULE3_VAR_QUEUE_BACKLOG_AGE_TICKS, nBacklogAgeTicks);
            Module3MetricAdd(oArea, MODULE3_METRIC_PENDING_AGE_MS, 1000);
        }
        else
        {
            SetLocalInt(oArea, MODULE3_VAR_QUEUE_BACKLOG_AGE_TICKS, 0);
        }

        // Auto-idle-stop: если в области нет игроков и нет pending, останавливаем loop.
        nPlayers = Module3CountPlayersInArea(oArea);
        if (nPlayers <= 0 && nPendingAfter <= 0)
        {
            Module3AreaStop(oArea);
        }
    }

    DelayCommand(1.0, ExecuteScript("module3_behavior_area_tick", oArea));
}

void Module3BootstrapModuleAreas()
{
    object oArea;

    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        if (GetLocalInt(oArea, MODULE3_VAR_AREA_STATE) == MODULE3_AREA_STATE_RUNNING)
        {
            Module3AreaActivate(oArea);
        }
        oArea = GetNextArea();
    }
}

void Module3OnSpawn(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    Module3MetricInc(oNpc, MODULE3_METRIC_SPAWN_COUNT);
    Module3ActivityOnSpawn(oNpc);

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea) && !Module3AreaIsRunning(oArea))
    {
        Module3AreaActivate(oArea);
    }
}

void Module3OnPerception(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    Module3MetricInc(oNpc, MODULE3_METRIC_PERCEPTION_COUNT);
    oArea = GetArea(oNpc);
    Module3QueueEnqueue(oArea, oNpc, MODULE3_PRIORITY_HIGH, MODULE3_REASON_PERCEPTION);
}

void Module3OnDamaged(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    Module3MetricInc(oNpc, MODULE3_METRIC_DAMAGED_COUNT);
    oArea = GetArea(oNpc);
    Module3QueueEnqueue(oArea, oNpc, MODULE3_PRIORITY_CRITICAL, MODULE3_REASON_DAMAGE);
}

void Module3OnDeath(object oNpc)
{
    Module3MetricInc(oNpc, MODULE3_METRIC_DEATH_COUNT);
}

void Module3OnDialogue(object oNpc)
{
    Module3MetricInc(oNpc, MODULE3_METRIC_DIALOGUE_COUNT);
}

void Module3OnAreaEnter(object oArea, object oEntering)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEntering))
    {
        return;
    }

    Module3MetricInc(oArea, MODULE3_METRIC_AREA_ENTER_COUNT);
    if (GetIsPC(oEntering) && !Module3AreaIsRunning(oArea))
    {
        Module3AreaActivate(oArea);
    }
}

void Module3OnAreaExit(object oArea, object oExiting)
{
    int nPlayers;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oExiting))
    {
        return;
    }

    Module3MetricInc(oArea, MODULE3_METRIC_AREA_EXIT_COUNT);

    nPlayers = Module3CountPlayersInArea(oArea);
    if (GetIsPC(oExiting) && nPlayers <= 1)
    {
        Module3AreaPause(oArea);
    }
}

void Module3OnModuleLoad()
{
    Module3MetricInc(GetModule(), MODULE3_METRIC_MODULE_LOAD_COUNT);
    Module3BootstrapModuleAreas();
}
