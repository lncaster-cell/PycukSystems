// NPC OnBlocked: attach to NPC OnBlocked in the toolset.
// Tries to open a nearby closed door when movement is blocked.

#include "al_constants_inc"

int AL_GetSecondsOfDay()
{
    return GetTimeSecond() + GetTimeMinute() * 60 + GetTimeHour() * 3600;
}

int AL_IsDebugEnabled(object oNpc)
{
    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return GetLocalInt(oNpc, "al_debug") == 1;
    }

    return GetLocalInt(oNpc, "al_debug") == 1 || GetLocalInt(oArea, "al_debug") == 1;
}

void AL_TryOpenNearestDoor(object oNpc)
{
    int nNow = AL_GetSecondsOfDay();
    int nLastBlockedTs = GetLocalInt(oNpc, "al_last_blocked_ts");
    int nElapsed = nNow - nLastBlockedTs;
    if (nElapsed < 0)
    {
        nElapsed += 86400;
    }

    if (nElapsed < 1)
    {
        return;
    }

    object oDoor = GetNearestObject(OBJECT_TYPE_DOOR, oNpc, 1);
    if (!GetIsObjectValid(oDoor))
    {
        return;
    }

    if (GetDistanceBetween(oNpc, oDoor) > 3.0)
    {
        return;
    }

    if (GetIsOpen(oDoor))
    {
        return;
    }

    SetLocalInt(oNpc, "al_last_blocked_ts", nNow);

    AssignCommand(oNpc, ClearAllActions());
    AssignCommand(oNpc, ActionOpenDoor(oDoor));
    AssignCommand(oNpc, ActionWait(0.2));
    AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC))));

    if (AL_IsDebugEnabled(oNpc))
    {
        object oPc = GetFirstPC();
        while (GetIsObjectValid(oPc))
        {
            if (GetArea(oPc) == GetArea(oNpc))
            {
                SendMessageToPC(oPc, "AL: OnBlocked opened door, resync queued.");
            }

            oPc = GetNextPC();
        }
    }
}

void main()
{
    object oNpc = OBJECT_SELF;
    AL_TryOpenNearestDoor(oNpc);
}
