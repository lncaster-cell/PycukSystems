// NPC route helpers: store per-slot route locations in locals and enqueue actions.
// Locals format on NPC:
//   r<slot>_n      (int)    number of points
//   r<slot>_<idx>  (location) route point
// Runtime locals:
//   r_slot         (int)    active slot
//   r_idx          (int)    active index (optional)

#include "al_constants_inc"
#include "al_npc_reg_inc"
#include "al_area_tick_inc"

void AL_RouteDebugLog(object oNpc, string sMessage)
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

    object oPc = GetFirstPC();
    while (GetIsObjectValid(oPc))
    {
        if (GetArea(oPc) == oArea)
        {
            SendMessageToPC(oPc, sMessage);
        }

        oPc = GetNextPC();
    }
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
    return GetLocalString(oNpc, "alwp" + IntToString(nSlot));
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
    SetLocalInt(oNpc, "r_idx", iIndex);
}

void AL_OnRouteStep(object oNpc, int nIdx, location lPoint)
{
    const float REACHED_THRESHOLD = 1.8;

    object oNpcArea = GetArea(oNpc);
    object oPointArea = GetAreaFromLocation(lPoint);

    if (!GetIsObjectValid(oNpcArea) || !GetIsObjectValid(oPointArea) || oNpcArea != oPointArea)
    {
        if (GetIsObjectValid(oNpcArea))
        {
            int nTickToken = GetLocalInt(oNpcArea, "al_tick_token");
            if (nTickToken == GetLocalInt(oNpc, "al_last_route_recover_tick"))
            {
                return;
            }

            SetLocalInt(oNpc, "al_last_route_recover_tick", nTickToken);
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

    int nTickToken = GetLocalInt(oNpcArea, "al_tick_token");
    if (nTickToken == GetLocalInt(oNpc, "al_last_route_recover_tick"))
    {
        return;
    }

    SetLocalInt(oNpc, "al_last_route_recover_tick", nTickToken);

    if (GetLocalInt(oNpc, "al_debug") == 1 || GetLocalInt(oNpcArea, "al_debug") == 1)
    {
        AL_RouteDebugLog(oNpc, "AL: route step failed, idx=" + IntToString(nIdx)
            + ", dist=" + FloatToString(fDist) + ", resync.");
    }

    AssignCommand(oNpc, ClearAllActions());
    SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
}

void AL_ClearActiveRoute(object oNpc, int bClearActions)
{
    if (bClearActions)
    {
        AssignCommand(oNpc, ClearAllActions());
    }

    DeleteLocalInt(oNpc, "r_slot");
    DeleteLocalInt(oNpc, "r_idx");
    DeleteLocalInt(oNpc, "r_active");
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

    if (!GetLocalInt(oArea, "al_routes_cached"))
    {
        AL_CacheAreaRoutes(oArea);
    }

    string sPrefix = AL_GetRoutePrefix(nSlot);
    string sAreaPrefix = "al_route_" + sTag + "_";
    int iAreaCount = GetLocalInt(oArea, sAreaPrefix + "n");
    int iAreaCountOriginal = iAreaCount;
    int iCopied = 0;
    int i = 0;

    if (iAreaCount > AL_ROUTE_MAX_POINTS)
    {
        iAreaCount = AL_ROUTE_MAX_POINTS;
        AL_RouteDebugLog(oNpc, "AL: route tag " + sTag + " truncated to "
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
            AL_RouteDebugLog(oNpc, "AL: route tag " + sTag + " skipped point "
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
        SetLocalObject(oNpc, "al_last_area", oArea);
        int nPlayerCount = GetLocalInt(oArea, "al_player_count");
        if (nPlayerCount <= 0)
        {
            // Protect zero-activity areas without PCs; activation happens via al_area_onenter.
            SetScriptHidden(oNpc, TRUE, TRUE);
            if (GetLocalInt(oNpc, "r_active"))
            {
                AL_ClearActiveRoute(oNpc, TRUE);
            }
            AL_RegisterNPC(oNpc);
            return;
        }

        AL_RegisterNPC(oNpc);
    }

    int nSlot = GetLocalInt(oNpc, "r_slot");
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

    SetLocalInt(oNpc, "r_slot", nSlot);
    SetLocalInt(oNpc, "r_idx", 0);
    SetLocalInt(oNpc, "r_active", TRUE);

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
        AssignCommand(oNpc, ActionMoveToLocation(lPoint));
        AssignCommand(oNpc, ActionDoCommand(AL_OnRouteStep(oNpc, i, lPoint)));
        location lJump = GetLocalLocation(oNpc, sIndex + "_jump");
        object oJumpArea = GetAreaFromLocation(lJump);
        if (GetIsObjectValid(oJumpArea))
        {
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

        AssignCommand(oNpc, ActionWait(fRepeatDelay));
        AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_ROUTE_REPEAT))));
    }
}
