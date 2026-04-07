#include "dl_all_inc"

string DL_SmokePassLabel(int bPass)
{
    if (bPass) return "PASS";
    return "FAIL";
}

int DL_SmokeIsInRange(int nValue, int nMin, int nMax)
{
    return nValue >= nMin && nValue <= nMax;
}

void DL_LogReadinessIssue(object oNPC, string sField, int nValue, string sExpected)
{
    DL_Log(
        DL_DEBUG_BASIC,
        "MilestoneA readiness issue npc=" + GetTag(oNPC) +
        " field=" + sField +
        " value=" + IntToString(nValue) +
        " expected=" + sExpected
    );
}

int DL_RunReadinessChecks()
{
    object oArea = GetFirstArea();
    int nAreaCount = 0;
    int nHotCount = 0;
    int nNpcCount = 0;
    int nWarnings = 0;
    int nErrors = 0;
    while (GetIsObjectValid(oArea))
    {
        int nTier = DL_GetAreaTier(oArea);
        object oObject = GetFirstObjectInArea(oArea);
        nAreaCount += 1;
        if (nTier == DL_AREA_HOT) nHotCount += 1;
        if (!DL_SmokeIsInRange(nTier, DL_AREA_FROZEN, DL_AREA_HOT))
        {
            DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness issue area=" + GetTag(oArea) + " tier=" + IntToString(nTier) + " expected=0..2");
            nErrors += 1;
        }
        while (GetIsObjectValid(oObject))
        {
            if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject) && DL_IsDailyLifeNpc(oObject))
            {
                int nFamily = DL_GetNpcFamily(oObject);
                int nSubtype = DL_GetNpcSubtype(oObject);
                int nSchedule = DL_GetScheduleTemplate(oObject);
                int nBase = DL_GetNpcBaseKind(oObject);
                int bNamed = GetLocalInt(oObject, DL_L_NAMED);
                int bPersistent = GetLocalInt(oObject, DL_L_PERSISTENT);
                nNpcCount += 1;
                if (!DL_SmokeIsInRange(nFamily, DL_FAMILY_LAW, DL_FAMILY_CLERGY))
                {
                    DL_LogReadinessIssue(oObject, DL_L_NPC_FAMILY, nFamily, "1..6");
                    nErrors += 1;
                }
                if (!DL_SmokeIsInRange(nSubtype, DL_SUBTYPE_PATROL, DL_SUBTYPE_PRIEST))
                {
                    DL_LogReadinessIssue(oObject, DL_L_NPC_SUBTYPE, nSubtype, "1..16");
                    nErrors += 1;
                }
                if (!DL_SmokeIsInRange(nSchedule, DL_SCH_EARLY_WORKER, DL_SCH_CIVILIAN_HOME))
                {
                    DL_LogReadinessIssue(oObject, DL_L_SCHEDULE_TEMPLATE, nSchedule, "1..7");
                    nErrors += 1;
                }
                if (!DL_SmokeIsInRange(nBase, DL_BASE_HOME, DL_BASE_OFFICE))
                {
                    DL_LogReadinessIssue(oObject, DL_L_NPC_BASE, nBase, "1..7");
                    nErrors += 1;
                }
                if (!bNamed && !bPersistent)
                {
                    DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness warning npc=" + GetTag(oObject) + " has no worker guarantee flags (dl_named or dl_persistent)");
                    nWarnings += 1;
                }
            }
            oObject = GetNextObjectInArea(oArea);
        }
        oArea = GetNextArea();
    }
    if (GetLocalInt(GetModule(), DL_L_SMOKE_TRACE) == FALSE)
    {
        DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness warning module local dl_smoke_trace=FALSE");
        nWarnings += 1;
    }
    if (nAreaCount == 0)
    {
        DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness issue no areas found in module");
        nErrors += 1;
    }
    if (nHotCount == 0)
    {
        DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness issue no HOT areas found (dl_area_tier=2)");
        nErrors += 1;
    }
    if (nNpcCount == 0)
    {
        DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness issue no Daily Life NPC found");
        nErrors += 1;
    }
    DL_Log(DL_DEBUG_BASIC, "MilestoneA readiness summary areas=" + IntToString(nAreaCount) + " hot_areas=" + IntToString(nHotCount) + " dl_npc=" + IntToString(nNpcCount) + " warnings=" + IntToString(nWarnings) + " errors=" + IntToString(nErrors));
    SetLocalInt(GetModule(), "dl_smoke_readiness_errors", nErrors);
    SetLocalInt(GetModule(), "dl_smoke_readiness_warnings", nWarnings);
    return nErrors;
}

void DL_LogScenarioResult(string sScenario, int bFound, int bPass, string sDetail)
{
    string sStatus;
    object oModule = GetModule();
    if (!bFound) sStatus = "NOT_FOUND";
    else sStatus = DL_SmokePassLabel(bPass);
    DL_Log(DL_DEBUG_BASIC, "MilestoneA smoke " + sScenario + " status=" + sStatus + " detail=" + sDetail);
    SetLocalInt(oModule, "dl_smoke_found_" + sScenario, bFound);
    SetLocalInt(oModule, "dl_smoke_pass_" + sScenario, bPass);
}

int DL_GetScenarioStatusCode(int bFound, int bPass)
{
    if (!bFound) return 0;
    if (bPass) return 2;
    return 1;
}

string DL_GetScenarioStatusLabelByCode(int nStatus)
{
    if (nStatus == 2) return "PASS";
    if (nStatus == 1) return "FAIL";
    return "NOT_FOUND";
}

void DL_LogScenarioCounters(string sScenario, int nChecked, int nPassed)
{
    DL_Log(DL_DEBUG_BASIC, "MilestoneA smoke " + sScenario + " counters checked=" + IntToString(nChecked) + " passed=" + IntToString(nPassed));
}

void DL_ClearScenarioMarkers()
{
    object oModule = GetModule();
    DeleteLocalInt(oModule, "dl_smoke_found_A"); DeleteLocalInt(oModule, "dl_smoke_pass_A");
    DeleteLocalInt(oModule, "dl_smoke_found_B"); DeleteLocalInt(oModule, "dl_smoke_pass_B");
    DeleteLocalInt(oModule, "dl_smoke_found_C"); DeleteLocalInt(oModule, "dl_smoke_pass_C");
    DeleteLocalInt(oModule, "dl_smoke_found_D"); DeleteLocalInt(oModule, "dl_smoke_pass_D");
    DeleteLocalInt(oModule, "dl_smoke_found_E"); DeleteLocalInt(oModule, "dl_smoke_pass_E");
    DeleteLocalInt(oModule, "dl_smoke_found_F"); DeleteLocalInt(oModule, "dl_smoke_pass_F");
    DeleteLocalInt(oModule, "dl_smoke_found_G"); DeleteLocalInt(oModule, "dl_smoke_pass_G");
}

int DL_IsScenarioAExpected(object oNPC)
{
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    int nService = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    return nDirective == DL_DIR_WORK && nDialogue == DL_DLG_WORK && (nService == DL_SERVICE_LIMITED || nService == DL_SERVICE_AVAILABLE);
}

int DL_IsScenarioBExpected(object oNPC)
{
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    int nService = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    return nDirective != DL_DIR_WORK && nDialogue != DL_DLG_WORK && nService != DL_SERVICE_AVAILABLE;
}

int DL_IsScenarioCExpected(object oNPC)
{
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    return (nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST) && (nDialogue == DL_DLG_INSPECTION || nDialogue == DL_DLG_OFF_DUTY || nDialogue == DL_DLG_WORK);
}

int DL_IsScenarioDExpected(object oNPC)
{
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    int nService = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    return (nDirective == DL_DIR_SERVICE || nDirective == DL_DIR_SOCIAL) && (nDialogue == DL_DLG_WORK || nDialogue == DL_DLG_OFF_DUTY) && (nService == DL_SERVICE_AVAILABLE || nService == DL_SERVICE_DISABLED);
}

int DL_IsScenarioEExpected(object oNPC, object oArea)
{
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    int nFamily = DL_GetNpcFamily(oNPC);
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    if (nOverride != DL_OVR_QUARANTINE) return FALSE;
    if (nFamily == DL_FAMILY_LAW) return nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST;
    return nDirective == DL_DIR_LOCKDOWN_BASE;
}

void DL_RunScenarioProfileChecks()
{
    object oArea = GetFirstArea();
    object oObject;
    int bFoundA = FALSE; int bFoundB = FALSE; int bFoundC = FALSE; int bFoundD = FALSE; int bFoundE = FALSE;
    int bPassA = FALSE; int bPassB = FALSE; int bPassC = FALSE; int bPassD = FALSE; int bPassE = FALSE;
    int nBlacksmithChecked = 0; int nBlacksmithWorkPass = 0; int nBlacksmithNonWorkPass = 0;
    int nGateChecked = 0; int nGatePass = 0; int nInnChecked = 0; int nInnPass = 0;
    int nQuarantineChecked = 0; int nQuarantinePass = 0;
    while (GetIsObjectValid(oArea))
    {
        oObject = GetFirstObjectInArea(oArea);
        while (GetIsObjectValid(oObject))
        {
            if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject) && DL_IsDailyLifeNpc(oObject))
            {
                DL_RunForcedResync(oObject, oArea, DL_RESYNC_WORKER);
                if (DL_GetNpcFamily(oObject) == DL_FAMILY_CRAFT && DL_GetNpcSubtype(oObject) == DL_SUBTYPE_BLACKSMITH)
                {
                    bFoundA = TRUE; bFoundB = TRUE; nBlacksmithChecked += 1;
                    if (DL_IsScenarioAExpected(oObject)) { bPassA = TRUE; nBlacksmithWorkPass += 1; }
                    if (DL_IsScenarioBExpected(oObject)) { bPassB = TRUE; nBlacksmithNonWorkPass += 1; }
                }
                if (DL_GetNpcFamily(oObject) == DL_FAMILY_LAW && DL_GetNpcSubtype(oObject) == DL_SUBTYPE_GATE_POST)
                {
                    bFoundC = TRUE; nGateChecked += 1;
                    if (DL_IsScenarioCExpected(oObject)) { bPassC = TRUE; nGatePass += 1; }
                }
                if (DL_GetNpcFamily(oObject) == DL_FAMILY_TRADE_SERVICE && DL_GetNpcSubtype(oObject) == DL_SUBTYPE_INNKEEPER)
                {
                    bFoundD = TRUE; nInnChecked += 1;
                    if (DL_IsScenarioDExpected(oObject)) { bPassD = TRUE; nInnPass += 1; }
                }
                if (DL_GetTopOverride(oObject, oArea) == DL_OVR_QUARANTINE)
                {
                    bFoundE = TRUE; nQuarantineChecked += 1;
                    if (DL_IsScenarioEExpected(oObject, oArea)) { bPassE = TRUE; nQuarantinePass += 1; }
                }
            }
            oObject = GetNextObjectInArea(oArea);
        }
        oArea = GetNextArea();
    }
    DL_LogScenarioResult("A", bFoundA, bPassA, "blacksmith work profile");
    DL_LogScenarioResult("B", bFoundB, bPassB, "blacksmith non-work profile");
    DL_LogScenarioResult("C", bFoundC, bPassC, "gate duty profile");
    DL_LogScenarioResult("D", bFoundD, bPassD, "innkeeper late profile");
    DL_LogScenarioResult("E", bFoundE, bPassE, "quarantine override profile");
    DL_LogScenarioCounters("A", nBlacksmithChecked, nBlacksmithWorkPass);
    DL_LogScenarioCounters("B", nBlacksmithChecked, nBlacksmithNonWorkPass);
    DL_LogScenarioCounters("C", nGateChecked, nGatePass);
    DL_LogScenarioCounters("D", nInnChecked, nInnPass);
    DL_LogScenarioCounters("E", nQuarantineChecked, nQuarantinePass);
}

void DL_RunScenarioFGChecks()
{
    object oArea = GetFirstArea();
    object oProbeNpc = OBJECT_INVALID;
    object oProbeArea = OBJECT_INVALID;
    int bFoundHot = FALSE; int bFoundWarm = FALSE; int bFoundFrozen = FALSE;
    int bBudgetShape = FALSE; int bGateShape = FALSE;
    if (DL_GetDefaultAreaTierBudget(DL_AREA_HOT) > DL_GetDefaultAreaTierBudget(DL_AREA_WARM) && DL_GetDefaultAreaTierBudget(DL_AREA_WARM) > DL_GetDefaultAreaTierBudget(DL_AREA_FROZEN)) bBudgetShape = TRUE;
    while (GetIsObjectValid(oArea))
    {
        int nTier = DL_GetAreaTier(oArea);
        object oObject = GetFirstObjectInArea(oArea);
        if (nTier == DL_AREA_HOT) bFoundHot = TRUE;
        else if (nTier == DL_AREA_WARM) bFoundWarm = TRUE;
        else if (nTier == DL_AREA_FROZEN) bFoundFrozen = TRUE;
        while (GetIsObjectValid(oObject))
        {
            if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject) && DL_IsDailyLifeNpc(oObject))
            {
                oProbeNpc = oObject;
                oProbeArea = oArea;
                break;
            }
            oObject = GetNextObjectInArea(oArea);
        }
        if (GetIsObjectValid(oProbeNpc)) break;
        oArea = GetNextArea();
    }
    if (GetIsObjectValid(oProbeNpc))
    {
        DL_RunForcedResync(oProbeNpc, oProbeArea, DL_RESYNC_AREA_ENTER);
        DL_LogScenarioResult("F", TRUE, GetLocalInt(oProbeNpc, DL_L_DIRECTIVE) != DL_DIR_NONE, "area enter forced resync on first available DL NPC");
    }
    else
    {
        DL_LogScenarioResult("F", FALSE, FALSE, "no DL NPC found for area-enter probe");
    }
    {
        int bHotRuns = DL_ShouldRunDailyLifeTier(DL_AREA_HOT);
        int bWarmRuns = DL_ShouldRunDailyLifeTier(DL_AREA_WARM);
        int bFrozenRuns = DL_ShouldRunDailyLifeTier(DL_AREA_FROZEN);
        bGateShape = bHotRuns && bWarmRuns && !bFrozenRuns;
    }
    DL_LogScenarioResult("G", bFoundHot || bFoundWarm || bFoundFrozen, bFoundHot && bFoundWarm && bFoundFrozen && bBudgetShape && bGateShape, "tier presence + budget ordering + gate hot/warm run, frozen stop");
}

void main()
{
    int nReadinessErrors;
    int nStatusA; int nStatusB; int nStatusC; int nStatusD; int nStatusE; int nStatusF; int nStatusG;
    int nPassCount = 0; int nFailCount = 0; int nNotFoundCount = 0;
    DL_ClearScenarioMarkers();
    nReadinessErrors = DL_RunReadinessChecks();
    if (nReadinessErrors > 0)
    {
        DL_Log(DL_DEBUG_BASIC, "MilestoneA smoke overall aborted due to readiness errors=" + IntToString(nReadinessErrors));
        DL_ClearScenarioMarkers();
        return;
    }
    DL_RunScenarioProfileChecks();
    DL_RunScenarioFGChecks();
    nStatusA = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_A"), GetLocalInt(GetModule(), "dl_smoke_pass_A"));
    nStatusB = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_B"), GetLocalInt(GetModule(), "dl_smoke_pass_B"));
    nStatusC = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_C"), GetLocalInt(GetModule(), "dl_smoke_pass_C"));
    nStatusD = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_D"), GetLocalInt(GetModule(), "dl_smoke_pass_D"));
    nStatusE = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_E"), GetLocalInt(GetModule(), "dl_smoke_pass_E"));
    nStatusF = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_F"), GetLocalInt(GetModule(), "dl_smoke_pass_F"));
    nStatusG = DL_GetScenarioStatusCode(GetLocalInt(GetModule(), "dl_smoke_found_G"), GetLocalInt(GetModule(), "dl_smoke_pass_G"));
    if (nStatusA == 2) nPassCount += 1; else if (nStatusA == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusB == 2) nPassCount += 1; else if (nStatusB == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusC == 2) nPassCount += 1; else if (nStatusC == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusD == 2) nPassCount += 1; else if (nStatusD == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusE == 2) nPassCount += 1; else if (nStatusE == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusF == 2) nPassCount += 1; else if (nStatusF == 1) nFailCount += 1; else nNotFoundCount += 1;
    if (nStatusG == 2) nPassCount += 1; else if (nStatusG == 1) nFailCount += 1; else nNotFoundCount += 1;
    DL_Log(DL_DEBUG_BASIC, "MilestoneA smoke overall pass=" + IntToString(nPassCount) + " fail=" + IntToString(nFailCount) + " not_found=" + IntToString(nNotFoundCount) + " statuses=[A:" + DL_GetScenarioStatusLabelByCode(nStatusA) + ",B:" + DL_GetScenarioStatusLabelByCode(nStatusB) + ",C:" + DL_GetScenarioStatusLabelByCode(nStatusC) + ",D:" + DL_GetScenarioStatusLabelByCode(nStatusD) + ",E:" + DL_GetScenarioStatusLabelByCode(nStatusE) + ",F:" + DL_GetScenarioStatusLabelByCode(nStatusF) + ",G:" + DL_GetScenarioStatusLabelByCode(nStatusG) + "]");
    DL_ClearScenarioMarkers();
}
