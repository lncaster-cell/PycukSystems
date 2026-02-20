// NPC behavior module: area tick handler (Phase 1 MVP)

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

const int NPC_DEFAULT_IDLE_INTERVAL = 6;
const int NPC_DEFAULT_COMBAT_INTERVAL = 2;

string NPC_VAR_STATE = "npc_state";
string NPC_VAR_LAST_TICK = "npc_last_tick";
string NPC_VAR_PROCESSED_TICK = "npc_processed_in_tick";

int NpcBehaviorTickNow()
{
    return GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond();
}

int NpcBehaviorGetInterval(object oNpc)
{
    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        return NPC_DEFAULT_COMBAT_INTERVAL;
    }

    return NPC_DEFAULT_IDLE_INTERVAL;
}

int NpcBehaviorShouldProcess(object oNpc, int nNow)
{
    int nLastTick = GetLocalInt(oNpc, NPC_VAR_LAST_TICK);
    int nInterval = NpcBehaviorGetInterval(oNpc);

    if (nLastTick == 0)
    {
        return TRUE;
    }

    if ((nNow - nLastTick) >= nInterval)
    {
        return TRUE;
    }

    return FALSE;
}

void NpcBehaviorHandleIdle(object oNpc)
{
    if (GetIsObjectValid(GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, PLAYER_CHAR_IS_PC, oNpc)) == FALSE)
    {
        ActionRandomWalk();
    }
}

void NpcBehaviorHandleCombat(object oNpc)
{
    if (GetIsInCombat(oNpc) == FALSE)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
}

void NpcBehaviorProcessNpc(object oNpc, int nNow)
{
    int nState = GetLocalInt(oNpc, NPC_VAR_STATE);

    if (nState == NPC_STATE_COMBAT)
    {
        NpcBehaviorHandleCombat(oNpc);
    }
    else
    {
        NpcBehaviorHandleIdle(oNpc);
    }

    SetLocalInt(oNpc, NPC_VAR_LAST_TICK, nNow);
}

void main()
{
    object oArea = OBJECT_SELF;
    object oObject = GetFirstObjectInArea(oArea);

    int nNow = NpcBehaviorTickNow();
    int nProcessed = 0;
    int nProcessLimit = 32;

    while (GetIsObjectValid(oObject) && nProcessed < nProcessLimit)
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && GetIsPC(oObject) == FALSE)
        {
            if (NpcBehaviorShouldProcess(oObject, nNow))
            {
                NpcBehaviorProcessNpc(oObject, nNow);
                nProcessed = nProcessed + 1;
            }
        }

        oObject = GetNextObjectInArea(oArea);
    }

    SetLocalInt(oArea, NPC_VAR_PROCESSED_TICK, nProcessed);
}
