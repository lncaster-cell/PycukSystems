const string DL_L_NPC_CACHE_SOCIAL_PARTNER_OBJ = "dl_cache_social_partner_obj";

void DL_ClearFocusExecutionState(object oNpc)
{
    DeleteLocalString(oNpc, DL_L_NPC_FOCUS_STATUS);
    DeleteLocalString(oNpc, DL_L_NPC_FOCUS_TARGET);
    DeleteLocalString(oNpc, DL_L_NPC_FOCUS_DIAGNOSTIC);
    DL_ClearTransitionExecutionState(oNpc);
}
object DL_ResolveSocialPartnerObject(object oNpc, string sPartnerTag)
{
    if (!GetIsObjectValid(oNpc) || sPartnerTag == "")
    {
        DeleteLocalObject(oNpc, DL_L_NPC_CACHE_SOCIAL_PARTNER_OBJ);
        return OBJECT_INVALID;
    }

    object oCached = GetLocalObject(oNpc, DL_L_NPC_CACHE_SOCIAL_PARTNER_OBJ);
    if (GetIsObjectValid(oCached) &&
        GetTag(oCached) == sPartnerTag &&
        DL_IsActivePipelineNpc(oCached))
    {
        return oCached;
    }

    object oPartner = GetObjectByTag(sPartnerTag);
    if (!DL_IsActivePipelineNpc(oPartner))
    {
        DeleteLocalObject(oNpc, DL_L_NPC_CACHE_SOCIAL_PARTNER_OBJ);
        return OBJECT_INVALID;
    }

    SetLocalObject(oNpc, DL_L_NPC_CACHE_SOCIAL_PARTNER_OBJ, oPartner);
    return oPartner;
}
int DL_ProgressFocusAtTarget(object oNpc, object oTarget, string sOnAnchorStatus, string sAnim)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oTarget))
    {
        return FALSE;
    }

    if (DL_WaypointHasTransition(oTarget))
    {
        if (DL_TryExecuteTransitionAtWaypoint(oNpc, oTarget))
        {
            return TRUE;
        }
    }

    if (GetDistanceBetween(oNpc, oTarget) > DL_WORK_ANCHOR_RADIUS)
    {
        if (GetLocalString(oNpc, DL_L_NPC_FOCUS_STATUS) != "moving_to_anchor")
        {
            SetLocalString(oNpc, DL_L_NPC_FOCUS_STATUS, "moving_to_anchor");
            SetLocalString(oNpc, DL_L_NPC_FOCUS_TARGET, GetTag(oTarget));
            DL_QueueMoveAction(oNpc, GetLocation(oTarget), TRUE);
        }
        return TRUE;
    }

    DL_ClearTransitionExecutionState(oNpc);
    SetLocalString(oNpc, DL_L_NPC_FOCUS_STATUS, sOnAnchorStatus);
    SetLocalString(oNpc, DL_L_NPC_FOCUS_TARGET, GetTag(oTarget));
    if (sAnim != "")
    {
        PlayCustomAnimation(oNpc, sAnim, TRUE);
    }
    DL_LogChatDebugEvent(oNpc, sOnAnchorStatus, sOnAnchorStatus + " anchor=" + GetTag(oTarget));
    return TRUE;
}
string DL_ResolveMealKind(object oNpc)
{
    int nNow = DL_GetNowMinuteOfDay();
    int nWake = DL_GetNpcWakeHour(oNpc);
    int nSleepHours = DL_GetNpcSleepHours(oNpc);
    int nSleepStart = DL_NormalizeMinuteOfDay((nWake * 60) - (nSleepHours * 60));
    int bWeekend = DL_GetWeekendType() != 0;
    int bHasWorkWindow = DL_NpcHasWorkDirectiveWindow(oNpc, bWeekend);
    int nShiftLen = bHasWorkWindow ? DL_GetNpcShiftLength(oNpc, bWeekend) : 0;
    int nShiftStartHour = DL_GetNpcShiftStart(oNpc);
    if (nShiftStartHour == 0 && GetLocalInt(oNpc, DL_L_NPC_SHIFT_LENGTH) <= 0 && bHasWorkWindow)
    {
        nShiftStartHour = 8;
    }
    int nShiftStart = nShiftStartHour * 60;
    string sTag = GetTag(oNpc);
    int nBreakfastStart = DL_NormalizeMinuteOfDay((nWake * 60) + DL_GetTagDeterministicOffset(sTag, 21, 10));
    int nLunchStart = DL_NormalizeMinuteOfDay(nShiftStart + 240 + DL_GetTagDeterministicOffset(sTag, 21, 10));
    int nDinnerStart = DL_NormalizeMinuteOfDay(nSleepStart - 75 + DL_GetTagDeterministicOffset(sTag, 21, 10));

    if (DL_MinuteInWindow(nNow, nBreakfastStart, 60))
    {
        return DL_MEAL_KIND_BREAKFAST;
    }
    if (nShiftLen >= 8 && DL_MinuteInWindow(nNow, nLunchStart, 30))
    {
        return DL_MEAL_KIND_LUNCH;
    }
    return DL_MEAL_KIND_DINNER;
}
object DL_ResolveMealWaypoint(object oNpc, string sMealKind)
{
    object oTargetArea = OBJECT_INVALID;
    if (sMealKind == DL_MEAL_KIND_LUNCH)
    {
        oTargetArea = DL_GetMealArea(oNpc);
        if (!GetIsObjectValid(oTargetArea))
        {
            oTargetArea = DL_GetWorkArea(oNpc);
            if (GetIsObjectValid(oTargetArea))
            {
                DL_LogChatDebugEvent(
                    oNpc,
                    "fallback_meal_work",
                    "fallback meal->work reason=missing_meal_area kind=" + sMealKind + " area=" + GetTag(oTargetArea)
                );
            }
        }
    }

    if (!GetIsObjectValid(oTargetArea))
    {
        oTargetArea = DL_GetHomeArea(oNpc);
        if (GetIsObjectValid(oTargetArea) && sMealKind == DL_MEAL_KIND_LUNCH)
        {
            DL_LogChatDebugEvent(
                oNpc,
                "fallback_meal_home",
                "fallback meal->home reason=missing_meal_and_work_area kind=" + sMealKind + " area=" + GetTag(oTargetArea)
            );
        }
    }

    return DL_GetAreaAnchorWaypoint(oNpc, oTargetArea, "dl_anchor_meal", DL_L_NPC_CACHE_MEAL, TRUE);
}
object DL_ResolveSocialWaypoint(object oNpc)
{
    object oArea = DL_GetSocialArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        oArea = DL_GetWorkArea(oNpc);
    }

    string sSlot = GetLocalString(oNpc, DL_L_NPC_SOCIAL_SLOT);
    string sAnchor = sSlot == "b" ? "dl_anchor_social_b" : "dl_anchor_social_a";
    string sCache = sSlot == "b" ? DL_L_NPC_CACHE_SOCIAL_B : DL_L_NPC_CACHE_SOCIAL_A;
    return DL_GetAreaAnchorWaypoint(oNpc, oArea, sAnchor, sCache, FALSE);
}
object DL_ResolvePublicWaypoint(object oNpc)
{
    object oArea = DL_GetPublicArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        oArea = DL_GetSocialArea(oNpc);
    }
    if (!GetIsObjectValid(oArea))
    {
        DL_LogMarkupIssueOnce(
            oNpc,
            "missing_public_area",
            "NPC " + GetTag(oNpc) + " has no public/social area for PUBLIC directive."
        );
        return OBJECT_INVALID;
    }
    return DL_GetAreaAnchorWaypoint(oNpc, oArea, "dl_anchor_public", DL_L_NPC_CACHE_PUBLIC, TRUE);
}
void DL_ExecuteMealDirective(object oNpc)
{
    string sMealKind = DL_ResolveMealKind(oNpc);
    object oMeal = DL_ResolveMealWaypoint(oNpc, sMealKind);
    if (!GetIsObjectValid(oMeal))
    {
        SetLocalString(oNpc, DL_L_NPC_FOCUS_DIAGNOSTIC, "missing_meal_anchor");
        return;
    }

    string sAnim = "siteat";
    if (sMealKind == DL_MEAL_KIND_BREAKFAST)
    {
        sAnim = "sitdrink";
    }
    else if ((DL_GetTagDeterministicOffset(GetTag(oNpc), 6, 0) % 6) == 0)
    {
        sAnim = "sitdrink";
    }

    DL_LogChatDebugEvent(
        oNpc,
        "target_meal",
        "target dir=MEAL area=" + GetTag(GetArea(oMeal)) + " anchor=" + GetTag(oMeal) + " kind=" + sMealKind
    );
    DL_ProgressFocusAtTarget(oNpc, oMeal, "on_meal_anchor_" + sMealKind, sAnim);
}
void DL_ExecutePublicDirective(object oNpc)
{
    object oPublic = DL_ResolvePublicWaypoint(oNpc);
    if (!GetIsObjectValid(oPublic))
    {
        SetLocalString(oNpc, DL_L_NPC_FOCUS_DIAGNOSTIC, "missing_public_anchor");
        return;
    }

    string sAnim = "pause";
    if ((DL_GetTagDeterministicOffset(GetTag(oNpc), 100, 0) % 2) == 0)
    {
        sAnim = "talk01";
    }
    DL_LogChatDebugEvent(
        oNpc,
        "target_public",
        "target dir=PUBLIC area=" + GetTag(GetArea(oPublic)) + " anchor=" + GetTag(oPublic)
    );
    DL_ProgressFocusAtTarget(oNpc, oPublic, "on_public_anchor", sAnim);
}
void DL_ExecuteSocialDirective(object oNpc)
{
    object oMe = DL_ResolveSocialWaypoint(oNpc);
    string sPartnerTag = GetLocalString(oNpc, DL_L_NPC_SOCIAL_PARTNER_TAG);
    if (!GetIsObjectValid(oMe) || sPartnerTag == "")
    {
        DL_LogChatDebugEvent(oNpc, "fallback_social_public", "fallback social->public reason=missing_social_anchor_or_partner");
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_PUBLIC);
        SetLocalString(oNpc, DL_L_NPC_DIALOGUE_MODE, DL_DIALOGUE_IDLE);
        DL_ExecutePublicDirective(oNpc);
        return;
    }

    object oPartner = DL_ResolveSocialPartnerObject(oNpc, sPartnerTag);
    if (!GetIsObjectValid(oPartner) || GetLocalInt(oPartner, DL_L_NPC_DIRECTIVE) != DL_DIR_SOCIAL)
    {
        DL_LogChatDebugEvent(oNpc, "fallback_social_public", "fallback social->public reason=partner_not_social");
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_PUBLIC);
        SetLocalString(oNpc, DL_L_NPC_DIALOGUE_MODE, DL_DIALOGUE_IDLE);
        DL_ExecutePublicDirective(oNpc);
        return;
    }

    object oPartnerWp = DL_ResolveSocialWaypoint(oPartner);
    if (!GetIsObjectValid(oPartnerWp))
    {
        DL_LogChatDebugEvent(oNpc, "fallback_social_public", "fallback social->public reason=partner_missing_social_anchor");
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_PUBLIC);
        SetLocalString(oNpc, DL_L_NPC_DIALOGUE_MODE, DL_DIALOGUE_IDLE);
        DL_ExecutePublicDirective(oNpc);
        return;
    }

    int bMeOnAnchor = GetDistanceBetween(oNpc, oMe) <= DL_WORK_ANCHOR_RADIUS;
    int bPartnerOnAnchor = GetDistanceBetween(oPartner, oPartnerWp) <= DL_WORK_ANCHOR_RADIUS;
    string sAnim = "";
    string sStatus = "moving_social_pair";
    if (bMeOnAnchor && bPartnerOnAnchor)
    {
        sStatus = "on_social_anchor";
        sAnim = "talk01";
        if ((DL_GetTagDeterministicOffset(GetTag(oNpc), 100, 0) % 2) == 0)
        {
            sAnim = "talk02";
        }
    }

    DL_LogChatDebugEvent(
        oNpc,
        "target_social",
        "target dir=SOCIAL area=" + GetTag(GetArea(oMe)) + " anchor=" + GetTag(oMe) +
            " slot=" + GetLocalString(oNpc, DL_L_NPC_SOCIAL_SLOT) +
            " partner=" + sPartnerTag
    );
    DL_ProgressFocusAtTarget(oNpc, oMe, sStatus, sAnim);
}
