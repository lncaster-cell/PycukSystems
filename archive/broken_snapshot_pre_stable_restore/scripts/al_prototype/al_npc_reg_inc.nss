// NPC registry helpers: dense array locals al_npc_count, al_npc_0..al_npc_99 on areas.
// Registry synchronization runs only at the area level (see AreaTick).

#include "al_constants_inc"
#include "al_area_constants_inc"
#include "al_debug_inc"
#include "al_area_mode_contract_inc"

const int AL_REGISTRY_FULL_MSG_THROTTLE_SECONDS = 60;

void AL_ResetNPCFreezeState(object oNpc);
void AL_HideRegisteredNPCs(object oArea);


int AL_GetAmbientLifeDaySeconds()
{
    int nSeconds = GetTimeSecond();
    int nMinutes = GetTimeMinute();
    int nHours = GetTimeHour();

    return nSeconds + (nMinutes * 60) + (nHours * 3600);
}

int AL_IsRegistryFullMessageCoolingDown(object oArea)
{
    int nNextStored = GetLocalInt(oArea, AL_L_NPC_FULL_MSG_NEXT);
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
    SetLocalInt(oArea, AL_L_NPC_FULL_MSG_NEXT, nNext + 1);
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
        object oSwap = GetLocalObject(oArea, AL_LocalNpcRegistryEntry(iLastIndex));
        SetLocalObject(oArea, AL_LocalNpcRegistryEntry(iIndex), oSwap);
    }

    DeleteLocalObject(oArea, AL_LocalNpcRegistryEntry(iLastIndex));
    iCount--;
    SetLocalInt(oArea, AL_L_NPC_COUNT, iCount);
    return iCount;
}

void AL_LogRegistrationSkip(object oNpc, object oArea, string sReason)
{
    if (!GetIsObjectValid(oArea) || !AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        return;
    }

    string sTag = GetTag(oNpc);
    if (sTag == "")
    {
        sTag = "<no-tag>";
    }

    AL_SendDebugMessageToAreaPCs(oArea, "AL: registration skipped for '" + sTag + "': " + sReason);
}

int AL_IsParticipantNPC(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    if (GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        return FALSE;
    }

    if (GetLocalInt(oNpc, AL_L_ENABLED) == 1)
    {
        return TRUE;
    }

    int iSlot = 0;
    while (iSlot <= AL_SLOT_MAX)
    {
        if (GetLocalString(oNpc, AL_LocalWaypointTag(iSlot)) != "")
        {
            return TRUE;
        }

        iSlot++;
    }

    return FALSE;
}

void AL_RegisterNPC(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oArea = GetArea(oNpc);

    if (GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        AL_LogRegistrationSkip(oNpc, oArea, "object is not a creature");
        return;
    }

    if (!AL_IsParticipantNPC(oNpc))
    {
        AL_LogRegistrationSkip(oNpc, oArea, "missing AL marker (set al_enabled=1 or route locals alwp<slot>)");
        return;
    }

    if (!GetIsObjectValid(oArea))
    {
        AL_LogRegistrationSkip(oNpc, oArea, "invalid area");
        return;
    }

    if (AL_IsAreaModeOff(oArea))
    {
        AL_LogRegistrationSkip(oNpc, oArea, "area mode is OFF");
        return;
    }

    SetLocalObject(oNpc, AL_L_LAST_AREA, oArea);

    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int iIndex = 0;

    while (iIndex < iCount)
    {
        object oEntry = GetLocalObject(oArea, AL_LocalNpcRegistryEntry(iIndex));

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
        if (AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1) && !AL_IsRegistryFullMessageCoolingDown(oArea))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: NPC registry full for area; registration skipped.");

            AL_MarkRegistryFullMessageSent(oArea);
        }
        return;
    }

    SetLocalObject(oArea, AL_LocalNpcRegistryEntry(iCount), oNpc);
    SetLocalInt(oArea, AL_L_NPC_COUNT, iCount + 1);
}

void AL_UnregisterNPC(object oNpc)
{
    object oArea = GetLocalObject(oNpc, AL_L_LAST_AREA);

    if (!GetIsObjectValid(oArea))
    {
        oArea = GetArea(oNpc);
    }

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int iIndex = 0;

    while (iIndex < iCount)
    {
        object oEntry = GetLocalObject(oArea, AL_LocalNpcRegistryEntry(iIndex));

        if (!GetIsObjectValid(oEntry))
        {
            iCount = AL_PruneRegistrySlot(oArea, iIndex, iCount);
            continue;
        }

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
    if (AL_IsAreaModeOff(oArea))
    {
        return;
    }

    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int i = 0;

    while (i < iCount)
    {
        string sKey = AL_LocalNpcRegistryEntry(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        object oCurrentArea = GetArea(oNpc);
        if (!GetIsObjectValid(oCurrentArea))
        {
            DeleteLocalObject(oNpc, AL_L_LAST_AREA);
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        if (oCurrentArea != oArea)
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            SetLocalObject(oNpc, AL_L_LAST_AREA, oCurrentArea);
            AL_RegisterNPC(oNpc);
            continue;
        }

        SetLocalObject(oNpc, AL_L_LAST_AREA, oArea);
        i++;
    }
}

void AL_HideRegisteredNPCs(object oArea)
{
    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int i = 0;

    while (i < iCount)
    {
        string sKey = AL_LocalNpcRegistryEntry(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        AL_ResetNPCFreezeState(oNpc);
        AssignCommand(oNpc, ClearAllActions());
        if (!GetScriptHidden(oNpc))
        {
            SetScriptHidden(oNpc, TRUE, TRUE);
        }
        i++;
    }
}



void AL_ResetNPCFreezeState(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Freeze/post-wake contract:
    // 1) force collision on (safe with/without AL_StopSleepAtBed),
    // 2) clear bed-docking state,
    // 3) clear runtime route-loop locals so wake always starts from RESYNC.
    SetCollision(oNpc, TRUE);
    DeleteLocalInt(oNpc, AL_L_SLEEP_DOCKED);
    DeleteLocalString(oNpc, AL_L_SLEEP_APPROACH_TAG);
    DeleteLocalInt(oNpc, AL_L_ROUTE_ACTIVE);
    DeleteLocalInt(oNpc, AL_L_ROUTE_SLOT);
    DeleteLocalInt(oNpc, AL_L_ROUTE_INDEX);
}

void AL_HandleAreaBecameEmpty(object oArea)
{
    if (AL_IsAreaModeOff(oArea))
    {
        return;
    }

    AL_SetAreaMode(oArea, AL_AREA_MODE_COLD);
    SetLocalInt(oArea, AL_L_TICK_TOKEN, GetLocalInt(oArea, AL_L_TICK_TOKEN) + 1);
    DeleteLocalInt(oArea, AL_L_TICK_SCHEDULED_TOKEN);
    DeleteLocalInt(oArea, AL_L_TICK_WARM_LEFT);
    DeleteLocalInt(oArea, AL_L_ROUTES_CACHED);
    AL_HideRegisteredNPCs(oArea);
    AL_DebugLogL1(oArea, OBJECT_INVALID, "AL: freeze complete; routes invalidated and NPCs hidden.");
}

void AL_UnhideAndResyncRegisteredNPCs(object oArea)
{
    if (AL_IsAreaModeOff(oArea) || AL_IsAreaModeCold(oArea))
    {
        return;
    }

    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int i = 0;

    while (i < iCount)
    {
        string sKey = AL_LocalNpcRegistryEntry(i);
        object oNpc = GetLocalObject(oArea, sKey);

        if (!GetIsObjectValid(oNpc))
        {
            iCount = AL_PruneRegistrySlot(oArea, i, iCount);
            continue;
        }

        if (GetScriptHidden(oNpc))
        {
            SetScriptHidden(oNpc, FALSE, FALSE);
        }
        AL_DebugLogL1(oArea, oNpc, "AL: wake RESYNC signaled for " + GetName(oNpc) + ".");
        SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
        i++;
    }
}

void AL_BroadcastUserEvent(object oArea, int nEvent)
{
    if (AL_IsAreaModeOff(oArea))
    {
        return;
    }

    int iCount = GetLocalInt(oArea, AL_L_NPC_COUNT);
    int i = 0;

    while (i < iCount)
    {
        string sKey = AL_LocalNpcRegistryEntry(i);
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
