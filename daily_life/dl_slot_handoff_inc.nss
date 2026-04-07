#ifndef DL_SLOT_HANDOFF_INC_NSS
#define DL_SLOT_HANDOFF_INC_NSS

#include "dl_const_inc"
#include "dl_log_inc"
#include "dl_resync_inc"

// Legacy compatibility include.
// New runtime entry scripts should prefer the compile-safe aggregation path via dl_all_inc.

const int DL_SLOT_REVIEW_TTL_SECONDS = 60;

string DL_MakeSlotProfileKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_profile_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotReviewKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_review_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotReviewInitKey(string sFunctionSlotId)
{
    return DL_MakeSlotReviewKey(sFunctionSlotId, "initialized");
}

int DL_GetCurrentSlotReviewTick()
{
    return (GetTimeHour() * 3600) + (GetTimeMinute() * 60) + GetTimeSecond();
}

string DL_MakeBaseLostNpcKey(object oNPC, string sField)
{
    return "dl_base_lost_npc_" + ObjectToString(oNPC) + "_" + sField;
}

string DL_MakeBaseLostSlotKey(string sFunctionSlotId, string sField)
{
    return "dl_base_lost_slot_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotAssignedNpcKey(object oNPC, string sField)
{
    return "dl_slot_assigned_npc_" + ObjectToString(oNPC) + "_" + sField;
}

string DL_MakeSlotAssignedSlotKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_assigned_slot_" + sFunctionSlotId + "_" + sField;
}

void DL_RecordSlotAssignedBootstrap(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sNpcSlotKey;
    string sSlotNpcKey;

    if (!GetIsObjectValid(oNPC) || sFunctionSlotId == "")
    {
        return;
    }

    sNpcSlotKey = DL_MakeSlotAssignedNpcKey(oNPC, "slot");
    sSlotNpcKey = DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc");

    SetLocalString(oModule, sNpcSlotKey, sFunctionSlotId);
    SetLocalObject(oModule, sSlotNpcKey, oNPC);
}

void DL_ClearSlotAssignedBootstrapForNpcOrSlot(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();

    if (GetIsObjectValid(oNPC))
    {
        DeleteLocalString(oModule, DL_MakeSlotAssignedNpcKey(oNPC, "slot"));
    }
    if (sFunctionSlotId != "")
    {
        DeleteLocalObject(oModule, DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc"));
    }
}

string DL_GetSlotAssignedBootstrapSlotForNpc(object oNPC)
{
    if (!GetIsObjectValid(oNPC))
    {
        return "";
    }
    return GetLocalString(GetModule(), DL_MakeSlotAssignedNpcKey(oNPC, "slot"));
}

object DL_GetSlotAssignedBootstrapNpcForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "")
    {
        return OBJECT_INVALID;
    }
    return GetLocalObject(GetModule(), DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc"));
}

void DL_StageFunctionSlotProfile(string sFunctionSlotId, int nFamily, int nSubtype, int nSchedule, object oBase)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;

    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot profile stage ignored: empty function slot id");
        return;
    }

    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");

    SetLocalInt(oModule, sFamilyKey, nFamily);
    SetLocalInt(oModule, sSubtypeKey, nSubtype);
    SetLocalInt(oModule, sScheduleKey, nSchedule);
    SetLocalObject(oModule, sBaseKey, oBase);
}

void DL_ClearFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;

    if (sFunctionSlotId == "")
    {
        return;
    }

    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");

    DeleteLocalInt(oModule, sFamilyKey);
    DeleteLocalInt(oModule, sSubtypeKey);
    DeleteLocalInt(oModule, sScheduleKey);
    DeleteLocalObject(oModule, sBaseKey);
}

int DL_HasStagedFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;

    if (sFunctionSlotId == "")
    {
        return FALSE;
    }

    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");

    if (GetLocalInt(oModule, sFamilyKey) > DL_FAMILY_NONE)
    {
        return TRUE;
    }
    if (GetLocalInt(oModule, sSubtypeKey) > DL_SUBTYPE_NONE)
    {
        return TRUE;
    }
    if (GetLocalInt(oModule, sScheduleKey) > DL_SCH_NONE)
    {
        return TRUE;
    }
    if (GetIsObjectValid(GetLocalObject(oModule, sBaseKey)))
    {
        return TRUE;
    }
    return FALSE;
}

int DL_NormalizeSlotReviewReason(int nReason)
{
    if (nReason == DL_RESYNC_BASE_LOST || nReason == DL_RESYNC_SLOT_ASSIGNED)
    {
        return nReason;
    }
    return DL_RESYNC_BASE_LOST;
}

void DL_RecordBaseLostEvent(object oNPC, string sFunctionSlotId, int nDirective)
{
    object oModule = GetModule();
    string sNpcSlotKey = DL_MakeBaseLostNpcKey(oNPC, "slot");
    string sNpcKindKey = DL_MakeBaseLostNpcKey(oNPC, "kind");

    // Per-NPC/per-slot keys are transient; cleanup paths must call DL_ClearBaseLostEventForNpcOrSlot.
    SetLocalString(oModule, sNpcSlotKey, sFunctionSlotId);
    SetLocalInt(oModule, sNpcKindKey, nDirective);

    if (sFunctionSlotId != "")
    {
        string sSlotNpcKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc");
        string sSlotKindKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind");
        SetLocalObject(oModule, sSlotNpcKey, oNPC);
        SetLocalInt(oModule, sSlotKindKey, nDirective);
    }

    SetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT, sFunctionSlotId);
    SetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC, oNPC);
    SetLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND, nDirective);
}

void DL_ClearBaseLostEventForNpcOrSlot(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sNpcSlotKey = DL_MakeBaseLostNpcKey(oNPC, "slot");
    string sNpcKindKey = DL_MakeBaseLostNpcKey(oNPC, "kind");

    DeleteLocalString(oModule, sNpcSlotKey);
    DeleteLocalInt(oModule, sNpcKindKey);

    if (sFunctionSlotId != "")
    {
        string sSlotNpcKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc");
        string sSlotKindKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind");
        DeleteLocalObject(oModule, sSlotNpcKey);
        DeleteLocalInt(oModule, sSlotKindKey);
    }
}

string DL_GetBaseLostSlotForNpc(object oNPC)
{
    return GetLocalString(GetModule(), DL_MakeBaseLostNpcKey(oNPC, "slot"));
}

int DL_GetBaseLostKindForNpc(object oNPC)
{
    return GetLocalInt(GetModule(), DL_MakeBaseLostNpcKey(oNPC, "kind"));
}

object DL_GetBaseLostNpcForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "")
    {
        return OBJECT_INVALID;
    }
    return GetLocalObject(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc"));
}

int DL_GetBaseLostKindForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "")
    {
        return DL_DIR_NONE;
    }
    return GetLocalInt(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind"));
}

void DL_ApplyAssignedSlotProfile(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;
    int nFamily;
    int nSubtype;
    int nSchedule;
    object oBase;

    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");

    nFamily = GetLocalInt(oModule, sFamilyKey);
    nSubtype = GetLocalInt(oModule, sSubtypeKey);
    nSchedule = GetLocalInt(oModule, sScheduleKey);
    oBase = GetLocalObject(oModule, sBaseKey);

    if (nFamily > DL_FAMILY_NONE)
    {
        SetLocalInt(oNPC, DL_L_NPC_FAMILY, nFamily);
    }
    if (nSubtype > DL_SUBTYPE_NONE)
    {
        SetLocalInt(oNPC, DL_L_NPC_SUBTYPE, nSubtype);
    }
    if (nSchedule > DL_SCH_NONE)
    {
        SetLocalInt(oNPC, DL_L_SCHEDULE_TEMPLATE, nSchedule);
    }
    if (GetIsObjectValid(oBase))
    {
        SetLocalObject(oNPC, DL_L_NPC_BASE, oBase);
    }
    else
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot profile base ignored: invalid base object for slot " + sFunctionSlotId);
    }
}

void DL_RequestAssignedNpcResync(object oNPC)
{
    int nCurrentReason;
    int nRequestedReason;
    int nSelectedReason;

    if (!GetIsObjectValid(oNPC))
    {
        return;
    }

    nCurrentReason = DL_NormalizeResyncReason(GetLocalInt(oNPC, DL_L_RESYNC_REASON));
    nRequestedReason = DL_NormalizeResyncReason(DL_RESYNC_SLOT_ASSIGNED);
    nSelectedReason = DL_SelectStrongerResyncReason(nCurrentReason, nRequestedReason);

    SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    if (nSelectedReason != nCurrentReason)
    {
        SetLocalInt(oNPC, DL_L_RESYNC_REASON, nSelectedReason);
    }
}

void DL_ClearFunctionSlotReviewState(object oModule, string sFunctionSlotId)
{
    string sLastTickKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick");
    string sLastTickSetKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick_set");
    string sLastReasonKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason");
    string sAttemptsKey = DL_MakeSlotReviewKey(sFunctionSlotId, "attempts");
    string sInitializedKey = DL_MakeSlotReviewInitKey(sFunctionSlotId);

    DeleteLocalInt(oModule, sLastTickKey);
    DeleteLocalInt(oModule, sLastTickSetKey);
    DeleteLocalInt(oModule, sLastReasonKey);
    DeleteLocalInt(oModule, sAttemptsKey);
    DeleteLocalInt(oModule, sInitializedKey);
}

void DL_RequestFunctionSlotReview(string sFunctionSlotId, int nReason)
{
    object oModule = GetModule();
    string sLastTickKey;
    string sLastTickSetKey;
    string sLastReasonKey;
    string sAttemptsKey;
    string sInitializedKey;
    int nNowTick;
    int nLastTick;
    int bHasLastTick;
    int nElapsed;
    int nLastReason;
    int nAttemptCount;
    int bInitialized;

    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot review requested with empty function slot id");
        return;
    }

    sLastTickKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick");
    sLastTickSetKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick_set");
    sLastReasonKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason");
    sAttemptsKey = DL_MakeSlotReviewKey(sFunctionSlotId, "attempts");
    sInitializedKey = DL_MakeSlotReviewInitKey(sFunctionSlotId);

    nReason = DL_NormalizeSlotReviewReason(nReason);
    nNowTick = DL_GetCurrentSlotReviewTick();
    bInitialized = GetLocalInt(oModule, sInitializedKey);
    nLastTick = GetLocalInt(oModule, sLastTickKey);
    nLastReason = GetLocalInt(oModule, sLastReasonKey);
    nAttemptCount = GetLocalInt(oModule, sAttemptsKey) + 1;
    nElapsed = nNowTick - nLastTick;
    if (nElapsed < 0)
    {
        nElapsed = nElapsed + 86400;
    }

    SetLocalInt(oModule, sAttemptsKey, nAttemptCount);

    if (bInitialized && nLastReason == nReason && nElapsed >= 0 && nElapsed < DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_VERBOSE,
            "Slot review deduplicated: " + sFunctionSlotId
            + ", reason=" + IntToString(nReason)
            + ", attempts=" + IntToString(nAttemptCount)
            + ", elapsed=" + IntToString(nElapsed)
            + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
        return;
    }

    if (bInitialized && nLastReason == nReason && nElapsed >= DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_BASIC,
            "Slot review re-requested after ttl: " + sFunctionSlotId
            + ", reason=" + IntToString(nReason)
            + ", attempts=" + IntToString(nAttemptCount)
            + ", elapsed=" + IntToString(nElapsed)
            + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
    }

    SetLocalString(oModule, DL_L_LAST_SLOT_REVIEW, sFunctionSlotId);
    SetLocalInt(oModule, DL_L_LAST_SLOT_REVIEW_REASON, nReason);
    SetLocalInt(oModule, sLastTickSetKey, TRUE);
    SetLocalInt(oModule, sLastTickKey, nNowTick);
    SetLocalInt(oModule, sLastReasonKey, nReason);
    SetLocalInt(oModule, sInitializedKey, TRUE);
    DL_Log(DL_DEBUG_BASIC,
        "Slot review requested: " + sFunctionSlotId
        + ", reason=" + IntToString(nReason)
        + ", attempts=" + IntToString(nAttemptCount));
}

void DL_OnFunctionSlotAssigned(string sFunctionSlotId, object oNPC)
{
    object oModule = GetModule();

    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot assigned callback ignored: empty function slot id");
        return;
    }

    SetLocalString(oModule, DL_L_LAST_SLOT_ASSIGNED, sFunctionSlotId);
    SetLocalInt(oModule, DL_L_LAST_SLOT_ASSIGNED_REASON, DL_RESYNC_SLOT_ASSIGNED);
    SetLocalObject(oModule, DL_L_SLOT_ASSIGNED_NPC, oNPC);
    if (GetLocalString(oModule, DL_L_LAST_SLOT_REVIEW) == sFunctionSlotId)
    {
        DeleteLocalString(oModule, DL_L_LAST_SLOT_REVIEW);
        DeleteLocalInt(oModule, DL_L_LAST_SLOT_REVIEW_REASON);
    }
    DL_ClearFunctionSlotReviewState(oModule, sFunctionSlotId);

    if (GetIsObjectValid(oNPC))
    {
        // Persist pending slot directly on NPC so bootstrap does not depend on module-wide buffers.
        SetLocalString(oNPC, DL_L_PENDING_SLOT_ID, sFunctionSlotId);
        SetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID, sFunctionSlotId);
        DL_RecordSlotAssignedBootstrap(oNPC, sFunctionSlotId);

        DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
        DL_ClearFunctionSlotProfile(sFunctionSlotId);
        DL_RequestAssignedNpcResync(oNPC);
    }
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot assigned: " + sFunctionSlotId);
}

#endif
