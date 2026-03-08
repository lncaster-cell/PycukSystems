// NPC sleep docking + bed waypoint helpers.

#include "al_npc_activity_apply_inc"

// Include layering contract (one-way):
// - al_npc_sleep_inc -> {al_npc_activity_apply_inc}
// - al_npc_acts_inc  -> compatibility wrapper only (no runtime logic)
//                       forwards to al_npc_sleep_inc + related split modules.
// Sleep helpers depend on activity module only for custom animation playback.

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
    DeleteLocalInt(oNpc, "al_sleep_docked");
    DeleteLocalString(oNpc, "al_sleep_approach_tag");
}

int AL_StartSleepAtBed(object oNpc, object oSleepWp)
{
    // Contract: this helper only performs bed docking + sleep loop when docking
    // is possible. Fallback sleep animation is owned by the caller
    // (AL_ApplyActivityForSlot in al_npc_onud.nss).
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSleepWp))
    {
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sBedTag = GetLocalString(oSleepWp, "al_bed_tag");
    object oApproachWp = OBJECT_INVALID;
    object oPoseWp = OBJECT_INVALID;

    if (sBedTag != "")
    {
        oApproachWp = AL_FindWaypointByTagInArea(oArea, sBedTag + "_approach");
        oPoseWp = AL_FindWaypointByTagInArea(oArea, sBedTag + "_pose");
    }

    if (!GetIsObjectValid(oApproachWp))
    {
        AL_ResetSleepDockState(oNpc);
        return FALSE;
    }

    string sApproachTag = GetTag(oApproachWp);
    if (GetLocalInt(oNpc, "al_sleep_docked")
        && GetLocalString(oNpc, "al_sleep_approach_tag") == sApproachTag)
    {
        // Already docked to this bed approach point: keep sleeping in place.
        return TRUE;
    }

    location lApproach = GetLocation(oApproachWp);
    AssignCommand(oNpc, ClearAllActions());
    AssignCommand(oNpc, ActionMoveToLocation(lApproach));
    AssignCommand(oNpc, ActionWait(0.1));

    if (GetIsObjectValid(oPoseWp))
    {
        location lPose = GetLocation(oPoseWp);
        AssignCommand(oNpc, ActionDoCommand(SetCollision(oNpc, FALSE)));
        AssignCommand(oNpc, ActionJumpToLocation(lPose));
        AssignCommand(oNpc, ActionWait(0.1));
    }

    AL_QueueSleepAnimationLoop(oNpc);

    SetLocalInt(oNpc, "al_sleep_docked", TRUE);
    SetLocalString(oNpc, "al_sleep_approach_tag", sApproachTag);
    return TRUE;
}

void AL_StopSleepAtBed(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || !GetLocalInt(oNpc, "al_sleep_docked"))
    {
        return;
    }

    object oArea = GetArea(oNpc);
    string sApproachTag = GetLocalString(oNpc, "al_sleep_approach_tag");
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
// - al_bed_tag (resolved by AL_StartSleepAtBed into <tag>_approach/<tag>_pose)
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

    int nIndex = GetLocalInt(oNpc, "r_idx");
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

    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        // Sleep waypoint is valid only when configured via al_bed_tag
        // (resolved to <tag>_approach/<tag>_pose).
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT
            && GetTag(oObj) == sRouteTag
            && GetLocalString(oObj, "al_bed_tag") != "")
        {
            float fDist = GetDistanceBetweenLocations(GetLocation(oObj), lRoutePoint);
            if (!GetIsObjectValid(oBest) || fDist < fBestDist)
            {
                oBest = oObj;
                fBestDist = fDist;
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    return oBest;
}
