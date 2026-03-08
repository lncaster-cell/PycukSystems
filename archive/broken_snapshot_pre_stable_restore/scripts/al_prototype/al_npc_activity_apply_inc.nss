// NPC activity resolve/apply helpers + custom animation utilities.

#include "al_acts_inc"
#include "al_constants_inc"
#include "al_debug_inc"
#include "al_npc_routes"

// Include layering contract (one-way):
// - al_npc_activity_apply_inc -> {al_acts_inc, al_constants_inc, al_debug_inc, al_npc_routes}
// - al_npc_sleep_inc          -> {al_npc_activity_apply_inc}
// - al_npc_acts_inc           -> compatibility wrapper only (no runtime logic)
//                                 forwards to {al_npc_activity_apply_inc, al_npc_sleep_inc, al_npc_pair_revalidate_inc}.
// Entrypoints should include only the highest-level include they need.

int AL_GetWaypointActivityForSlot(object oNpc, int nSlot)
{
    if (AL_GetRouteCount(oNpc, nSlot) <= 0)
    {
        return AL_ACT_NPC_ACT_ONE;
    }

    int nIndex = GetLocalInt(oNpc, AL_L_ROUTE_INDEX);
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
// - Training partners are set via local object AL_L_TRAINING_PARTNER on the NPC.
// - Bar pair NPCs are set via local object AL_L_BAR_PAIR on the NPC.
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
    object oTrainingPartner = GetLocalObject(oNpc, AL_L_TRAINING_PARTNER);
    object oBarPair = GetLocalObject(oNpc, AL_L_BAR_PAIR);
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
