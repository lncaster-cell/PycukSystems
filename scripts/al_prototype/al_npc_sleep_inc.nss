// NPC sleep docking + bed waypoint helpers.

#include "al_constants_inc"
#include "al_npc_activity_apply_inc"

// Include layering contract (one-way):
// - al_npc_sleep_inc -> {al_npc_activity_apply_inc}
// - al_npc_acts_inc  -> compatibility wrapper only (no runtime logic)
//                       forwards to al_npc_sleep_inc + related split modules.
// Sleep helpers depend on activity module only for custom animation playback.

string AL_GetSleepDockingProgressKey()
{
    return "al_sleep_docking_in_progress";
}

void AL_SleepDebugLogL1(object oArea, object oNpc, string sMsg)
{
    if (GetIsObjectValid(oArea) && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        AL_SendDebugMessageToAreaPCs(oArea, sMsg);
    }
}

object AL_FindWaypointByTagInArea(object oArea, string sTag)
{
    if (!GetIsObjectValid(oArea) || sTag == "")
    {
        return OBJECT_INVALID;
    }

    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT && GetTag(oObj) == sTag)
        {
            return oObj;
        }

        oObj = GetNextObjectInArea(oArea);
    }

    return OBJECT_INVALID;
}

void AL_QueueSleepAnimationLoop(object oNpc)
{
    AssignCommand(oNpc, AL_PlayCustomAnimation(oNpc, "laydownB", FALSE));
    AssignCommand(oNpc, ActionWait(0.1));
    AssignCommand(oNpc, AL_PlayCustomAnimation(oNpc, "proneB", TRUE));
}

void AL_ResetSleepDockState(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    AssignCommand(oNpc, ActionDoCommand(SetCollision(oNpc, TRUE)));
    DeleteLocalInt(oNpc, AL_L_SLEEP_DOCKED);
    DeleteLocalInt(oNpc, AL_GetSleepDockingProgressKey());
    DeleteLocalString(oNpc, AL_L_SLEEP_APPROACH_TAG);
}

void AL_CompleteSleepDocking(object oNpc, string sApproachTag, string sPoseTag)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, AL_L_SLEEP_DOCKED, TRUE);
    DeleteLocalInt(oNpc, AL_GetSleepDockingProgressKey());
    SetLocalString(oNpc, AL_L_SLEEP_APPROACH_TAG, sApproachTag);

    object oArea = GetArea(oNpc);
    AL_SleepDebugLogL1(oArea, oNpc,
        "AL: sleep docking completed; approach=" + sApproachTag + ", pose=" + sPoseTag + ".");
}

int AL_StartSleepAtBed(object oNpc, object oSleepWp)
{
    // Contract: this helper only performs bed docking + sleep loop when docking
    // is possible. Fallback sleep animation is owned by the caller
    // (AL_ApplyActivityForSlot in al_npc_onud.nss).
    // Route sleep waypoint is required.
    // <bed_id>_pose waypoint is required.
    // <bed_id>_approach waypoint is optional override.
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        AL_SleepDebugLogL1(oArea, oNpc, "AL: invalid sleep waypoint; docking aborted.");
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sExpectedRouteTag = GetLocalString(oNpc, AL_GetRouteTagKey(GetLocalInt(oNpc, AL_L_LAST_SLOT)));
    string sSleepTag = GetTag(oSleepWp);
    if (sExpectedRouteTag != "" && sSleepTag != sExpectedRouteTag)
    {
        AL_SleepDebugLogL1(oArea, oNpc,
            "AL: sleep route tag mismatch; expected=" + sExpectedRouteTag + ", got=" + sSleepTag + ".");
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    if (!GetIsObjectValid(oSleepWp))
    {
        AL_SleepDebugLogL1(oArea, oNpc, "AL: invalid sleep waypoint; docking aborted.");
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sExpectedRouteTag = GetLocalString(oNpc, AL_GetRouteTagKey(GetLocalInt(oNpc, AL_L_LAST_SLOT)));
    string sSleepTag = GetTag(oSleepWp);
    if (sExpectedRouteTag != "" && sSleepTag != sExpectedRouteTag)
    {
        AL_SleepDebugLogL1(oArea, oNpc,
            "AL: sleep route tag mismatch; expected=" + sExpectedRouteTag + ", got=" + sSleepTag + ".");
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sBedTag = GetLocalString(oSleepWp, AL_L_BED_TAG);
    object oApproachWp = oSleepWp;
    object oPoseWp = OBJECT_INVALID;

    if (sBedTag != "")
    {
        object oApproachOverrideWp = AL_FindWaypointByTagInArea(oArea, sBedTag + "_approach");
        if (GetIsObjectValid(oApproachOverrideWp))
        {
            oApproachWp = oApproachOverrideWp;
        }

        oPoseWp = AL_FindWaypointByTagInArea(oArea, sBedTag + "_pose");
    }

    if (!GetIsObjectValid(oPoseWp))
    {
        AL_SleepDebugLogL1(oArea, oNpc,
            "AL: missing pose waypoint; expected tag=" + sBedTag + "_pose.");
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sApproachTag = GetTag(oApproachWp);
    int bDockingInProgress = GetLocalInt(oNpc, AL_GetSleepDockingProgressKey());
    if (!bDockingInProgress
        && GetLocalInt(oNpc, AL_L_SLEEP_DOCKED)
        && GetLocalString(oNpc, AL_L_SLEEP_APPROACH_TAG) == sApproachTag)
    {
        // Contract: "already docked" means no repeat move/jump, but keep the
        // sleep-loop animation active.
        AL_QueueSleepAnimationLoop(oNpc);
        return TRUE;
    }

    location lApproach = GetLocation(oApproachWp);
    location lPose = GetLocation(oPoseWp);
    string sPoseTag = GetTag(oPoseWp);

    DeleteLocalInt(oNpc, AL_L_SLEEP_DOCKED);
    SetLocalInt(oNpc, AL_GetSleepDockingProgressKey(), TRUE);
    AssignCommand(oNpc, ClearAllActions());
    AssignCommand(oNpc, ActionMoveToLocation(lApproach));
    AssignCommand(oNpc, ActionWait(0.1));

    AssignCommand(oNpc, ActionDoCommand(SetCollision(oNpc, FALSE)));
    AssignCommand(oNpc, ActionJumpToLocation(lPose));
    AssignCommand(oNpc, ActionWait(0.1));
    AssignCommand(oNpc, ActionDoCommand(AL_CompleteSleepDocking(oNpc, sApproachTag, sPoseTag)));

    AL_QueueSleepAnimationLoop(oNpc);

    AL_SleepDebugLogL1(oArea, oNpc,
        "AL: sleep docking queued; approach=" + sApproachTag + ", pose=" + sPoseTag + ".");
    return TRUE;
}

void AL_StopSleepAtBed(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int bDocked = GetLocalInt(oNpc, AL_L_SLEEP_DOCKED);
    int bDockingInProgress = GetLocalInt(oNpc, AL_GetSleepDockingProgressKey());
    if (!bDocked && !bDockingInProgress)
    {
        return;
    }

    object oArea = GetArea(oNpc);
    string sApproachTag = GetLocalString(oNpc, AL_L_SLEEP_APPROACH_TAG);
    object oApproachWp = AL_FindWaypointByTagInArea(oArea, sApproachTag);

    AssignCommand(oNpc, ClearAllActions());
    if (GetIsObjectValid(oApproachWp))
    {
        AssignCommand(oNpc, ActionJumpToLocation(GetLocation(oApproachWp)));
        AssignCommand(oNpc, ActionWait(0.1));
    }
    AL_ResetSleepDockState(oNpc);
}

// Finds nearest sleep route waypoint that has bed config via:
// - route sleep waypoint (required)
// - al_bed_tag (required for <tag>_pose lookup)
// - <tag>_approach (optional override, fallback to route sleep waypoint)
object AL_FindSleepWaypointForSlot(object oNpc, int nSlot)
{
    int nCount = AL_GetRouteCount(oNpc, nSlot);
    if (nCount <= 0)
    {
        return OBJECT_INVALID;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return OBJECT_INVALID;
    }

    string sRouteTag = AL_GetRouteTag(oNpc, nSlot);
    if (sRouteTag == "")
    {
        return OBJECT_INVALID;
    }

    int nIndex = GetLocalInt(oNpc, AL_L_ROUTE_INDEX);
    if (nIndex < 0 || nIndex >= nCount)
    {
        if (AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: corrected invalid r_idx " + IntToString(nIndex)
                + " to 0 for sleep waypoint lookup.");
        }

        nIndex = 0;
    }

    location lRoutePoint = AL_GetRoutePoint(oNpc, nSlot, nIndex);
    object oBest = OBJECT_INVALID;
    float fBestDist = 999999.0;
    int bFoundTagMatch = FALSE;
    int bFoundTagWithBed = FALSE;

    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        // Sleep waypoint is valid only when configured via al_bed_tag
        // (resolved to required <tag>_pose and optional <tag>_approach).
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT
            && GetTag(oObj) == sRouteTag)
        {
            bFoundTagMatch = TRUE;
            if (GetLocalString(oObj, AL_L_BED_TAG) != "")
            {
                bFoundTagWithBed = TRUE;
                float fDist = GetDistanceBetweenLocations(GetLocation(oObj), lRoutePoint);
                if (!GetIsObjectValid(oBest) || fDist < fBestDist)
                {
                    oBest = oObj;
                    fBestDist = fDist;
                }
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    if (!bFoundTagMatch)
    {
        AL_SleepDebugLogL1(oArea, oNpc,
            "AL: sleep route tag mismatch; no waypoint found for route tag " + sRouteTag + ".");
    }
    else if (!bFoundTagWithBed)
    {
        AL_SleepDebugLogL1(oArea, oNpc,
            "AL: invalid sleep waypoint; route tag " + sRouteTag + " missing al_bed_tag.");
    }

    return oBest;
}
