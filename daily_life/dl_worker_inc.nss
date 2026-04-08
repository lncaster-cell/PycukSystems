#ifndef DL_WORKER_INC_NSS
#define DL_WORKER_INC_NSS

#include "dl_const_inc"
#include "dl_area_inc"
#include "dl_resync_inc"
#include "dl_override_inc"
#include "dl_slot_handoff_inc"
#include "dl_types_inc"

// Legacy compatibility include.
// New runtime entry scripts should prefer the compile-safe aggregation path via dl_all_inc.

const string DL_L_WORKER_CURSOR = "dl_worker_cursor";
const string DL_L_WORKER_CANDIDATE_IDX = "dl_worker_candidate_idx";
const string DL_L_WORKER_IS_CANDIDATE = "dl_worker_is_candidate";

int DL_IsWorkerCreatureObject(object oObject)
{
    return GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject);
}

void DL_ClearWorkerCandidateMarker(object oNPC)
{
    DeleteLocalInt(oNPC, DL_L_WORKER_CANDIDATE_IDX);
    DeleteLocalInt(oNPC, DL_L_WORKER_IS_CANDIDATE);
}

void DL_ClearAreaWorkerMarkers(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            DL_ClearWorkerCandidateMarker(oObject);
        }
        oObject = GetNextObjectInArea(oArea);
    }
}

string DL_DescribeResyncReason(int nReason)
{
    if (nReason == DL_RESYNC_AREA_ENTER) return "AREA_ENTER";
    if (nReason == DL_RESYNC_TIER_UP) return "TIER_UP";
    if (nReason == DL_RESYNC_SAVE_LOAD) return "SAVE_LOAD";
    if (nReason == DL_RESYNC_TIME_JUMP) return "TIME_JUMP";
    if (nReason == DL_RESYNC_OVERRIDE_END) return "OVERRIDE_END";
    if (nReason == DL_RESYNC_WORKER) return "WORKER";
    if (nReason == DL_RESYNC_SLOT_ASSIGNED) return "SLOT_ASSIGNED";
    if (nReason == DL_RESYNC_BASE_LOST) return "BASE_LOST";
    return "NONE";
}

string DL_DescribeDirective(int nDirective)
{
    if (nDirective == DL_DIR_SLEEP) return "SLEEP";
    if (nDirective == DL_DIR_WORK) return "WORK";
    if (nDirective == DL_DIR_SERVICE) return "SERVICE";
    if (nDirective == DL_DIR_SOCIAL) return "SOCIAL";
    if (nDirective == DL_DIR_DUTY) return "DUTY";
    if (nDirective == DL_DIR_PUBLIC_PRESENCE) return "PUBLIC_PRESENCE";
    if (nDirective == DL_DIR_HOLD_POST) return "HOLD_POST";
    if (nDirective == DL_DIR_LOCKDOWN_BASE) return "LOCKDOWN_BASE";
    if (nDirective == DL_DIR_HIDE_SAFE) return "HIDE_SAFE";
    if (nDirective == DL_DIR_ABSENT) return "ABSENT";
    if (nDirective == DL_DIR_UNASSIGNED) return "UNASSIGNED";
    return "NONE";
}

string DL_DescribeDialogueMode(int nDialogue)
{
    if (nDialogue == DL_DLG_WORK) return "WORK";
    if (nDialogue == DL_DLG_OFF_DUTY) return "OFF_DUTY";
    if (nDialogue == DL_DLG_INSPECTION) return "INSPECTION";
    if (nDialogue == DL_DLG_LOCKDOWN) return "LOCKDOWN";
    if (nDialogue == DL_DLG_HIDE) return "HIDE";
    if (nDialogue == DL_DLG_UNAVAILABLE) return "UNAVAILABLE";
    return "NONE";
}

string DL_DescribeServiceMode(int nService)
{
    if (nService == DL_SERVICE_AVAILABLE) return "AVAILABLE";
    if (nService == DL_SERVICE_LIMITED) return "LIMITED";
    if (nService == DL_SERVICE_DISABLED) return "DISABLED";
    return "NONE";
}

string DL_DescribeOverride(int nOverride)
{
    if (nOverride == DL_OVR_FIRE) return "FIRE";
    if (nOverride == DL_OVR_QUARANTINE) return "QUARANTINE";
    return "NONE";
}

void DL_LogSmokeSnapshot(object oNPC, object oArea, int nReason)
{
    string sMessage;
    object oModule = GetModule();
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    string sLastBaseLostSlot = DL_GetBaseLostSlotForNpc(oNPC);
    int nLastBaseLostKind = DL_GetBaseLostKindForNpc(oNPC);
    object oLastBaseLostNpc = OBJECT_INVALID;
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    int nService = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);

    if (sLastBaseLostSlot == "" && sFunctionSlotId != "")
    {
        sLastBaseLostSlot = sFunctionSlotId;
    }
    if (nLastBaseLostKind == DL_DIR_NONE && sLastBaseLostSlot != "")
    {
        nLastBaseLostKind = DL_GetBaseLostKindForSlot(sLastBaseLostSlot);
    }
    if (sLastBaseLostSlot != "")
    {
        object oSlotNpc = DL_GetBaseLostNpcForSlot(sLastBaseLostSlot);
        if (GetIsObjectValid(oSlotNpc))
        {
            oLastBaseLostNpc = oSlotNpc;
        }
    }
    if (nLastBaseLostKind == DL_DIR_NONE)
    {
        nLastBaseLostKind = GetLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND);
        if (sLastBaseLostSlot == "")
        {
            sLastBaseLostSlot = GetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
        }
        if (!GetIsObjectValid(oLastBaseLostNpc))
        {
            oLastBaseLostNpc = GetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
        }
    }

    sMessage =
        "smoke snapshot"
        + " reason=" + IntToString(nReason) + "(" + DL_DescribeResyncReason(nReason) + ")"
        + " family=" + IntToString(nFamily)
        + " subtype=" + IntToString(nSubtype)
        + " directive=" + IntToString(nDirective) + "(" + DL_DescribeDirective(nDirective) + ")"
        + " dialogue=" + IntToString(nDialogue) + "(" + DL_DescribeDialogueMode(nDialogue) + ")"
        + " service=" + IntToString(nService) + "(" + DL_DescribeServiceMode(nService) + ")"
        + " override=" + IntToString(nOverride) + "(" + DL_DescribeOverride(nOverride) + ")"
        + " base_lost_kind=" + IntToString(nLastBaseLostKind) + "(" + DL_DescribeDirective(nLastBaseLostKind) + ")"
        + " base_lost_slot=" + sLastBaseLostSlot;

    if (GetIsObjectValid(oLastBaseLostNpc) && oLastBaseLostNpc == oNPC)
    {
        sMessage = sMessage + " base_lost_npc=SELF";
    }
    else if (!GetIsObjectValid(oLastBaseLostNpc))
    {
        sMessage = sMessage + " base_lost_npc=UNKNOWN";
    }

    DL_LogNpc(oNPC, DL_DEBUG_BASIC, sMessage);
}

int DL_GetWorkerBudget(object oArea)
{
    return DL_GetDefaultAreaTierBudget(DL_GetAreaTier(oArea));
}

int DL_ShouldProcessNpcInWorker(object oNPC)
{
    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }
    if (GetLocalInt(oNPC, DL_L_RESYNC_PENDING) == TRUE)
    {
        return TRUE;
    }
    return DL_IsPersistent(oNPC) || DL_IsNamed(oNPC);
}

void DL_ProcessNpcBudgeted(object oArea, object oNPC)
{
    int nReason = GetLocalInt(oNPC, DL_L_RESYNC_REASON);
    if (nReason == DL_RESYNC_NONE)
    {
        nReason = DL_RESYNC_WORKER;
    }
    DL_RunResync(oNPC, oArea, nReason);
    if (GetLocalInt(GetModule(), DL_L_SMOKE_TRACE) == TRUE)
    {
        DL_LogSmokeSnapshot(oNPC, oArea, nReason);
    }
}

void DL_DispatchDueJobs(object oArea, int nBudget)
{
    object oObject;
    int nCandidateCount = 0;
    int nCursor = 0;
    int nPlanned = 0;
    int nProcessed = 0;

    if (nBudget <= 0)
    {
        DL_ClearAreaWorkerMarkers(oArea);
        SetLocalInt(oArea, DL_L_WORKER_CURSOR, 0);
        return;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            if (DL_ShouldProcessNpcInWorker(oObject))
            {
                SetLocalInt(oObject, DL_L_WORKER_CANDIDATE_IDX, nCandidateCount);
                SetLocalInt(oObject, DL_L_WORKER_IS_CANDIDATE, TRUE);
                nCandidateCount += 1;
            }
            else
            {
                DL_ClearWorkerCandidateMarker(oObject);
            }
        }
        oObject = GetNextObjectInArea(oArea);
    }

    if (nCandidateCount <= 0)
    {
        SetLocalInt(oArea, DL_L_WORKER_CURSOR, 0);
        return;
    }

    nCursor = GetLocalInt(oArea, DL_L_WORKER_CURSOR) % nCandidateCount;
    if (nCursor < 0)
    {
        nCursor += nCandidateCount;
    }

    nPlanned = nBudget;
    if (nPlanned > nCandidateCount)
    {
        nPlanned = nCandidateCount;
    }

    DL_Log(
        DL_DEBUG_VERBOSE,
        "worker fairness area=" + GetTag(oArea)
        + " cursor=" + IntToString(nCursor)
        + " candidates=" + IntToString(nCandidateCount)
        + " budget=" + IntToString(nBudget));

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            if (GetLocalInt(oObject, DL_L_WORKER_IS_CANDIDATE) == TRUE)
            {
                int nCandidateIndex = GetLocalInt(oObject, DL_L_WORKER_CANDIDATE_IDX);
                if (nProcessed < nPlanned)
                {
                    int nDistance = (nCandidateIndex - nCursor) % nCandidateCount;
                    if (nDistance < 0)
                    {
                        nDistance += nCandidateCount;
                    }
                    if (nDistance < nPlanned)
                    {
                        DL_ProcessNpcBudgeted(oArea, oObject);
                        nProcessed += 1;
                    }
                }
            }
            DL_ClearWorkerCandidateMarker(oObject);
        }
        oObject = GetNextObjectInArea(oArea);
    }

    SetLocalInt(oArea, DL_L_WORKER_CURSOR, (nCursor + nProcessed) % nCandidateCount);
}

void DL_AreaWorkerTick(object oArea)
{
    if (!DL_ShouldRunDailyLife(oArea))
    {
        return;
    }
    DL_DispatchDueJobs(oArea, DL_GetWorkerBudget(oArea));
}

#endif
