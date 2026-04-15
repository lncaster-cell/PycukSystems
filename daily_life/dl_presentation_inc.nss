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
int DL_TryApplyWorkActivityPresentation(object oNpc, string sProfile, string sWorkKind)
{
    if (sProfile == DL_PROFILE_BLACKSMITH)
    {
        if (sWorkKind == DL_WORK_KIND_FORGE)
        {
            DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_FORGE, DL_ARCH_ANIMS_FORGE);
            return TRUE;
        }

        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_FORGE_MULTI, DL_ARCH_ANIMS_CRAFT);
        return TRUE;
    }

    if (sProfile == DL_PROFILE_GATE_POST)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_GUARD, DL_ARCH_ANIMS_GUARD);
        return TRUE;
    }

    if (sProfile == DL_PROFILE_TRADER)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_MERCHANT_MULTI, DL_ARCH_ANIMS_TRADE);
        return TRUE;
    }
    if (sProfile == DL_PROFILE_DOMESTIC_WORKER)
    {
        DL_SetActivityPresentation(oNpc, DL_ARCH_ACT_NPC_FORGE_MULTI, DL_ARCH_ANIMS_DOMESTIC);
        return TRUE;
    }

    return FALSE;
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

    if (nDirective != DL_DIR_WORK)
    {
        DL_ClearActivityPresentation(oNpc);
        return;
    }

    string sProfile = GetLocalString(oNpc, DL_L_NPC_PROFILE_ID);
    string sWorkKind = GetLocalString(oNpc, DL_L_NPC_WORK_KIND);
    if (DL_TryApplyWorkActivityPresentation(oNpc, sProfile, sWorkKind))
    {
        return;
    }

    DL_ClearActivityPresentation(oNpc);
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

    string sProfile = GetLocalString(oNpc, DL_L_NPC_PROFILE_ID);
    if (sProfile == DL_PROFILE_BLACKSMITH)
    {
        string sKind = GetLocalString(oNpc, DL_L_NPC_WORK_KIND);
        int nTick = (GetTimeHour() * 60 + GetTimeMinute()) / 5;
        int nPhase = (nTick + DL_GetTagDeterministicOffset(GetTag(oNpc), 97, 0)) % 20;
        string sAnim = "forge01";

        if (sKind == DL_WORK_KIND_FORGE)
        {
            sAnim = (nPhase % 2) == 0 ? "forge01" : "forge02";
            if (nPhase == 0)
            {
                sAnim = "dustoff";
            }
        }
        else if (sKind == DL_WORK_KIND_FETCH)
        {
            sAnim = (nPhase % 2) == 0 ? "gettable" : "getground";
            if (nPhase == 0)
            {
                sAnim = "dustoff";
            }
        }
        else
        {
            sAnim = "craft01";
            if (nPhase == 0)
            {
                sAnim = "dustoff";
            }
            else if ((nPhase % 5) == 0)
            {
                sAnim = "gettable";
            }
        }

        PlayCustomAnimation(oNpc, sAnim, TRUE);
        return;
    }
    if (sProfile == DL_PROFILE_DOMESTIC_WORKER)
    {
        string sKindDomestic = GetLocalString(oNpc, DL_L_NPC_WORK_KIND);
        int nTickDomestic = (GetTimeHour() * 60 + GetTimeMinute()) / 5;
        int nPhaseDomestic = (nTickDomestic + DL_GetTagDeterministicOffset(GetTag(oNpc), 97, 0)) % 10;
        string sDomesticAnim = "cooking01";

        if (nPhaseDomestic == 0)
        {
            sDomesticAnim = "dustoff";
        }
        else if (sKindDomestic == DL_WORK_KIND_FETCH)
        {
            sDomesticAnim = (nPhaseDomestic % 2) == 0 ? "gettable" : "getground";
        }
        else if (sKindDomestic == DL_WORK_KIND_CRAFT)
        {
            sDomesticAnim = (nPhaseDomestic % 4) == 0 ? "cooking02" : "craft01";
        }
        else
        {
            sDomesticAnim = (nPhaseDomestic % 3) == 0 ? "cooking02" : "cooking01";
        }

        PlayCustomAnimation(oNpc, sDomesticAnim, TRUE);
        return;
    }

    string sAnimFallback = DL_GetFirstAnimToken(GetLocalString(oNpc, DL_L_NPC_ANIM_SET));
    if (sAnimFallback == "")
    {
        return;
    }

    PlayCustomAnimation(oNpc, sAnimFallback, TRUE);
}
