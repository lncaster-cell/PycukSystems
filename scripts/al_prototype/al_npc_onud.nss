// NPC OnUserDefined: attach to NPC OnUserDefined in the toolset.

#include "al_constants_inc"
#include "al_npc_acts_inc"
#include "al_debug_inc"

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

void AL_DebugLog(object oNpc, string sMessage)
{
    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetLocalInt(oNpc, "al_debug") != 1 && GetLocalInt(oArea, "al_debug") != 1)
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, sMessage);
}

void main()
{
    object oNpc = OBJECT_SELF;
    int nEvent = GetUserDefinedEventNumber();
    int nSlot = -1;

    if (nEvent == AL_EVT_RESYNC)
    {
        object oArea = GetArea(oNpc);
        if (GetIsObjectValid(oArea))
        {
            nSlot = GetLocalInt(oArea, "al_slot");
        }

    }
    else if (nEvent >= AL_EVT_SLOT_0 && nEvent <= AL_EVT_SLOT_5)
    {
        nSlot = nEvent - AL_EVT_SLOT_0;
    }
    else if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        nSlot = GetLocalInt(oNpc, "r_slot");
    }
    else
    {
        return;
    }

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

    SetLocalInt(oNpc, "al_last_slot", nSlot);
    int nActivity = AL_GetWaypointActivityForSlot(oNpc, nSlot);
    int bUsesRoute = AL_ActivityUsesRoute(nSlot);
    int bRequiresRouteTag = AL_GetActivityWaypointTag(nActivity) != "";
    int bHasRequiredRoute = AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity);
    int bCanUseRoute = bUsesRoute && bHasRequiredRoute;
    AL_DebugLog(oNpc, "AL_EVT " + IntToString(nEvent)
        + " slot=" + IntToString(nSlot)
        + " activity=" + IntToString(nActivity));
    if (nActivity == AL_ACT_NPC_HIDDEN)
    {
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }
    if (nEvent == AL_EVT_ROUTE_REPEAT && !bCanUseRoute)
    {
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }

    int bSleepActivity = AL_ShouldLoopCustomAnimation(nActivity);
    if (!bCanUseRoute)
    {
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
    }
    AL_DebugLog(oNpc, "routeCount=" + IntToString(AL_GetRouteCount(oNpc, nSlot))
        + " requiresRoute=" + IntToString(bRequiresRouteTag)
        + " usesRoute=" + IntToString(bUsesRoute)
        + " hasRequiredRoute=" + IntToString(bHasRequiredRoute)
        + " sleep=" + IntToString(bSleepActivity));

    int bSkipMoveRepeat = FALSE;
    if (bCanUseRoute && nEvent == AL_EVT_ROUTE_REPEAT && AL_GetRouteCount(oNpc, nSlot) == 1)
    {
        bSkipMoveRepeat = TRUE;
    }

    if (bCanUseRoute)
    {
        if (bSleepActivity && nEvent == AL_EVT_ROUTE_REPEAT)
        {
            AL_ClearActiveRoute(oNpc, /*bClearActions=*/ FALSE);
        }
        else if (bSkipMoveRepeat)
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

    int bAllowAnimation = TRUE;
    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        if (AL_IsRepeatAnimCoolingDown(oNpc))
        {
            bAllowAnimation = FALSE;
        }
    }

    int bShouldPlay = bAllowAnimation;
    if (bCanUseRoute && nEvent != AL_EVT_ROUTE_REPEAT)
    {
        bShouldPlay = FALSE;
    }

    if (bShouldPlay)
    {
        int nIntervalSeconds = AL_GetRepeatAnimIntervalSeconds();
        AL_ApplyActivityForSlot(oNpc, nSlot);
        AL_MarkAnimationApplied(oNpc, nIntervalSeconds);
    }
}
