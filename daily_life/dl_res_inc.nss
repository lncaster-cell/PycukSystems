#include "dl_activity_archive_anim_inc"

// Step 05+: resolver/materialization skeleton.
// Scope: EARLY_WORKER sleep window + basic BLACKSMITH/GATE_POST/TRADER WORK/SLEEP window split.

const string DL_L_NPC_DIRECTIVE = "dl_npc_directive";
const string DL_L_NPC_MAT_REQ = "dl_npc_mat_req";
const string DL_L_NPC_MAT_TAG = "dl_npc_mat_tag";
const string DL_L_NPC_DIALOGUE_MODE = "dl_npc_dialogue_mode";
const string DL_L_NPC_SERVICE_MODE = "dl_npc_service_mode";
const string DL_L_NPC_PROFILE_ID = "dl_profile_id";
const string DL_L_NPC_STATE = "dl_state";
const string DL_L_NPC_SLEEP_PHASE = "dl_npc_sleep_phase";
const string DL_L_NPC_SLEEP_STATUS = "dl_npc_sleep_status";
const string DL_L_NPC_SLEEP_TARGET = "dl_npc_sleep_target";
const string DL_L_NPC_SLEEP_DIAGNOSTIC = "dl_npc_sleep_diagnostic";
const string DL_L_NPC_WORK_KIND = "dl_npc_work_kind";
const string DL_L_NPC_WORK_TARGET = "dl_npc_work_target";
const string DL_L_NPC_WORK_STATUS = "dl_npc_work_status";
const string DL_L_NPC_WORK_DIAGNOSTIC = "dl_npc_work_diagnostic";
const string DL_L_NPC_GUARD_SHIFT_START = "dl_guard_shift_start";
const string DL_L_NPC_ACTIVITY_ID = "dl_npc_activity_id";
const string DL_L_NPC_ANIM_SET = "dl_npc_anim_set";

const string DL_PROFILE_EARLY_WORKER = "early_worker";
const string DL_PROFILE_BLACKSMITH = "blacksmith";
const string DL_PROFILE_GATE_POST = "gate_post";
const string DL_PROFILE_TRADER = "trader";

const string DL_STATE_IDLE = "idle";
const string DL_STATE_SLEEP = "sleep";
const string DL_STATE_WORK = "work";
const string DL_STATE_SOCIAL = "social";

const string DL_DIALOGUE_IDLE = "idle";
const string DL_DIALOGUE_SLEEP = "sleep";
const string DL_DIALOGUE_WORK = "work";
const string DL_DIALOGUE_SOCIAL = "social";

const string DL_SERVICE_OFF = "off";
const string DL_SERVICE_AVAILABLE = "available";

const string DL_MAT_SLEEP = "sleep";
const string DL_MAT_WORK = "work";
const string DL_MAT_SOCIAL = "social";

const int DL_DIR_NONE = 0;
const int DL_DIR_SLEEP = 1;
const int DL_DIR_WORK = 2;
const int DL_DIR_SOCIAL = 3;
const int DL_SLEEP_PHASE_NONE = 0;
const int DL_SLEEP_PHASE_MOVING = 1;
const int DL_SLEEP_PHASE_JUMPING = 2;
const int DL_SLEEP_PHASE_ON_BED = 3;

const float DL_SLEEP_APPROACH_RADIUS = 1.50;
const float DL_SLEEP_BED_RADIUS = 1.10;
const float DL_WORK_ANCHOR_RADIUS = 1.60;

const int DL_GUARD_SHIFT_HOURS = 9;

const string DL_WORK_KIND_FORGE = "forge";
const string DL_WORK_KIND_CRAFT = "craft";
const string DL_WORK_KIND_POST = "post";
const string DL_WORK_KIND_TRADE = "trade";

int DL_NormalizeHour(int nHour)
{
    while (nHour < 0)
    {
        nHour = nHour + 24;
    }
    while (nHour > 23)
    {
        nHour = nHour - 24;
    }
    return nHour;
}

int DL_IsEarlyWorkerSleepHour(int nHour)
{
    nHour = DL_NormalizeHour(nHour);
    return nHour >= 22 || nHour < 6;
}

int DL_IsBlacksmithWorkHour(int nHour)
{
    nHour = DL_NormalizeHour(nHour);
    return nHour >= 8 && nHour < 18;
}

int DL_IsTraderWorkHour(int nHour)
{
    nHour = DL_NormalizeHour(nHour);
    return nHour >= 8 && nHour < 18;
}

int DL_IsHourInShiftWindow(int nHour, int nStartHour, int nDuration)
{
    nHour = DL_NormalizeHour(nHour);
    nStartHour = DL_NormalizeHour(nStartHour);

    int nOffset = nHour - nStartHour;
    if (nOffset < 0)
    {
        nOffset = nOffset + 24;
    }

    return nOffset >= 0 && nOffset < nDuration;
}

int DL_IsGatePostWorkHour(object oNpc, int nHour)
{
    return DL_IsHourInShiftWindow(nHour, GetLocalInt(oNpc, DL_L_NPC_GUARD_SHIFT_START), DL_GUARD_SHIFT_HOURS);
}

int DL_ResolveNpcDirectiveAtHour(object oNpc, int nHour)
{
    if (!GetIsObjectValid(oNpc))
    {
        return DL_DIR_NONE;
    }

    if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_EARLY_WORKER)
    {
        if (DL_IsEarlyWorkerSleepHour(nHour))
        {
            return DL_DIR_SLEEP;
        }
    }
    else if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_BLACKSMITH)
    {
        if (DL_IsEarlyWorkerSleepHour(nHour))
        {
            return DL_DIR_SLEEP;
        }

        if (DL_IsBlacksmithWorkHour(nHour))
        {
            return DL_DIR_WORK;
        }
        return DL_DIR_SLEEP;
    }
    else if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_GATE_POST)
    {
        if (DL_IsGatePostWorkHour(oNpc, nHour))
        {
            return DL_DIR_WORK;
        }

        return DL_DIR_SLEEP;
    }
    else if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_TRADER)
    {
        if (DL_IsTraderWorkHour(nHour))
        {
            return DL_DIR_WORK;
        }

        return DL_DIR_SLEEP;
    }

    return DL_DIR_NONE;
}

int DL_ResolveNpcDirective(object oNpc)
{
    return DL_ResolveNpcDirectiveAtHour(oNpc, GetTimeHour());
}

void DL_ApplyMaterializationSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nDirective == DL_DIR_SLEEP)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_SLEEP);
        return;
    }

    if (nDirective == DL_DIR_WORK)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_WORK);
        return;
    }

    if (nDirective == DL_DIR_SOCIAL)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_SOCIAL);
        return;
    }

    DeleteLocalInt(oNpc, DL_L_NPC_MAT_REQ);
    DeleteLocalString(oNpc, DL_L_NPC_MAT_TAG);
}

object DL_GetSleepWaypointByTag(string sTag)
{
    if (sTag == "")
    {
        return OBJECT_INVALID;
    }

    object oWp = GetWaypointByTag(sTag);
    if (!GetIsObjectValid(oWp))
    {
        return OBJECT_INVALID;
    }

    return oWp;
}

object DL_GetWorkWaypointByTag(string sTag)
{
    if (sTag == "")
    {
        return OBJECT_INVALID;
    }

    object oWp = GetWaypointByTag(sTag);
    if (!GetIsObjectValid(oWp))
    {
        return OBJECT_INVALID;
    }

    return oWp;
}

int DL_IsSleepWaypointInNpcArea(object oNpc, object oWp)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oWp))
    {
        return FALSE;
    }

    return GetArea(oWp) == GetArea(oNpc);
}

int DL_IsWorkWaypointInNpcArea(object oNpc, object oWp)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oWp))
    {
        return FALSE;
    }

    return GetArea(oWp) == GetArea(oNpc);
}

int DL_IsSleepWaypointTagInvalidArea(object oNpc, string sTag)
{
    object oWp = DL_GetSleepWaypointByTag(sTag);
    if (!GetIsObjectValid(oWp))
    {
        return FALSE;
    }

    return !DL_IsSleepWaypointInNpcArea(oNpc, oWp);
}

object DL_ResolveSleepApproachWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetSleepWaypointByTag("dl_sleep_" + sNpcTag + "_approach");
    if (DL_IsSleepWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetSleepWaypointByTag("dl_sleep_approach");
    if (DL_IsSleepWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

object DL_ResolveSleepBedWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetSleepWaypointByTag("dl_sleep_" + sNpcTag + "_bed");
    if (DL_IsSleepWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetSleepWaypointByTag("dl_sleep_bed");
    if (DL_IsSleepWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

object DL_ResolveBlacksmithForgeWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetWorkWaypointByTag("dl_work_" + sNpcTag + "_forge");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetWorkWaypointByTag("dl_work_forge");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

object DL_ResolveBlacksmithCraftWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetWorkWaypointByTag("dl_work_" + sNpcTag + "_craft");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetWorkWaypointByTag("dl_work_craft");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

object DL_ResolveGatePostWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetWorkWaypointByTag("dl_work_" + sNpcTag + "_post");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetWorkWaypointByTag("dl_work_post");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

object DL_ResolveTraderWaypoint(object oNpc)
{
    string sNpcTag = GetTag(oNpc);
    object oWp = DL_GetWorkWaypointByTag("dl_work_" + sNpcTag + "_trade");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    oWp = DL_GetWorkWaypointByTag("dl_work_trade");
    if (DL_IsWorkWaypointInNpcArea(oNpc, oWp))
    {
        return oWp;
    }

    return OBJECT_INVALID;
}

void DL_ClearSleepExecutionState(object oNpc)
{
    DeleteLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_TARGET);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
}

void DL_ClearWorkExecutionState(object oNpc)
{
    DeleteLocalString(oNpc, DL_L_NPC_WORK_KIND);
    DeleteLocalString(oNpc, DL_L_NPC_WORK_TARGET);
    DeleteLocalString(oNpc, DL_L_NPC_WORK_STATUS);
    DeleteLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC);
}

void DL_ClearActivityPresentation(object oNpc)
{
    DeleteLocalInt(oNpc, DL_L_NPC_ACTIVITY_ID);
    DeleteLocalString(oNpc, DL_L_NPC_ANIM_SET);
}

void DL_SetActivityPresentation(object oNpc, int nActivityId, string sAnimSet)
{
    SetLocalInt(oNpc, DL_L_NPC_ACTIVITY_ID, nActivityId);
    SetLocalString(oNpc, DL_L_NPC_ANIM_SET, sAnimSet);
}

void DL_ApplyArchiveActivityPresentation(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nDirective == DL_DIR_SLEEP)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_SLEEP_BED, DL_ARCH_ANIMS_SLEEP_BED);
        return;
    }

    if (nDirective == DL_DIR_WORK && GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_BLACKSMITH)
    {
        if (GetLocalString(oNpc, DL_L_NPC_WORK_KIND) == DL_WORK_KIND_CRAFT)
        {
            DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_FORGE_MULTI, DL_ARCH_ANIMS_CRAFT);
            return;
        }

        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_FORGE, DL_ARCH_ANIMS_FORGE);
        return;
    }

    if (nDirective == DL_DIR_WORK && GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_GATE_POST)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_GUARD, DL_ARCH_ANIMS_GUARD);
        return;
    }

    if (nDirective == DL_DIR_WORK && GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_TRADER)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_MERCHANT_MULTI, DL_ARCH_ANIMS_TRADE);
        return;
    }

    DL_ClearActivityPresentation(oNpc);
}

string DL_ResolveBlacksmithWorkKindAtHour(int nHour)
{
    nHour = DL_NormalizeHour(nHour);
    if ((nHour % 2) == 0)
    {
        return DL_WORK_KIND_FORGE;
    }

    return DL_WORK_KIND_CRAFT;
}

string DL_TrimAnimToken(string sToken)
{
    int nStart = 0;
    int nEnd = GetStringLength(sToken);

    while (nStart < nEnd && GetSubString(sToken, nStart, 1) == " ")
    {
        nStart = nStart + 1;
    }

    while (nEnd > nStart && GetSubString(sToken, nEnd - 1, 1) == " ")
    {
        nEnd = nEnd - 1;
    }

    return GetSubString(sToken, nStart, nEnd - nStart);
}

string DL_GetFirstAnimToken(string sAnimSet)
{
    int nComma = FindSubString(sAnimSet, ",");
    if (nComma < 0)
    {
        return DL_TrimAnimToken(sAnimSet);
    }

    return DL_TrimAnimToken(GetSubString(sAnimSet, 0, nComma));
}

string DL_GetSecondAnimToken(string sAnimSet)
{
    int nComma = FindSubString(sAnimSet, ",");
    if (nComma < 0)
    {
        return "";
    }

    string sTail = GetSubString(sAnimSet, nComma + 1, GetStringLength(sAnimSet) - (nComma + 1));
    int nSecondComma = FindSubString(sTail, ",");
    if (nSecondComma < 0)
    {
        return DL_TrimAnimToken(sTail);
    }

    return DL_TrimAnimToken(GetSubString(sTail, 0, nSecondComma));
}

void DL_PlaySleepAnimation(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    string sAnimSet = GetLocalString(oNpc, DL_L_NPC_ANIM_SET);
    if (sAnimSet == "")
    {
        sAnimSet = DL_ARCH_ANIMS_SLEEP_BED;
    }

    string sLoopAnim = DL_GetSecondAnimToken(sAnimSet);
    if (sLoopAnim == "")
    {
        sLoopAnim = DL_GetFirstAnimToken(sAnimSet);
    }

    if (sLoopAnim == "")
    {
        return;
    }

    PlayCustomAnimation(oNpc, sLoopAnim, TRUE);
}

void DL_PlayWorkAnimation(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    string sAnim = DL_GetFirstAnimToken(GetLocalString(oNpc, DL_L_NPC_ANIM_SET));
    if (sAnim == "")
    {
        return;
    }

    PlayCustomAnimation(oNpc, sAnim, TRUE);
}

void DL_ExecuteSleepDirective(object oNpc)
{
    object oApproach = DL_ResolveSleepApproachWaypoint(oNpc);
    object oBed = DL_ResolveSleepBedWaypoint(oNpc);
    int bInvalidArea = FALSE;

    if (GetIsObjectValid(oApproach) && !DL_IsSleepWaypointInNpcArea(oNpc, oApproach))
    {
        oApproach = OBJECT_INVALID;
        bInvalidArea = TRUE;
    }
    if (GetIsObjectValid(oBed) && !DL_IsSleepWaypointInNpcArea(oNpc, oBed))
    {
        oBed = OBJECT_INVALID;
        bInvalidArea = TRUE;
    }

    if (!GetIsObjectValid(oApproach) || !GetIsObjectValid(oBed))
    {
        SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_NONE);
        SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "missing_waypoints");
        if (bInvalidArea)
        {
            SetLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC, "sleep_target_invalid_area");
        }
        else
        {
            DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
        }
        DeleteLocalString(oNpc, DL_L_NPC_SLEEP_TARGET);
        return;
    }

    SetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET, GetTag(oBed));
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);

    location lApproach = GetLocation(oApproach);
    location lBed = GetLocation(oBed);
    int nPhase = GetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE);
    string sStatus = GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
    int bCommittedToBed = nPhase == DL_SLEEP_PHASE_JUMPING || nPhase == DL_SLEEP_PHASE_ON_BED;

    if (!bCommittedToBed && GetDistanceBetweenLocations(GetLocation(oNpc), lApproach) > DL_SLEEP_APPROACH_RADIUS)
    {
        if (nPhase != DL_SLEEP_PHASE_MOVING || sStatus != "moving_to_approach")
        {
            SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_MOVING);
            SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "moving_to_approach");
            AssignCommand(oNpc, ClearAllActions(TRUE));
            AssignCommand(oNpc, ActionMoveToLocation(lApproach, TRUE));
        }
        return;
    }

    if (!bCommittedToBed)
    {
        SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_JUMPING);
        SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "approach_reached");
        nPhase = DL_SLEEP_PHASE_JUMPING;
        sStatus = "approach_reached";
    }

    if (GetDistanceBetweenLocations(GetLocation(oNpc), lBed) > DL_SLEEP_BED_RADIUS)
    {
        if (nPhase != DL_SLEEP_PHASE_JUMPING || sStatus != "jumping_to_bed")
        {
            SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_JUMPING);
            SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "jumping_to_bed");
            AssignCommand(oNpc, ClearAllActions(TRUE));
            AssignCommand(oNpc, ActionJumpToLocation(lBed));
        }
        return;
    }

    if (nPhase != DL_SLEEP_PHASE_ON_BED || sStatus != "on_bed")
    {
        DL_PlaySleepAnimation(oNpc);
    }

    SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_ON_BED);
    SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "on_bed");
}

void DL_ExecuteWorkDirective(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    string sProfile = GetLocalString(oNpc, DL_L_NPC_PROFILE_ID);

    if (sProfile != DL_PROFILE_BLACKSMITH && sProfile != DL_PROFILE_GATE_POST && sProfile != DL_PROFILE_TRADER)
    {
        DL_ClearWorkExecutionState(oNpc);
        return;
    }

    if (sProfile == DL_PROFILE_BLACKSMITH)
    {
        string sKind = DL_ResolveBlacksmithWorkKindAtHour(GetTimeHour());
        object oForge = DL_ResolveBlacksmithForgeWaypoint(oNpc);
        object oCraft = DL_ResolveBlacksmithCraftWaypoint(oNpc);

        if (!GetIsObjectValid(oForge) || !GetIsObjectValid(oCraft))
        {
            SetLocalString(oNpc, DL_L_NPC_WORK_KIND, sKind);
            SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "missing_waypoints");
            SetLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC, "need_forge_and_craft_waypoints");
            DeleteLocalString(oNpc, DL_L_NPC_WORK_TARGET);
            DL_ClearActivityPresentation(oNpc);
            return;
        }

        object oTarget = sKind == DL_WORK_KIND_CRAFT ? oCraft : oForge;
        location lTarget = GetLocation(oTarget);

        SetLocalString(oNpc, DL_L_NPC_WORK_KIND, sKind);
        SetLocalString(oNpc, DL_L_NPC_WORK_TARGET, GetTag(oTarget));
        DeleteLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC);

        if (GetDistanceBetweenLocations(GetLocation(oNpc), lTarget) > DL_WORK_ANCHOR_RADIUS)
        {
            if (GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) != "moving_to_anchor")
            {
                SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "moving_to_anchor");
                AssignCommand(oNpc, ClearAllActions(TRUE));
                AssignCommand(oNpc, ActionMoveToLocation(lTarget, TRUE));
            }
            return;
        }

        SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "on_anchor");
        DL_ApplyArchiveActivityPresentation(oNpc, DL_DIR_WORK);
        DL_PlayWorkAnimation(oNpc);
        return;
    }

    if (sProfile == DL_PROFILE_GATE_POST)
    {
        object oPost = DL_ResolveGatePostWaypoint(oNpc);

        if (!GetIsObjectValid(oPost))
        {
            SetLocalString(oNpc, DL_L_NPC_WORK_KIND, DL_WORK_KIND_POST);
            SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "missing_waypoints");
            SetLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC, "need_post_waypoint");
            DeleteLocalString(oNpc, DL_L_NPC_WORK_TARGET);
            DL_ClearActivityPresentation(oNpc);
            return;
        }

        location lTarget = GetLocation(oPost);

        SetLocalString(oNpc, DL_L_NPC_WORK_KIND, DL_WORK_KIND_POST);
        SetLocalString(oNpc, DL_L_NPC_WORK_TARGET, GetTag(oPost));
        DeleteLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC);

        if (GetDistanceBetweenLocations(GetLocation(oNpc), lTarget) > DL_WORK_ANCHOR_RADIUS)
        {
            if (GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) != "moving_to_anchor")
            {
                SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "moving_to_anchor");
                AssignCommand(oNpc, ClearAllActions(TRUE));
                AssignCommand(oNpc, ActionMoveToLocation(lTarget, TRUE));
            }
            return;
        }

        SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "on_anchor");
        DL_ApplyArchiveActivityPresentation(oNpc, DL_DIR_WORK);
        DL_PlayWorkAnimation(oNpc);
        return;
    }

    object oTrade = DL_ResolveTraderWaypoint(oNpc);

    if (!GetIsObjectValid(oTrade))
    {
        SetLocalString(oNpc, DL_L_NPC_WORK_KIND, DL_WORK_KIND_TRADE);
        SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "missing_waypoints");
        SetLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC, "need_trade_waypoint");
        DeleteLocalString(oNpc, DL_L_NPC_WORK_TARGET);
        DL_ClearActivityPresentation(oNpc);
        return;
    }

    location lTarget = GetLocation(oTrade);

    SetLocalString(oNpc, DL_L_NPC_WORK_KIND, DL_WORK_KIND_TRADE);
    SetLocalString(oNpc, DL_L_NPC_WORK_TARGET, GetTag(oTrade));
    DeleteLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC);

    if (GetDistanceBetweenLocations(GetLocation(oNpc), lTarget) > DL_WORK_ANCHOR_RADIUS)
    {
        if (GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) != "moving_to_anchor")
        {
            SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "moving_to_anchor");
            AssignCommand(oNpc, ClearAllActions(TRUE));
            AssignCommand(oNpc, ActionMoveToLocation(lTarget, TRUE));
        }
        return;
    }

    SetLocalString(oNpc, DL_L_NPC_WORK_STATUS, "on_anchor");
    DL_ApplyArchiveActivityPresentation(oNpc, DL_DIR_WORK);
    DL_PlayWorkAnimation(oNpc);
}

void DL_SetInteractionModes(object oNpc, string sDialogue, string sService)
{
    SetLocalString(oNpc, DL_L_NPC_DIALOGUE_MODE, sDialogue);
    SetLocalString(oNpc, DL_L_NPC_SERVICE_MODE, sService);
}

void DL_ApplyDirectiveSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_DIRECTIVE, nDirective);

    if (nDirective == DL_DIR_SLEEP)
    {
        DL_ClearWorkExecutionState(oNpc);
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_SLEEP);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_SLEEP, DL_SERVICE_OFF);
        DL_ApplyArchiveActivityPresentation(oNpc, nDirective);
        DL_ExecuteSleepDirective(oNpc);
    }
    else if (nDirective == DL_DIR_WORK)
    {
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_WORK);

        if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == DL_PROFILE_GATE_POST)
        {
            DL_SetInteractionModes(oNpc, DL_DIALOGUE_WORK, DL_SERVICE_OFF);
        }
        else
        {
            DL_SetInteractionModes(oNpc, DL_DIALOGUE_WORK, DL_SERVICE_AVAILABLE);
        }

        DL_ClearSleepExecutionState(oNpc);
        DL_ExecuteWorkDirective(oNpc);
    }
    else if (nDirective == DL_DIR_SOCIAL)
    {
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_SOCIAL);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_SOCIAL, DL_SERVICE_OFF);
        DL_ClearSleepExecutionState(oNpc);
        DL_ClearWorkExecutionState(oNpc);
        DL_ClearActivityPresentation(oNpc);
    }
    else
    {
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_IDLE);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_IDLE, DL_SERVICE_OFF);
        DL_ClearSleepExecutionState(oNpc);
        DL_ClearWorkExecutionState(oNpc);
        DL_ClearActivityPresentation(oNpc);
    }

    DL_ApplyMaterializationSkeleton(oNpc, nDirective);
}
