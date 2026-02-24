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

const int MODULE3_QUEUE_MAX = 64;
const int MODULE3_STARVATION_STREAK_LIMIT = 3;

const string MODULE3_VAR_AREA_STATE = "module3_area_state";
const string MODULE3_VAR_AREA_TIMER_RUNNING = "module3_area_timer_running";
const string MODULE3_VAR_QUEUE_DEPTH = "module3_queue_depth";
const string MODULE3_VAR_QUEUE_PENDING_TOTAL = "module3_queue_pending_total";
const string MODULE3_VAR_QUEUE_CURSOR = "module3_queue_cursor";
const string MODULE3_VAR_FAIRNESS_STREAK = "module3_fairness_streak";

string Module3QueueDepthKey(int nPriority)
{
    return "module3_queue_depth_" + IntToString(nPriority);
}

string Module3QueueSubjectKey(int nPriority, int nIndex)
{
    return "module3_queue_subject_" + IntToString(nPriority) + "_" + IntToString(nIndex);
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

int Module3QueueEnqueue(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nTotal;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    if (nPriority < MODULE3_PRIORITY_CRITICAL || nPriority > MODULE3_PRIORITY_LOW)
    {
        nPriority = MODULE3_PRIORITY_NORMAL;
    }

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

void Module3QueueProcessOne(object oArea)
{
    int nTotalDepth;
    int nPriority;
    object oSubject;

    if (!GetIsObjectValid(oArea) || !Module3AreaIsRunning(oArea))
    {
        return;
    }

    nTotalDepth = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nTotalDepth <= 0)
    {
        SetLocalInt(oArea, MODULE3_VAR_FAIRNESS_STREAK, 0);
        return;
    }

    nPriority = Module3QueuePickPriority(oArea);
    if (nPriority < MODULE3_PRIORITY_CRITICAL)
    {
        return;
    }

    oSubject = Module3QueueDequeueFromPriority(oArea, nPriority);
    if (!GetIsObjectValid(oSubject))
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DEFERRED_COUNT);
        return;
    }

    Module3ActivityOnIdleTick(oSubject);
}

void Module3OnAreaTick(object oArea)
{
    int nPlayers;

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
        Module3QueueProcessOne(oArea);

        // Auto-idle-stop: если в области нет игроков и нет pending, останавливаем loop.
        nPlayers = Module3CountPlayersInArea(oArea);
        if (nPlayers <= 0 && GetLocalInt(oArea, MODULE3_VAR_QUEUE_PENDING_TOTAL) <= 0)
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
    Module3QueueEnqueue(oArea, oNpc, MODULE3_PRIORITY_HIGH);
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
    Module3QueueEnqueue(oArea, oNpc, MODULE3_PRIORITY_CRITICAL);
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
