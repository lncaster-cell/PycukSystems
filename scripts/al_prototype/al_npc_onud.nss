// NPC OnUserDefined: attach to NPC OnUserDefined in the toolset.

#include "al_npc_acts_inc"

void AL_ResetRouteIndex(object oNpc)
{
    SetLocalInt(oNpc, "r_idx", 0);
}

int AL_ActivityUsesRoute(int nSlot)
{
    return AL_GetRouteCount(OBJECT_SELF, nSlot) > 0;
}

int AL_GetRepeatAnimIntervalSeconds()
{
    return 15 + Random(16);
}

int AL_ResolveSlot(object oNpc, int nEvent)
{
    if (nEvent == AL_EVT_RESYNC)
    {
        object oArea = GetArea(oNpc);
        if (GetIsObjectValid(oArea))
        {
            return GetLocalInt(oArea, "al_slot");
        }

        return -1;
    }

    if (nEvent >= AL_EVT_SLOT_BASE && nEvent <= AL_EVT_SLOT_5)
    {
        return nEvent - AL_EVT_SLOT_BASE;
    }

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        return GetLocalInt(oNpc, "r_slot");
    }

    return -1;
}

void AL_SyncRouteForSlot(object oNpc, int nSlot)
{
    string sDesiredTag = AL_GetDesiredRouteTag(oNpc, nSlot);
    string sCurrentTag = AL_GetRouteTag(oNpc, nSlot);

    if (sDesiredTag == "")
    {
        AL_ClearRoute(oNpc, nSlot);
    }
    else
    {
        if (sCurrentTag != "" && sCurrentTag != sDesiredTag)
        {
            AL_ClearRoute(oNpc, nSlot);
        }

        AL_CacheRouteFromTag(oNpc, nSlot, sDesiredTag);
    }

    AL_ResetRouteIndex(oNpc);
}

int AL_IsRepeatAnimCoolingDown(object oNpc)
{
    int nNextStored = GetLocalInt(oNpc, "al_anim_next");
    if (nNextStored == 0)
    {
        return FALSE;
    }

    int nNext = nNextStored - 1;
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nDelta = (nNext - nNow + 86400) % 86400;
    return nDelta > 0 && nDelta < 43200;
}

void AL_MarkAnimationApplied(object oNpc, int nIntervalSeconds)
{
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = (nNow + nIntervalSeconds) % 86400;
    SetLocalInt(oNpc, "al_anim_next", nNext + 1);
}

void main()
{
    object oNpc = OBJECT_SELF;
    int nEvent = GetUserDefinedEventNumber();
    int nSlot = AL_ResolveSlot(oNpc, nEvent);

    if (nSlot < 0 || nSlot > AL_SLOT_MAX)
    {
        return;
    }

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        int nRouteActive = GetLocalInt(oNpc, "r_active");
        if (nRouteActive == FALSE || AL_GetRouteCount(oNpc, nSlot) <= 0)
        {
            return;
        }

        if (GetLocalInt(oNpc, "al_last_slot") != nSlot)
        {
            return;
        }
    }
    else if (nEvent != AL_EVT_RESYNC && GetLocalInt(oNpc, "al_last_slot") == nSlot)
    {
        return;
    }

    if (nEvent == AL_EVT_RESYNC)
    {
        SetLocalInt(oNpc, "al_last_slot", -1);
    }

    if (nEvent != AL_EVT_ROUTE_REPEAT)
    {
        AL_SyncRouteForSlot(oNpc, nSlot);
    }

    SetLocalInt(oNpc, "al_last_slot", nSlot);
    int nActivity = AL_GetWaypointActivityForSlot(oNpc, nSlot);
    int bUsesRoute = AL_ActivityUsesRoute(nSlot);
    int bRequiresRouteTag = AL_GetActivityWaypointTag(nActivity) != "";
    int bHasRequiredRoute = AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity);
    int bCanUseRoute = bUsesRoute && bHasRequiredRoute;
    if (nActivity == AL_ACT_NPC_HIDDEN)
    {
        AL_StopSleepAtBed(oNpc);
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }
    if (nEvent == AL_EVT_ROUTE_REPEAT && !bCanUseRoute)
    {
        AL_StopSleepAtBed(oNpc);
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }

    int bSleepActivity = AL_ShouldLoopCustomAnimation(nActivity);
    if (!bSleepActivity)
    {
        AL_StopSleepAtBed(oNpc);
    }

    if (!bCanUseRoute)
    {
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
    }

    int bSkipMoveRepeat = FALSE;
    if (bCanUseRoute && nEvent == AL_EVT_ROUTE_REPEAT && AL_GetRouteCount(oNpc, nSlot) == 1)
    {
        bSkipMoveRepeat = TRUE;
    }

    if (bCanUseRoute && !bSleepActivity)
    {
        if (bSkipMoveRepeat)
        {
            float fRepeatDelay = 5.0 + IntToFloat(Random(8));

            AssignCommand(oNpc, ActionWait(fRepeatDelay));
            AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_ROUTE_REPEAT))));
        }
        else
        {
            AL_QueueRoute(oNpc, nSlot, nEvent != AL_EVT_ROUTE_REPEAT);
        }
    }
    else if (bSleepActivity)
    {
        // Sleep does not need movement repeat loops: keep NPC docked and avoid
        // extra AL_EVT_ROUTE_REPEAT scheduling/load while sleeping.
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
    }

    int bAllowAnimation = TRUE;
    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        if (AL_IsRepeatAnimCoolingDown(oNpc))
        {
            bAllowAnimation = FALSE;
        }
    }

    int bShouldPlay = bAllowAnimation && (bSleepActivity || !(bCanUseRoute && nEvent != AL_EVT_ROUTE_REPEAT));

    if (bShouldPlay)
    {
        int nIntervalSeconds = AL_GetRepeatAnimIntervalSeconds();
        if (bSleepActivity)
        {
            object oSleepWp = AL_FindSleepWaypointForSlot(oNpc, nSlot);
            if (!AL_StartSleepAtBed(oNpc, oSleepWp))
            {
                AL_ApplyActivityForSlot(oNpc, nSlot);
            }
        }
        else
        {
            AL_ApplyActivityForSlot(oNpc, nSlot);
        }
        AL_MarkAnimationApplied(oNpc, nIntervalSeconds);
    }
}
