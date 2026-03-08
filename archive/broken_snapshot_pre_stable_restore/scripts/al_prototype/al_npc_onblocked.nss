// NPC OnBlocked: attach to NPC OnBlocked in the toolset.
// Tries to open a nearby closed door when movement is blocked.

#include "al_constants_inc"

int AL_GetSecondsOfDay()
{
    return GetTimeSecond() + GetTimeMinute() * 60 + GetTimeHour() * 3600;
}

void AL_TryOpenNearestDoor(object oNpc)
{
    int nNow = AL_GetSecondsOfDay();
    int nLastBlockedTs = GetLocalInt(oNpc, AL_L_LAST_BLOCKED_TS);
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

    SetLocalInt(oNpc, AL_L_LAST_BLOCKED_TS, nNow);

    AssignCommand(oNpc, ClearAllActions());
    AssignCommand(oNpc, ActionOpenDoor(oDoor));
    AssignCommand(oNpc, ActionWait(0.2));
    AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC))));
}

void main()
{
    object oNpc = OBJECT_SELF;
    AL_TryOpenNearestDoor(oNpc);
}
