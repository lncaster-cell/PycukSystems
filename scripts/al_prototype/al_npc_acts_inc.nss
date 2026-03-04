// NPC activity helpers: apply per-slot activity animations without tag searches.

#include "al_acts_inc"
#include "al_constants_inc"
#include "al_npc_routes"

void AL_PlayCustomAnimation(object oNpc, string sAnimation, int bLooping);

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

int AL_StartSleepAtBed(object oNpc, object oSleepWp)
{
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oSleepWp))
    {
        AL_QueueSleepAnimationLoop(oNpc);
        DeleteLocalInt(oNpc, "al_sleep_docked");
        DeleteLocalString(oNpc, "al_sleep_approach_tag");
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
        string sApproachTag = GetLocalString(oSleepWp, "al_bed_approach_wp");
        oApproachWp = AL_FindWaypointByTagInArea(oArea, sApproachTag);
    }

    if (!GetIsObjectValid(oPoseWp))
    {
        string sPoseTag = GetLocalString(oSleepWp, "al_bed_pose_wp");
        oPoseWp = AL_FindWaypointByTagInArea(oArea, sPoseTag);
    }

    if (!GetIsObjectValid(oApproachWp))
    {
        AL_QueueSleepAnimationLoop(oNpc);
        DeleteLocalInt(oNpc, "al_sleep_docked");
        DeleteLocalString(oNpc, "al_sleep_approach_tag");
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
    AssignCommand(oNpc, ActionDoCommand(SetCollision(oNpc, TRUE)));

    DeleteLocalInt(oNpc, "al_sleep_docked");
    DeleteLocalString(oNpc, "al_sleep_approach_tag");
}

// Finds nearest sleep route waypoint that has bed config via one of:
// - al_bed_tag (resolved by AL_StartSleepAtBed into <tag>_approach/<tag>_pose)
// - al_bed_approach_wp
// - al_bed_pose_wp
object AL_FindSleepWaypointForSlot(object oNpc, int nSlot)
{
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
    if (nIndex < 0)
    {
        nIndex = 0;
    }

    location lRoutePoint = AL_GetRoutePoint(oNpc, nSlot, nIndex);
    object oBest = OBJECT_INVALID;
    float fBestDist = 999999.0;

    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        // Sleep waypoint is valid if configured via one of 3 options:
        // 1) al_bed_tag (resolved to <tag>_approach/<tag>_pose)
        // 2) al_bed_approach_wp
        // 3) al_bed_pose_wp
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT
            && GetTag(oObj) == sRouteTag
            && (GetLocalString(oObj, "al_bed_tag") != ""
                || GetLocalString(oObj, "al_bed_approach_wp") != ""
                || GetLocalString(oObj, "al_bed_pose_wp") != ""))
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

int AL_GetWaypointActivityForSlot(object oNpc, int nSlot)
{
    if (AL_GetRouteCount(oNpc, nSlot) <= 0)
    {
        return AL_ACT_NPC_ACT_ONE;
    }

    int nIndex = GetLocalInt(oNpc, "r_idx");
    if (nIndex < 0)
    {
        nIndex = 0;
    }
    else if (nIndex >= AL_GetRouteCount(oNpc, nSlot))
    {
        nIndex = 0;
    }

    int nRouteActivity = AL_GetRoutePointActivity(oNpc, nSlot, nIndex);
    if (nRouteActivity <= 0)
    {
        return AL_ACT_NPC_ACT_ONE;
    }

    return nRouteActivity;
}

string AL_TrimToken(string sToken)
{
    int iLen = GetStringLength(sToken);
    int iStart = 0;
    int iEnd = iLen - 1;

    while (iStart <= iEnd && GetSubString(sToken, iStart, 1) == " ")
    {
        iStart++;
    }

    while (iEnd >= iStart && GetSubString(sToken, iEnd, 1) == " ")
    {
        iEnd--;
    }

    if (iEnd < iStart)
    {
        return "";
    }

    return GetSubString(sToken, iStart, iEnd - iStart + 1);
}

string AL_SelectRandomToken(string sList)
{
    if (sList == "")
    {
        return "";
    }

    int i = 0;
    int iLen = GetStringLength(sList);
    int iStart = 0;
    int iToken = 0;
    string sSelected = "";

    while (i <= iLen)
    {
        if (i == iLen || GetSubString(sList, i, 1) == ",")
        {
            string sToken = AL_TrimToken(GetSubString(sList, iStart, i - iStart));
            // Allow "dirty" lists with extra commas by skipping empty tokens.
            if (sToken != "")
            {
                iToken++;
                if (Random(iToken) == 0)
                {
                    sSelected = sToken;
                }
            }
            iStart = i + 1;
        }
        i++;
    }

    return sSelected;
}

int AL_ShouldLoopCustomAnimation(int nActivity)
{
    if (nActivity == AL_ACT_NPC_MIDNIGHT_BED
        || nActivity == AL_ACT_NPC_SLEEP_BED
        || nActivity == AL_ACT_NPC_MIDNIGHT_90
        || nActivity == AL_ACT_NPC_SLEEP_90)
    {
        return TRUE;
    }

    return FALSE;
}

void AL_PlayCustomAnimation(object oNpc, string sAnimation, int bLooping)
{
    if (sAnimation == "")
    {
        return;
    }

    PlayCustomAnimation(oNpc, sAnimation, bLooping, 1.0);
}


// Requirement checks avoid tag searches by relying on prebuilt locals/routes:
// - Routes for pacing/WWP use locals r<slot>_n / r<slot>_<idx> (see AL_NPC_Routes_Inc).
// - Training partners are set via local object "al_training_partner" on the NPC.
// - Bar pair NPCs are set via local object "al_bar_pair" on the NPC.
int AL_ActivityHasRequiredRoute(object oNpc, int nSlot, int nActivity)
{
    string sWaypointTag = AL_GetActivityWaypointTag(nActivity);
    if (sWaypointTag == "")
    {
        return TRUE;
    }

    return AL_GetRouteTag(oNpc, nSlot) == sWaypointTag;
}

void AL_ApplyActivityForSlot(object oNpc, int nSlot)
{
    if (nSlot < 0 || nSlot > AL_SLOT_MAX)
    {
        return;
    }

    int nActivity = AL_GetWaypointActivityForSlot(oNpc, nSlot);

    if (nActivity == AL_ACT_NPC_HIDDEN)
    {
        return;
    }

    int bNeedsTrainingPartner = AL_ActivityRequiresTrainingPartner(nActivity);
    int bNeedsBarPair = AL_ActivityRequiresBarPair(nActivity);
    object oTrainingPartner = GetLocalObject(oNpc, "al_training_partner");
    object oBarPair = GetLocalObject(oNpc, "al_bar_pair");
    // Cross-area references are not considered valid for paired placements.
    int bTrainingPartnerValid = GetIsObjectValid(oTrainingPartner)
        && GetArea(oTrainingPartner) == GetArea(oNpc);
    int bBarPairValid = GetIsObjectValid(oBarPair)
        && GetArea(oBarPair) == GetArea(oNpc);

    if (!AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity)
        || (bNeedsTrainingPartner && !bTrainingPartnerValid)
        || (bNeedsBarPair && !bBarPairValid))
    {
        nActivity = AL_ACT_NPC_ACT_ONE;
    }

    int bLocateWrapper = AL_IsLocateWrapperActivity(nActivity);
    string sCustom = bLocateWrapper
        ? AL_GetLocateWrapperCustomAnims(nActivity)
        : AL_GetActivityCustomAnims(nActivity);
    if (sCustom != "")
    {
        string sAnim = AL_SelectRandomToken(sCustom);
        int bLooping = AL_ShouldLoopCustomAnimation(nActivity);
        AL_PlayCustomAnimation(oNpc, sAnim, bLooping);
        return;
    }

}
