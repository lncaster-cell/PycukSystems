// NPC activity helpers: apply per-slot activity animations without tag searches.

#include "al_acts_inc"
#include "al_constants_inc"
#include "al_debug_inc"
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

string AL_AppendDegradeReasonCode(string sReasonCodes, string sReasonCode)
{
    if (sReasonCode == "")
    {
        return sReasonCodes;
    }

    if (sReasonCodes == "")
    {
        return sReasonCode;
    }

    return sReasonCodes + "," + sReasonCode;
}

string AL_GetActivityName(int nActivity)
{
    return IntToString(nActivity);
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

void AL_ClearAreaPairKeyIfStale(object oArea, string sAreaKey)
{
    if (!GetIsObjectValid(oArea) || sAreaKey == "")
    {
        return;
    }

    object oAreaPair = GetLocalObject(oArea, sAreaKey);
    if (GetIsObjectValid(oAreaPair) && GetArea(oAreaPair) != oArea)
    {
        DeleteLocalObject(oArea, sAreaKey);
    }
}

void AL_RevalidateAreaPairLinksForWake(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        DeleteLocalObject(oNpc, "al_training_partner");
        DeleteLocalObject(oNpc, "al_bar_pair");
        return;
    }

    int bDebug = AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1);
    int bClearedTraining = FALSE;
    int bClearedBar = FALSE;

    object oTrainingPartner = GetLocalObject(oNpc, "al_training_partner");
    if (GetIsObjectValid(oTrainingPartner))
    {
        if (GetArea(oTrainingPartner) != oArea
            || GetLocalObject(oTrainingPartner, "al_training_partner") != oNpc)
        {
            DeleteLocalObject(oNpc, "al_training_partner");
            bClearedTraining = TRUE;
        }
    }

    object oBarPair = GetLocalObject(oNpc, "al_bar_pair");
    if (GetIsObjectValid(oBarPair))
    {
        if (GetArea(oBarPair) != oArea
            || GetLocalObject(oBarPair, "al_bar_pair") != oNpc)
        {
            DeleteLocalObject(oNpc, "al_bar_pair");
            bClearedBar = TRUE;
        }
    }

    // Keep area-level runtime pair cache clean so slot wake/resync never reuses stale links.
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc1");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc2");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_bartender");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_barmaid");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc1_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc2_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_bartender_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_barmaid_ref");

    if (bDebug)
    {
        if (bClearedTraining)
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: wake revalidation cleared stale training link for " + GetName(oNpc) + ".");
        }

        if (bClearedBar)
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: wake revalidation cleared stale bar link for " + GetName(oNpc) + ".");
        }
    }
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
    object oNpcArea = GetArea(oNpc);
    // Cross-area references are not considered valid for paired placements.
    int bHasTrainingPartner = GetIsObjectValid(oTrainingPartner);
    int bHasBarPair = GetIsObjectValid(oBarPair);
    int bTrainingPartnerInArea = bHasTrainingPartner && GetArea(oTrainingPartner) == oNpcArea;
    int bBarPairInArea = bHasBarPair && GetArea(oBarPair) == oNpcArea;
    int bTrainingPartnerValid = bHasTrainingPartner && bTrainingPartnerInArea;
    int bBarPairValid = bHasBarPair && bBarPairInArea;

    int bRouteTagMismatch = !AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity);
    int bTrainingPartnerMissing = bNeedsTrainingPartner && !bHasTrainingPartner;
    int bTrainingPartnerInvalidArea = bNeedsTrainingPartner && bHasTrainingPartner && !bTrainingPartnerInArea;
    int bBarPairMissing = bNeedsBarPair && !bHasBarPair;
    int bBarPairInvalidArea = bNeedsBarPair && bHasBarPair && !bBarPairInArea;

    if (bRouteTagMismatch
        || (bNeedsTrainingPartner && !bTrainingPartnerValid)
        || (bNeedsBarPair && !bBarPairValid))
    {
        if (GetIsObjectValid(oNpcArea) && AL_IsDebugLevelEnabled(oNpcArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            string sReasonCodes = "";
            if (bRouteTagMismatch)
            {
                sReasonCodes = AL_AppendDegradeReasonCode(sReasonCodes, "route_tag_mismatch");
            }

            if (bTrainingPartnerMissing || bBarPairMissing)
            {
                sReasonCodes = AL_AppendDegradeReasonCode(sReasonCodes, "missing_partner");
            }

            if (bTrainingPartnerInvalidArea || bBarPairInvalidArea)
            {
                sReasonCodes = AL_AppendDegradeReasonCode(sReasonCodes, "invalid_pair_area");
            }

            AL_SendDebugMessageToAreaPCs(oNpcArea,
                "AL: activity degrade; reason_codes=" + sReasonCodes
                + "; slot=" + IntToString(nSlot)
                + "; source_activity=" + AL_GetActivityName(nActivity));
        }

        nActivity = AL_ACT_NPC_ACT_ONE;
    }

    int bLocateWrapper = AL_IsLocateWrapperActivity(nActivity);
    string sCustom = bLocateWrapper
        ? AL_GetLocateWrapperCustomAnims(nActivity)
        : AL_GetActivityCustomAnims(nActivity);
    if (sCustom == "" && nActivity != AL_ACT_NPC_ACT_ONE)
    {
        int nOriginalActivity = nActivity;
        nActivity = AL_ACT_NPC_ACT_ONE;
        sCustom = AL_GetActivityCustomAnims(AL_ACT_NPC_ACT_ONE);

        object oArea = GetArea(oNpc);
        if (GetIsObjectValid(oArea) && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: fallback to AL_ACT_NPC_ACT_ONE due to empty custom anim list for activity "
                + IntToString(nOriginalActivity) + ".");
        }
    }

    if (sCustom != "")
    {
        string sAnim = AL_SelectRandomToken(sCustom);
        int bLooping = AL_ShouldLoopCustomAnimation(nActivity);
        AL_PlayCustomAnimation(oNpc, sAnim, bLooping);
        return;
    }

}
