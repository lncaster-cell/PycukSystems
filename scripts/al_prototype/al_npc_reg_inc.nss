// NPC registry helpers: dense array locals al_npc_count, al_npc_0..al_npc_99 on areas.
// Registry synchronization runs only at the area level (see AreaTick).

#include "al_constants_inc"

const int AL_REGISTRY_FULL_MSG_THROTTLE_SECONDS = 60;

int AL_GetAmbientLifeDaySeconds()
{
    int nSeconds = GetTimeSecond();
    int nMinutes = GetTimeMinute();
    int nHours = GetTimeHour();

    return nSeconds + (nMinutes * 60) + (nHours * 3600);
}

int AL_IsRegistryFullMessageCoolingDown(object oArea)
{
    int nNextStored = GetLocalInt(oArea, "al_npc_full_msg_next");
    if (nNextStored == 0)
    {
        return FALSE;
    }

    int nNext = nNextStored - 1;
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nDelta = (nNext - nNow + 86400) % 86400;
    return nDelta > 0 && nDelta < 43200;
}

void AL_MarkRegistryFullMessageSent(object oArea)
{
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = (nNow + AL_REGISTRY_FULL_MSG_THROTTLE_SECONDS) % 86400;
    SetLocalInt(oArea, "al_npc_full_msg_next", nNext + 1);
}

int AL_PruneRegistrySlot(object oArea, int iIndex, int iCount)
{
    int iLastIndex = iCount - 1;

    if (iLastIndex < 0)
    {
        return 0;
    }

    if (iIndex != iLastIndex)
    {
        object oSwap = GetLocalObject(oArea, "al_npc_" + IntToString(iLastIndex));
        SetLocalObject(oArea, "al_npc_" + IntToString(iIndex), oSwap);
    }

    DeleteLocalObject(oArea, "al_npc_" + IntToString(iLastIndex));
    iCount--;
    SetLocalInt(oArea, "al_npc_count", iCount);
    return iCount;
}

void AL_RegisterNPC(object oNpc)
{
    object oArea = GetArea(oNpc);

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalObject(oNpc, "al_last_area", oArea);

    int iCount = GetLocalInt(oArea, "al_npc_count");
    int iIndex = 0;

    while (iIndex < iCount)
    {
        object oEntry = GetLocalObject(oArea, "al_npc_" + IntToString(iIndex));

        if (!GetIsObjectValid(oEntry))
        {
            iCount = AL_PruneRegistrySlot(oArea, iIndex, iCount);
            continue;
        }

        if (oEntry == oNpc)
        {
            return;
        }

        iIndex++;
    }

    if (iCount >= AL_MAX_NPCS)
    {
        if (GetLocalInt(oArea, "al_debug") == 1 && !AL_IsRegistryFullMessageCoolingDown(oArea))
        {
            object oPc = GetFirstPC();
            while (GetIsObjectValid(oPc))
            {
                if (GetArea(oPc) == oArea)
                {
                    SendMessageToPC(oPc, "AL: NPC registry full for area; registration skipped.");
                }

                oPc = GetNextPC();
            }

            AL_MarkRegistryFullMessageSent(oArea);
        }
        return;
    }

    SetLocalObject(oArea, "al_npc_" + IntToString(iCount), oNpc);
    SetLocalInt(oArea, "al_npc_count", iCount + 1);
}

void AL_UnregisterNPC(object oNpc)
{
    object oArea = GetLocalObject(oNpc, "al_last_area");

    if (!GetIsObjectValid(oArea))
    {
        oArea = GetArea(oNpc);
    }

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    int iCount = GetLocalInt(oArea, "al_npc_count");
    int iIndex = 0;

    while (iIndex < iCount)
    {
        object oEntry = GetLocalObject(oArea, "al_npc_" + IntToString(iIndex));

        if (oEntry == oNpc)
        {
            AL_PruneRegistrySlot(oArea, iIndex, iCount);
            return;
        }

        iIndex++;
    }
}

void AL_SyncAreaNPCRegistry(object oArea)
{
    int iCount = GetLocalInt(oArea, "al_npc_count");
    int i = 0;

    while (i < iCount)
    {
        string sKey = "al_npc_" + IntToString(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        object oCurrentArea = GetArea(oNpc);
        if (!GetIsObjectValid(oCurrentArea))
        {
            DeleteLocalObject(oNpc, "al_last_area");
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        if (oCurrentArea != oArea)
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            SetLocalObject(oNpc, "al_last_area", oCurrentArea);
            AL_RegisterNPC(oNpc);
            continue;
        }

        SetLocalObject(oNpc, "al_last_area", oArea);
        i++;
    }
}

void AL_HideRegisteredNPCs(object oArea)
{
    int iCount = GetLocalInt(oArea, "al_npc_count");
    int i = 0;

    while (i < iCount)
    {
        string sKey = "al_npc_" + IntToString(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        if (AL_CLEAR_ACTIONS_ON_DEACTIVATE)
        {
            AssignCommand(oNpc, ClearAllActions());
        }

        SetScriptHidden(oNpc, TRUE, TRUE);
        i++;
    }
}

void AL_HandleAreaBecameEmpty(object oArea)
{
    SetLocalInt(oArea, "al_tick_token", GetLocalInt(oArea, "al_tick_token") + 1);
    DeleteLocalInt(oArea, "al_routes_cached");
    AL_HideRegisteredNPCs(oArea);
}

void AL_UnhideAndResyncRegisteredNPCs(object oArea)
{
    int iCount = GetLocalInt(oArea, "al_npc_count");
    int i = 0;

    while (i < iCount)
    {
        string sKey = "al_npc_" + IntToString(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        SetScriptHidden(oNpc, FALSE, FALSE);
        SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
        i++;
    }
}

void AL_BroadcastUserEvent(object oArea, int nEvent)
{
    int iCount = GetLocalInt(oArea, "al_npc_count");
    int i = 0;

    while (i < iCount)
    {
        string sKey = "al_npc_" + IntToString(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        SignalEvent(oNpc, EventUserDefined(nEvent));
        i++;
    }
}
