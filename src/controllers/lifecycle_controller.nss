// Area lifecycle controller: RUNNING/PAUSED/STOPPED state machine for area orchestration.

const int NPC_AREA_LIFECYCLE_STOPPED = 0;
const int NPC_AREA_LIFECYCLE_RUNNING = 1;
const int NPC_AREA_LIFECYCLE_PAUSED = 2;

string NPC_CTRL_VAR_AREA_LIFECYCLE_STATE = "nb_area_lifecycle_state";
string NPC_CTRL_VAR_AREA_ACTIVE = "nb_area_active"; // legacy compatibility mirror
string NPC_CTRL_VAR_AREA_TIMER_RUNNING = "nb_area_timer_running";

int NpcControllerAreaGetLifecycleState(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return NPC_AREA_LIFECYCLE_STOPPED;
    }

    return GetLocalInt(oArea, NPC_CTRL_VAR_AREA_LIFECYCLE_STATE);
}

void NpcControllerAreaSetLifecycleState(object oArea, int nState)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nState != NPC_AREA_LIFECYCLE_RUNNING && nState != NPC_AREA_LIFECYCLE_PAUSED)
    {
        nState = NPC_AREA_LIFECYCLE_STOPPED;
    }

    SetLocalInt(oArea, NPC_CTRL_VAR_AREA_LIFECYCLE_STATE, nState);
    SetLocalInt(oArea, NPC_CTRL_VAR_AREA_ACTIVE, nState == NPC_AREA_LIFECYCLE_RUNNING);
}

int NpcControllerAreaIsRunning(object oArea)
{
    return NpcControllerAreaGetLifecycleState(oArea) == NPC_AREA_LIFECYCLE_RUNNING;
}

int NpcControllerAreaCanProcessTick(object oArea)
{
    int nState;

    nState = NpcControllerAreaGetLifecycleState(oArea);
    return nState == NPC_AREA_LIFECYCLE_RUNNING;
}

void NpcControllerAreaStart(object oArea)
{
    NpcControllerAreaSetLifecycleState(oArea, NPC_AREA_LIFECYCLE_RUNNING);
}

void NpcControllerAreaPause(object oArea)
{
    NpcControllerAreaSetLifecycleState(oArea, NPC_AREA_LIFECYCLE_PAUSED);
}

void NpcControllerAreaStop(object oArea)
{
    NpcControllerAreaSetLifecycleState(oArea, NPC_AREA_LIFECYCLE_STOPPED);
}

int NpcControllerAreaIsTimerRunning(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    return GetLocalInt(oArea, NPC_CTRL_VAR_AREA_TIMER_RUNNING) == TRUE;
}

void NpcControllerAreaSetTimerRunning(object oArea, int bRunning)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_CTRL_VAR_AREA_TIMER_RUNNING, bRunning == TRUE);
}
