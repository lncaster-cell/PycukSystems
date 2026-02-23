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

const string MODULE3_VAR_AREA_STATE = "module3_area_state";
const string MODULE3_VAR_AREA_TIMER_RUNNING = "module3_area_timer_running";
const string MODULE3_VAR_QUEUE_DEPTH = "module3_queue_depth";
const string MODULE3_VAR_QUEUE_CURSOR = "module3_queue_cursor";

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

    Module3AreaSetState(oArea, MODULE3_AREA_STATE_PAUSED);
}

void Module3AreaStop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    Module3AreaSetState(oArea, MODULE3_AREA_STATE_STOPPED);
}

int Module3QueueEnqueue(object oArea, object oSubject, int nPriority)
{
    int nDepth;
    int nSlot;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSubject))
    {
        return FALSE;
    }

    nDepth = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nDepth >= MODULE3_QUEUE_MAX)
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_OVERFLOW_COUNT);
        return FALSE;
    }

    nSlot = nDepth + 1;
    SetLocalObject(oArea, "module3_queue_subject_" + IntToString(nSlot), oSubject);
    SetLocalInt(oArea, "module3_queue_priority_" + IntToString(nSlot), nPriority);
    SetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH, nSlot);

    Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_ENQUEUED_COUNT);
    return TRUE;
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

void Module3QueueProcessOne(object oArea)
{
    int nDepth;
    int nCursor;
    object oSubject;

    if (!GetIsObjectValid(oArea) || !Module3AreaIsRunning(oArea))
    {
        return;
    }

    nDepth = GetLocalInt(oArea, MODULE3_VAR_QUEUE_DEPTH);
    if (nDepth <= 0)
    {
        return;
    }

    nCursor = GetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR) + 1;
    if (nCursor > nDepth)
    {
        nCursor = 1;
    }

    oSubject = GetLocalObject(oArea, "module3_queue_subject_" + IntToString(nCursor));
    if (!GetIsObjectValid(oSubject))
    {
        Module3MetricInc(oArea, MODULE3_METRIC_QUEUE_DEFERRED_COUNT);
        SetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR, nCursor);
        return;
    }

    // TODO(module3): CRITICAL/HIGH/NORMAL/LOW scheduler with fairness guarantees.
    Module3ActivityOnIdleTick(oSubject);
    SetLocalInt(oArea, MODULE3_VAR_QUEUE_CURSOR, nCursor);
}

void Module3OnAreaTick(object oArea)
{
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
