// NPC route helpers: store per-slot route locations in locals and enqueue actions.
// Locals format on NPC:
//   r<slot>_n      (int)    number of points
//   r<slot>_<idx>  (location) route point
// Runtime locals:
//   r_slot         (int)    active slot
//   r_idx          (int)    active index (optional)

#include "al_constants_inc"
#include "al_npc_reg_inc"
#include "al_route_cache_inc"

void AL_RouteDebugLog(object oNpc, int nLevel, string sMessage)
{
    object oArea = GetArea(oNpc);
    AL_DebugLog(oArea, oNpc, nLevel, sMessage);
}

string AL_GetRoutePrefix(int nSlot)
{
    return "r" + IntToString(nSlot) + "_";
}

string AL_GetRouteTagKey(int nSlot)
{
    return AL_GetRoutePrefix(nSlot) + "tag";
}

string AL_GetRouteTag(object oNpc, int nSlot)
{
    return GetLocalString(oNpc, AL_GetRouteTagKey(nSlot));
}

string AL_GetDesiredRouteTag(object oNpc, int nSlot)
{
    string sTag = GetLocalString(oNpc, AL_LocalWaypointTag(nSlot));
    if (sTag != "")
    {
        return sTag;
    }

    // Sleep spans 00:00..08:00 (slots 0 and 1). Allow content to define
    // only one sleep route tag and reuse it for the neighbouring slot.
    if (nSlot == 0)
    {
        return GetLocalString(oNpc, AL_LocalWaypointTag(1));
    }

    if (nSlot == 1)
    {
        return GetLocalString(oNpc, AL_LocalWaypointTag(0));
    }

    return "";
}

int AL_GetRouteCount(object oNpc, int nSlot)
{
    return GetLocalInt(oNpc, AL_GetRoutePrefix(nSlot) + "n");
}

location AL_GetRoutePoint(object oNpc, int nSlot, int iIndex)
{
    return GetLocalLocation(oNpc, AL_GetRoutePrefix(nSlot) + IntToString(iIndex));
}

int AL_GetRoutePointActivity(object oNpc, int nSlot, int iIndex)
{
    return GetLocalInt(oNpc, AL_GetRoutePrefix(nSlot) + IntToString(iIndex) + "_activity");
}

void AL_UpdateRouteIndex(object oNpc, int iIndex)
{
    SetLocalInt(oNpc, AL_L_ROUTE_INDEX, iIndex);
}

void AL_OnRouteStep(object oNpc, int nIdx, location lPoint)
{
    float REACHED_THRESHOLD = 1.8;

    object oNpcArea = GetArea(oNpc);
    object oPointArea = GetAreaFromLocation(lPoint);

    if (!GetIsObjectValid(oNpcArea) || !GetIsObjectValid(oPointArea) || oNpcArea != oPointArea)
    {
        if (GetIsObjectValid(oNpcArea))
        {
            int nTickToken = GetLocalInt(oNpcArea, AL_L_TICK_TOKEN);
            if (nTickToken == GetLocalInt(oNpc, AL_L_LAST_ROUTE_RECOVER_TICK))
            {
                return;
            }

            SetLocalInt(oNpc, AL_L_LAST_ROUTE_RECOVER_TICK, nTickToken);
        }

        AssignCommand(oNpc, ClearAllActions());
        SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
        return;
    }

    float fDist = GetDistanceBetweenLocations(GetLocation(oNpc), lPoint);
    if (fDist <= REACHED_THRESHOLD)
    {
        AL_UpdateRouteIndex(oNpc, nIdx);
        return;
    }

    int nTickToken = GetLocalInt(oNpcArea, AL_L_TICK_TOKEN);
    if (nTickToken == GetLocalInt(oNpc, AL_L_LAST_ROUTE_RECOVER_TICK))
    {
        return;
    }

    SetLocalInt(oNpc, AL_L_LAST_ROUTE_RECOVER_TICK, nTickToken);

    AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L1, "AL: route step failed, idx=" + IntToString(nIdx)
        + ", dist=" + FloatToString(fDist) + ", resync.");

    AssignCommand(oNpc, ClearAllActions());
    SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
}

void AL_ClearActiveRoute(object oNpc, int bClearActions)
{
    if (bClearActions)
    {
        AssignCommand(oNpc, ClearAllActions());
    }

    DeleteLocalInt(oNpc, AL_L_ROUTE_SLOT);
    DeleteLocalInt(oNpc, AL_L_ROUTE_INDEX);
    DeleteLocalInt(oNpc, AL_L_ROUTE_ACTIVE);
}

void AL_ClearRoute(object oNpc, int nSlot)
{
    string sPrefix = AL_GetRoutePrefix(nSlot);
    int iCount = GetLocalInt(oNpc, sPrefix + "n");
    int i = 0;

    while (i < iCount)
    {
        string sIndex = sPrefix + IntToString(i);
        DeleteLocalLocation(oNpc, sIndex);
        DeleteLocalLocation(oNpc, sIndex + "_jump");
        DeleteLocalInt(oNpc, sIndex + "_activity");
        i++;
    }

    DeleteLocalInt(oNpc, sPrefix + "n");
    DeleteLocalString(oNpc, AL_GetRouteTagKey(nSlot));
}

int AL_CacheRouteFromTag(object oNpc, int nSlot, string sTag)
{
    AL_ClearRoute(oNpc, nSlot);

    if (sTag == "")
    {
        return 0;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    if (!GetLocalInt(oArea, AL_L_ROUTES_CACHED))
    {
        AL_CacheAreaRoutes(oArea);
    }

    string sPrefix = AL_GetRoutePrefix(nSlot);
    string sAreaPrefix = AL_LocalRouteTagPrefix(sTag);
    int iAreaCount = GetLocalInt(oArea, sAreaPrefix + "n");
    int iAreaCountOriginal = iAreaCount;
    int iCopied = 0;
    int i = 0;

    if (iAreaCount > AL_ROUTE_MAX_POINTS)
    {
        iAreaCount = AL_ROUTE_MAX_POINTS;
        AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L2, "AL: route tag " + sTag + " truncated to "
            + IntToString(AL_ROUTE_MAX_POINTS) + " points (was "
            + IntToString(iAreaCountOriginal) + ").");
    }

    while (i < iAreaCount && iCopied < AL_ROUTE_MAX_POINTS)
    {
        int iSourceIndex = i;
        if (GetLocalInt(oArea, sAreaPrefix + "idx_built"))
        {
            iSourceIndex = GetLocalInt(oArea, sAreaPrefix + "idx_" + IntToString(i));
        }

        string sAreaIndex = sAreaPrefix + IntToString(iSourceIndex);
        location lPoint = GetLocalLocation(oArea, sAreaIndex);
        object oPointArea = GetAreaFromLocation(lPoint);
        if (GetIsObjectValid(oPointArea) && oPointArea == oArea)
        {
            string sNpcIndex = sPrefix + IntToString(iCopied);
            SetLocalLocation(oNpc, sNpcIndex, lPoint);

            int nActivity = GetLocalInt(oArea, sAreaIndex + "_activity");
            if (nActivity > 0)
            {
                SetLocalInt(oNpc, sNpcIndex + "_activity", nActivity);
            }
            else
            {
                DeleteLocalInt(oNpc, sNpcIndex + "_activity");
            }

            DeleteLocalLocation(oNpc, sNpcIndex + "_jump");
            location lJump = GetLocalLocation(oArea, sAreaIndex + "_jump");
            object oJumpArea = GetAreaFromLocation(lJump);
            if (GetIsObjectValid(oJumpArea))
            {
                SetLocalLocation(oNpc, sNpcIndex + "_jump", lJump);
            }

            iCopied++;
        }
        else if (GetIsObjectValid(oPointArea) && oPointArea != oArea)
        {
            AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L2, "AL: route tag " + sTag + " skipped point "
                + IntToString(iSourceIndex) + " due to area mismatch.");
        }

        i++;
    }

    if (iCopied > 0)
    {
        SetLocalInt(oNpc, sPrefix + "n", iCopied);
        SetLocalString(oNpc, AL_GetRouteTagKey(nSlot), sTag);
    }

    return iCopied;
}

void AL_HandleRouteAreaTransition()
{
    object oNpc = OBJECT_SELF;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Instant registry update on explicit route transitions (no per-NPC timers).
    AL_UnregisterNPC(oNpc);

    object oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        SetLocalObject(oNpc, AL_L_LAST_AREA, oArea);
        int nPlayerCount = GetLocalInt(oArea, AL_L_PLAYER_COUNT);
        if (nPlayerCount <= 0)
        {
            // Protect zero-activity areas without PCs; activation happens via al_area_onenter.
            if (!GetScriptHidden(oNpc))
            {
                SetScriptHidden(oNpc, TRUE, TRUE);
            }
            if (GetLocalInt(oNpc, AL_L_ROUTE_ACTIVE))
            {
                AL_ClearActiveRoute(oNpc, TRUE);
            }
            AL_RegisterNPC(oNpc);
            return;
        }

        AL_RegisterNPC(oNpc);
    }

    int nSlot = GetLocalInt(oNpc, AL_L_ROUTE_SLOT);
    if (nSlot >= 0 && nSlot <= AL_SLOT_MAX)
    {
        string sDesiredTag = AL_GetDesiredRouteTag(oNpc, nSlot);
        string sCurrentTag = AL_GetRouteTag(oNpc, nSlot);
        if (sCurrentTag != "" && sCurrentTag != sDesiredTag)
        {
            AL_ClearRoute(oNpc, nSlot);
        }
        AL_CacheRouteFromTag(oNpc, nSlot, sDesiredTag);
    }
    SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
}

void AL_QueueRoute(object oNpc, int nSlot, int bClearActions)
{
    int iCount = AL_GetRouteCount(oNpc, nSlot);
    int i = 0;
    int bMoveQueued = FALSE;
    int bTransitionQueued = FALSE;

    if (bClearActions)
    {
        AssignCommand(oNpc, ClearAllActions());
    }

    if (iCount <= 0)
    {
        AL_ClearActiveRoute(oNpc, FALSE);
        return;
    }

    SetLocalInt(oNpc, AL_L_ROUTE_SLOT, nSlot);
    SetLocalInt(oNpc, AL_L_ROUTE_INDEX, 0);
    SetLocalInt(oNpc, AL_L_ROUTE_ACTIVE, TRUE);

    while (i < iCount)
    {
        string sIndex = AL_GetRoutePrefix(nSlot) + IntToString(i);
        location lPoint = AL_GetRoutePoint(oNpc, nSlot, i);
        object oPointArea = GetAreaFromLocation(lPoint);
        if (!GetIsObjectValid(oPointArea))
        {
            i++;
            continue;
        }
        bMoveQueued = TRUE;
        AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L2, "AL: route queue slot=" + IntToString(nSlot)
            + ", idx=" + IntToString(i) + ", move.");
        AssignCommand(oNpc, ActionMoveToLocation(lPoint));
        AssignCommand(oNpc, ActionDoCommand(AL_OnRouteStep(oNpc, i, lPoint)));
        location lJump = GetLocalLocation(oNpc, sIndex + "_jump");
        object oJumpArea = GetAreaFromLocation(lJump);
        if (GetIsObjectValid(oJumpArea))
        {
            AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L2, "AL: route transition slot=" + IntToString(nSlot)
                + ", idx=" + IntToString(i) + ", jump queued.");
            AssignCommand(oNpc, ActionJumpToLocation(lJump));
            AssignCommand(oNpc, ActionDoCommand(AL_HandleRouteAreaTransition()));
            bTransitionQueued = TRUE;
            break;
        }
        i++;
    }

    if (!bTransitionQueued)
    {
        if (!bMoveQueued)
        {
            AL_ClearActiveRoute(oNpc, FALSE);
            return;
        }

        float fRepeatDelay = 5.0 + IntToFloat(Random(8));
        AL_RouteDebugLog(oNpc, AL_DEBUG_LEVEL_L2, "AL: route repeat queued, slot=" + IntToString(nSlot)
            + ", delay=" + FloatToString(fRepeatDelay) + ".");

        AssignCommand(oNpc, ActionWait(fRepeatDelay));
        AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_ROUTE_REPEAT))));
    }
}
