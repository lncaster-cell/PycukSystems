#pragma once

#include "daily_life/dl_const_inc"
#include "daily_life/dl_log_inc"

const int DL_SLOT_REVIEW_TTL_SECONDS = 60;

string DL_MakeSlotProfileKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_profile_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotReviewKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_review_" + sFunctionSlotId + "_" + sField;
}

int DL_GetCurrentSlotReviewTick()
{
    int nHour = GetTimeHour();
    int nMinute = GetTimeMinute();
    int nSecond = GetTimeSecond();
    return (nHour * 3600) + (nMinute * 60) + nSecond;
}

string DL_MakeBaseLostNpcKey(object oNPC, string sField)
{
    return "dl_base_lost_npc_" + ObjectToString(oNPC) + "_" + sField;
}

string DL_MakeBaseLostSlotKey(string sFunctionSlotId, string sField)
{
    return "dl_base_lost_slot_" + sFunctionSlotId + "_" + sField;
}

void DL_StageFunctionSlotProfile(string sFunctionSlotId, int nFamily, int nSubtype, int nSchedule, object oBase)
{
    object oModule = GetModule();
    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot profile stage ignored: empty function slot id");
        return;
    }
    SetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "family"), nFamily);
    SetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "subtype"), nSubtype);
    SetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "schedule"), nSchedule);
    SetLocalObject(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "base"), oBase);
}

void DL_ClearFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    if (sFunctionSlotId == "") return;
    DeleteLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "family"));
    DeleteLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "subtype"));
    DeleteLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "schedule"));
    DeleteLocalObject(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "base"));
}

int DL_HasStagedFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    if (sFunctionSlotId == "") return FALSE;
    if (GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "family")) > DL_FAMILY_NONE) return TRUE;
    if (GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "subtype")) > DL_SUBTYPE_NONE) return TRUE;
    if (GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "schedule")) > DL_SCH_NONE) return TRUE;
    if (GetIsObjectValid(GetLocalObject(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "base")))) return TRUE;
    return FALSE;
}

int DL_NormalizeSlotReviewReason(int nReason)
{
    if (nReason == DL_RESYNC_BASE_LOST || nReason == DL_RESYNC_SLOT_ASSIGNED) return nReason;
    return DL_RESYNC_BASE_LOST;
}

void DL_RecordBaseLostEvent(object oNPC, string sFunctionSlotId, int nDirective)
{
    object oModule = GetModule();
    SetLocalString(oModule, DL_MakeBaseLostNpcKey(oNPC, "slot"), sFunctionSlotId);
    SetLocalInt(oModule, DL_MakeBaseLostNpcKey(oNPC, "kind"), nDirective);
    if (sFunctionSlotId != "")
    {
        SetLocalObject(oModule, DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc"), oNPC);
        SetLocalInt(oModule, DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind"), nDirective);
    }
    SetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT, sFunctionSlotId);
    SetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC, oNPC);
    SetLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND, nDirective);
}

void DL_ClearBaseLostEventForNpcOrSlot(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    DeleteLocalString(oModule, DL_MakeBaseLostNpcKey(oNPC, "slot"));
    DeleteLocalInt(oModule, DL_MakeBaseLostNpcKey(oNPC, "kind"));
    if (sFunctionSlotId != "")
    {
        DeleteLocalObject(oModule, DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc"));
        DeleteLocalInt(oModule, DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind"));
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
    if (sFunctionSlotId == "") return OBJECT_INVALID;
    return GetLocalObject(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc"));
}

int DL_GetBaseLostKindForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "") return DL_DIR_NONE;
    return GetLocalInt(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind"));
}

void DL_ApplyAssignedSlotProfile(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    int nFamily = GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "family"));
    int nSubtype = GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "subtype"));
    int nSchedule = GetLocalInt(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "schedule"));
    object oBase = GetLocalObject(oModule, DL_MakeSlotProfileKey(sFunctionSlotId, "base"));

    if (nFamily > DL_FAMILY_NONE) SetLocalInt(oNPC, DL_L_NPC_FAMILY, nFamily);
    if (nSubtype > DL_SUBTYPE_NONE) SetLocalInt(oNPC, DL_L_NPC_SUBTYPE, nSubtype);
    if (nSchedule > DL_SCH_NONE) SetLocalInt(oNPC, DL_L_SCHEDULE_TEMPLATE, nSchedule);
    if (GetIsObjectValid(oBase)) SetLocalObject(oNPC, DL_L_NPC_BASE, oBase);
    else DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot profile base ignored: invalid base object for slot " + sFunctionSlotId);
}

void DL_RequestAssignedNpcResync(object oNPC)
{
    if (!GetIsObjectValid(oNPC)) return;
    SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_RESYNC_SLOT_ASSIGNED);
}

void DL_RequestFunctionSlotReview(string sFunctionSlotId, int nReason)
{
    object oModule = GetModule();
    int nNowTick;
    int nLastTick;
    int nElapsed;
    int nLastReason;
    int nAttemptCount;

    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot review requested with empty function slot id");
        return;
    }

    nReason = DL_NormalizeSlotReviewReason(nReason);
    nNowTick = DL_GetCurrentSlotReviewTick();
    nLastTick = GetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick"));
    nLastReason = GetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason"));
    nAttemptCount = GetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "attempts")) + 1;
    nElapsed = nNowTick - nLastTick;
    if (nElapsed < 0) nElapsed = nElapsed + 86400;

    SetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "attempts"), nAttemptCount);

    if (nLastTick > 0 && nLastReason == nReason && nElapsed >= 0 && nElapsed < DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_VERBOSE, "Slot review deduplicated: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount) + ", elapsed=" + IntToString(nElapsed) + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
        return;
    }

    if (nLastTick > 0 && nLastReason == nReason && nElapsed >= DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_BASIC, "Slot review re-requested after ttl: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount) + ", elapsed=" + IntToString(nElapsed) + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
    }

    SetLocalString(oModule, DL_L_LAST_SLOT_REVIEW, sFunctionSlotId);
    SetLocalInt(oModule, DL_L_LAST_SLOT_REVIEW_REASON, nReason);
    SetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick"), nNowTick);
    SetLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason"), nReason);
    DL_Log(DL_DEBUG_BASIC, "Slot review requested: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount));
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
    DeleteLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick"));
    DeleteLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason"));
    DeleteLocalInt(oModule, DL_MakeSlotReviewKey(sFunctionSlotId, "attempts"));

    if (GetIsObjectValid(oNPC))
    {
        DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
        DL_ClearFunctionSlotProfile(sFunctionSlotId);
        SetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID, sFunctionSlotId);
        DL_RequestAssignedNpcResync(oNPC);
    }
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot assigned: " + sFunctionSlotId);
}
