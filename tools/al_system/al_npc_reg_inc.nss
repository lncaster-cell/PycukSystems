// NPC registry helpers: dense array locals al_npc_count, al_npc_0..al_npc_99 on areas.
// Registry synchronization runs only at the area level (see AreaTick).

#include "al_system/al_constants_inc"

void AL_RecordRegistryOverflow(object oArea, object oNpc, int iCount)
{
    int iDroppedTotal = GetLocalInt(oArea, "al_npc_reg_dropped_total") + 1;
    SetLocalInt(oArea, "al_npc_reg_dropped_total", iDroppedTotal);
    SetLocalInt(oArea, "al_npc_reg_dropped_last_tick", GetTimeHour() * 60 + GetTimeMinute());

    string sAreaTag = GetTag(oArea);
    string sNpcTag = GetTag(oNpc);
    string sMessage = "AL: NPC registry overflow; area=" + sAreaTag
        + ", npc=" + sNpcTag
        + ", count=" + IntToString(iCount)
        + ", limit=" + IntToString(AL_MAX_NPCS)
        + ", dropped_total=" + IntToString(iDroppedTotal);

    WriteTimestampedLogEntry(sMessage);

    if (GetLocalInt(oArea, "al_debug") == 1)
    {
        object oPc = GetFirstPC();
        if (GetIsObjectValid(oPc))
        {
            SendMessageToPC(oPc, sMessage);
        }
    }
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
        AL_RecordRegistryOverflow(oArea, oNpc, iCount);
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
